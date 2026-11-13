import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../../data/local_store.dart';
import '../../data/models.dart';
import '../downloads/downloads_service.dart';
import '../player/mini_player.dart';
import '../player/player_providers.dart';
import '../settings/settings_controller.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({
    super.key,
    required this.reciter,
    required this.moshaf,
  });

  final Reciter reciter;
  final Moshaf moshaf;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int surahNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final neu = dialogContext.neu;
        return AlertDialog(
          backgroundColor: neu.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('حذف التنزيل؟',
              style: TextStyle(color: neu.text)),
          content: Text(
            'سيتم حذف سورة ${kSurahNames[surahNumber - 1]} من جهازك',
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
          .delete(moshaf.id, surahNumber);
      if (context.mounted) _showMessage(context, 'تم حذف السورة');
    }
  }

  Future<void> _confirmDownloadAll(
      BuildContext context, WidgetRef ref, List<int> numbers) async {
    final service = ref.read(downloadsServiceProvider);
    if (ref.read(settingsProvider).offlineMode) {
      _showMessage(context, 'لا يمكن التنزيل أثناء وضع الأوفلاين');
      return;
    }
    if (service.isBatchRunning) {
      _showMessage(context, 'يوجد تنزيل مصحف جار حاليا');
      return;
    }
    final pending =
        numbers.where((n) => !service.isDownloaded(moshaf.id, n)).length;
    if (pending == 0) {
      _showMessage(context, 'كل السور محفوظة بالفعل');
      return;
    }
    final free = await ref.read(freeSpaceProvider.future);
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final neu = dialogContext.neu;
        return AlertDialog(
          backgroundColor: neu.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('تنزيل المصحف كاملا؟',
              style: TextStyle(color: neu.text)),
          content: Text(
            'سيتم تنزيل $pending سورة بصوت ${reciter.name}. '
            'قد يتجاوز الحجم 600 ميغابايت حسب طول السور. '
            'المساحة المتوفرة: ${free != null ? formatBytes(free) : 'غير معروفة'}',
            style: TextStyle(color: neu.subtext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('إلغاء', style: TextStyle(color: neu.subtext)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('تنزيل', style: TextStyle(color: neu.accent)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await service.downloadMoshaf(reciter: reciter, moshaf: moshaf);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final settings = ref.watch(settingsProvider);
    ref.watch(downloadsChangedProvider);
    final progress =
        ref.watch(downloadProgressProvider).valueOrNull ?? const <String, double>{};
    final batch = ref.watch(batchProgressProvider).valueOrNull;
    final batchHere = batch != null && batch.moshafId == moshaf.id;

    final numbers =
        List<int>.generate(114, (i) => i + 1).where(moshaf.hasSurah).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  NeuIconButton(
                    icon: Icons.arrow_forward_rounded,
                    size: 56,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reciter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: neu.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          moshaf.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: neu.subtext, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!kIsWeb) ...[
                    NeuIconButton(
                      icon: Icons.download_rounded,
                      size: 56,
                      iconSize: 24,
                      onTap: numbers.isEmpty
                          ? null
                          : () => _confirmDownloadAll(context, ref, numbers),
                    ),
                    const SizedBox(width: 10),
                  ],
                  NeuContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    radius: 22,
                    color: neu.accent,
                    onTap: numbers.isEmpty
                        ? null
                        : () => ref.read(playerControllerProvider).playSurah(
                              reciter: reciter,
                              moshaf: moshaf,
                              surahNumber: numbers.first,
                            ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'تشغيل الكل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (batchHere)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: NeuContainer(
                  pressed: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, color: neu.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'جاري تنزيل المصحف ${batch.done}/${batch.total} — سورة ${kSurahNames[batch.currentSurah - 1]}',
                              style: TextStyle(
                                color: neu.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: batch.fraction,
                                minHeight: 8,
                                backgroundColor:
                                    neu.subtext.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation(neu.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(downloadsServiceProvider)
                            .cancelBatch(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded,
                              color: neu.subtext, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: numbers.isEmpty
                  ? Center(
                      child: Text('لا توجد سور متاحة في هذه الرواية',
                          style: TextStyle(color: neu.subtext)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: numbers.length,
                      itemBuilder: (context, index) {
                        final surahNumber = numbers[index];
                        final name = kSurahNames[surahNumber - 1];
                        final downloads =
                            ref.read(downloadsServiceProvider);
                        final downloaded = downloads.isDownloaded(
                            moshaf.id, surahNumber);
                        final key =
                            LocalStore.downloadKey(moshaf.id, surahNumber);
                        final isDownloading = progress.containsKey(key);
                        final downloadFraction = progress[key] ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NeuContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            onTap: () {
                              if (settings.offlineMode && !downloaded) {
                                _showMessage(context,
                                    'هذه السورة غير محفوظة على جهازك');
                                return;
                              }
                              ref
                                  .read(playerControllerProvider)
                                  .playSurah(
                                    reciter: reciter,
                                    moshaf: moshaf,
                                    surahNumber: surahNumber,
                                  );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: neu.accent
                                        .withValues(alpha: 0.12),
                                  ),
                                  child: Text(
                                    '$surahNumber',
                                    style: TextStyle(
                                      color: neu.accent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'سورة $name',
                                    style: TextStyle(
                                      color: neu.text,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isDownloading)
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: downloadFraction > 0
                                              ? downloadFraction
                                              : null,
                                          strokeWidth: 3,
                                          color: neu.accent,
                                        ),
                                        Text(
                                          '${(downloadFraction * 100).round()}',
                                          style: TextStyle(
                                              color: neu.subtext,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (downloaded)
                                  GestureDetector(
                                    onTap: () => _confirmDelete(
                                        context, ref, surahNumber),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: neu.accent
                                            .withValues(alpha: 0.15),
                                      ),
                                      child: Icon(Icons.check_rounded,
                                          color: neu.accent, size: 24),
                                    ),
                                  )
                                else if (!kIsWeb)
                                  NeuIconButton(
                                    icon: Icons.download_rounded,
                                    size: 48,
                                    iconSize: 22,
                                    onTap: () {
                                      if (settings.offlineMode) {
                                        _showMessage(context,
                                            'لا يمكن التنزيل أثناء وضع الأوفلاين');
                                        return;
                                      }
                                      ref
                                          .read(downloadsServiceProvider)
                                          .download(
                                            reciter: reciter,
                                            moshaf: moshaf,
                                            surahNumber: surahNumber,
                                          );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
