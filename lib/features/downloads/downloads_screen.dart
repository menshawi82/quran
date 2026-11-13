import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../player/player_providers.dart';
import 'downloads_service.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  var _grouped = false;
  final _expanded = <int>{};

  Future<void> _confirmDelete(DownloadedSurah item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final neu = dialogContext.neu;
        return AlertDialog(
          backgroundColor: neu.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title:
              Text('حذف التنزيل؟', style: TextStyle(color: neu.text)),
          content: Text(
            'سيتم حذف سورة ${kSurahNames[item.surahNumber - 1]} بصوت ${item.reciterName}',
            style: TextStyle(color: neu.subtext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('إلغاء', style: TextStyle(color: neu.subtext)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('حذف', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref
          .read(downloadsServiceProvider)
          .delete(item.moshafId, item.surahNumber);
    }
  }

  Widget _surahRow(DownloadedSurah item, {bool showReciter = true}) {
    final neu = context.neu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          NeuIconButton(
            icon: Icons.play_arrow_rounded,
            size: 44,
            iconSize: 22,
            pressed: true,
            onTap: () =>
                ref.read(playerControllerProvider).playDownloaded(item),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سورة ${kSurahNames[item.surahNumber - 1]}',
                  style: TextStyle(
                    color: neu.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showReciter) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.reciterName} · ${item.moshafName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: neu.subtext, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(item),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.delete_outline_rounded,
                  color: neu.subtext, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(int moshafId, List<DownloadedSurah> items) {
    final neu = context.neu;
    final isOpen = _expanded.contains(moshafId);
    final first = items.first;
    var totalBytes = 0;
    final service = ref.read(downloadsServiceProvider);
    for (final item in items) {
      totalBytes += service.fileSizeBytes(item.filePath);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                NeuIconButton(
                  icon: Icons.play_arrow_rounded,
                  size: 48,
                  iconSize: 24,
                  pressed: true,
                  onTap: () => ref
                      .read(playerControllerProvider)
                      .playItems(items, 0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.reciterName,
                        style: TextStyle(
                          color: neu.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${first.moshafName} · ${items.length} ${items.length == 1 ? 'سورة' : 'سور'} · ${formatBytes(totalBytes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: neu.subtext, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    if (isOpen) {
                      _expanded.remove(moshafId);
                    } else {
                      _expanded.add(moshafId);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: neu.subtext, size: 26),
                    ),
                  ),
                ),
              ],
            ),
            if (isOpen)
              for (final item in items) _surahRow(item, showReciter: false),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    final downloads = ref.watch(downloadsListProvider);
    final freeSpace = ref.watch(freeSpaceProvider).valueOrNull;

    final groups = <int, List<DownloadedSurah>>{};
    for (final item in downloads) {
      groups.putIfAbsent(item.moshafId, () => []).add(item);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Text(
            'التنزيلات',
            style: TextStyle(
              color: neu.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (!kIsWeb)
            NeuContainer(
              pressed: true,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, color: neu.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'المساحة المتوفرة للتنزيل',
                      style: TextStyle(color: neu.text, fontSize: 14),
                    ),
                  ),
                  Text(
                    freeSpace != null ? formatBytes(freeSpace) : '—',
                    style: TextStyle(color: neu.subtext, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (!kIsWeb) const SizedBox(height: 12),
          Text(
            kIsWeb
                ? 'التنزيل للاستماع دون إنترنت متاح في تطبيق أندرويد فقط'
                : downloads.isEmpty
                    ? 'الملفات التي تنزلها تظهر هنا لتشغيلها دون إنترنت'
                    : '${downloads.length} ${downloads.length == 1 ? 'سورة محفوظة' : 'سور محفوظة'}',
            style: TextStyle(color: neu.subtext, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (downloads.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.download_rounded, size: 56, color: neu.subtext),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد تنزيلات بعد',
                      style:
                          TextStyle(color: neu.subtext, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                for (final entry in const [
                  (false, Icons.view_list_rounded, 'الكل'),
                  (true, Icons.folder_rounded, 'حسب القارئ'),
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                          end: entry.$1 ? 0 : 8),
                      child: NeuContainer(
                        pressed: _grouped != entry.$1,
                        color: _grouped == entry.$1 ? neu.accent : null,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onTap: () => setState(() => _grouped = entry.$1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              entry.$2,
                              size: 18,
                              color: _grouped == entry.$1
                                  ? Colors.white
                                  : neu.subtext,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.$3,
                              style: TextStyle(
                                color: _grouped == entry.$1
                                    ? Colors.white
                                    : neu.subtext,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_grouped)
              for (final item in downloads)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NeuContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: _surahRow(item),
                  ),
                )
            else
              for (final entry in groups.entries)
                _groupCard(entry.key, entry.value),
          ],
        ],
      ),
    );
  }
}
