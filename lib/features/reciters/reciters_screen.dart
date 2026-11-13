import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../../data/models.dart';
import '../settings/settings_controller.dart';
import '../surahs/surah_list_screen.dart';
import 'reciters_controller.dart';

class RecitersScreen extends ConsumerStatefulWidget {
  const RecitersScreen({super.key});

  @override
  ConsumerState<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends ConsumerState<RecitersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _reciterTile(BuildContext context, Reciter reciter) {
    final neu = context.neu;
    final isFavorite = ref.watch(favoritesProvider).contains(reciter.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuContainer(
        padding: const EdgeInsets.all(16),
        onTap: () => _openReciter(context, reciter),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neu.accent.withValues(alpha: 0.12),
              ),
              child: Text(
                reciter.letter,
                style: TextStyle(
                  color: neu.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.name,
                    style: TextStyle(
                      color: neu.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reciter.moshafs.isEmpty
                        ? 'لا توجد روايات'
                        : '${reciter.moshafs.length} ${reciter.moshafs.length == 1 ? 'رواية' : 'روايات'} · ${reciter.moshafs.first.surahTotal} سورة',
                    style: TextStyle(color: neu.subtext, fontSize: 13),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(favoritesProvider.notifier).toggle(reciter.id),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                  color: isFavorite ? Colors.redAccent : neu.subtext,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: neu.subtext,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReciter(BuildContext context, Reciter reciter) async {
    if (reciter.moshafs.isEmpty) return;
    if (reciter.moshafs.length == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SurahListScreen(reciter: reciter, moshaf: reciter.moshafs.first),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<Moshaf>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final neu = sheetContext.neu;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: NeuContainer(
            padding: const EdgeInsets.all(20),
            radius: 28,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اختر رواية ${reciter.name}',
                      style: TextStyle(
                        color: neu.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final moshaf in reciter.moshafs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NeuContainer(
                          pressed: true,
                          padding: const EdgeInsets.all(16),
                          onTap: () => Navigator.of(sheetContext).pop(moshaf),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  moshaf.name,
                                  style: TextStyle(
                                    color: neu.text,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                '${moshaf.surahTotal} سورة',
                                style: TextStyle(
                                  color: neu.subtext,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SurahListScreen(reciter: reciter, moshaf: selected),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final neu = context.neu;
    final settings = ref.watch(settingsProvider);
    final recitersAsync = ref.watch(recitersProvider);
    final query = ref.watch(reciterSearchQueryProvider);
    final favorites = ref.watch(favoritesProvider);

    final reciters = recitersAsync.valueOrNull ?? const <Reciter>[];
    final filtered = query.isEmpty
        ? reciters
        : reciters.where((r) => r.name.contains(query.trim())).toList();

    final grouped = <String, List<Reciter>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(r.letter.isEmpty ? '#' : r.letter, () => []).add(r);
    }
    final letters = grouped.keys.toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(recitersProvider.notifier).refresh(),
        color: neu.accent,
        backgroundColor: neu.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تلاوات',
                        style: TextStyle(
                          color: neu.text,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'استمع إلى القرآن الكريم اونلاين واوفلاين',
                        style: TextStyle(color: neu.subtext, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                NeuIconButton(
                  icon: settings.themeMode == AppThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.wb_sunny_rounded,
                  size: 56,
                  onTap: () {
                    final next = settings.themeMode == AppThemeMode.dark
                        ? AppThemeMode.light
                        : AppThemeMode.dark;
                    ref.read(settingsProvider.notifier).setThemeMode(next);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (settings.offlineMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeuContainer(
                  pressed: true,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: neu.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'وضع الأوفلاين مفعّل، التشغيل من الملفات المحفوظة فقط',
                          style: TextStyle(color: neu.text, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            NeuTextField(
              controller: _searchController,
              hint: 'ابحث عن قارئ',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) =>
                  ref.read(reciterSearchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            recitersAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: neu.accent),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 60),
                child: NeuContainer(
                  pressed: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: neu.subtext,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: neu.text, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      NeuContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        radius: 24,
                        color: neu.accent,
                        onTap: () =>
                            ref.read(recitersProvider.notifier).refresh(),
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        query.isEmpty
                            ? 'لا يوجد قراء'
                            : 'لا توجد نتائج مطابقة لبحثك',
                        style: TextStyle(color: neu.subtext, fontSize: 15),
                      ),
                    ),
                  );
                }
                final favoriteReciters = query.isEmpty
                    ? filtered.where((r) => favorites.contains(r.id)).toList()
                    : const <Reciter>[];
                return Column(
                  children: [
                    if (favoriteReciters.isNotEmpty) ...[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'المفضلون',
                            style: TextStyle(
                              color: neu.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      for (final reciter in favoriteReciters)
                        _reciterTile(context, reciter),
                      const SizedBox(height: 8),
                    ],
                    for (final letter in letters) ...[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: neu.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      for (final reciter in grouped[letter]!)
                        _reciterTile(context, reciter),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
