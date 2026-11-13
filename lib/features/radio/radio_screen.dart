import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../../data/models.dart';
import '../player/player_providers.dart';
import '../settings/settings_controller.dart';
import 'radio_controller.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _cleanName(String name) =>
      name.replaceAll(RegExp(r'[-\s]+$'), '').trim();

  Widget _stationTile(RadioStation station) {
    final neu = context.neu;
    final mediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final playback = ref.watch(playbackStateStreamProvider).valueOrNull;
    final isThisLive = mediaItem?.extras?['live'] == true;
    final isPlaying = isThisLive &&
        mediaItem?.id == 'radio_${station.id}' &&
        (playback?.playing ?? false);
    final isFavorite =
        ref.watch(radioFavoritesProvider).contains(station.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuContainer(
        padding: const EdgeInsets.all(14),
        color: isPlaying ? neu.accent.withValues(alpha: 0.10) : null,
        onTap: () =>
            ref.read(playerControllerProvider).playRadio(station),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying
                    ? neu.accent
                    : neu.accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : neu.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanName(station.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: neu.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بث مباشر',
                    style: TextStyle(color: neu.subtext, fontSize: 13),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref
                  .read(radioFavoritesProvider.notifier)
                  .toggle(station.id),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    final settings = ref.watch(settingsProvider);
    final query = ref.watch(radioSearchQueryProvider).trim();
    final radiosAsync =
        settings.offlineMode ? null : ref.watch(radiosProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإذاعات',
                style: TextStyle(
                  color: neu.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'استمع مباشرة إلى إذاعات القرآن الكريم',
                style: TextStyle(color: neu.subtext, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (settings.offlineMode)
            NeuContainer(
              pressed: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: neu.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الإذاعات المباشرة تحتاج اتصالا بالإنترنت، أوقف وضع الأوفلاين للاستماع',
                      style: TextStyle(color: neu.text, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            NeuTextField(
              controller: _searchController,
              hint: 'ابحث عن إذاعة',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) => ref
                  .read(radioSearchQueryProvider.notifier)
                  .state = value,
            ),
            const SizedBox(height: 16),
            if (radiosAsync != null)
              radiosAsync.when(
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
                        Icon(Icons.cloud_off_rounded,
                            size: 48, color: neu.subtext),
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: neu.text, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        NeuContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          radius: 24,
                          color: neu.accent,
                          onTap: () => ref
                              .read(radiosProvider.notifier)
                              .refresh(),
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
                data: (stations) {
                  final filtered = query.isEmpty
                      ? stations
                      : [
                          if (cairoStation.name.contains(query))
                            cairoStation,
                          ...stations.where(
                              (s) => _cleanName(s.name).contains(query)),
                        ];
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'لا توجد نتائج مطابقة لبحثك',
                          style: TextStyle(
                              color: neu.subtext, fontSize: 15),
                        ),
                      ),
                    );
                  }
                  final favorites = ref.watch(radioFavoritesProvider);
                  final favoriteRadios = query.isEmpty
                      ? [cairoStation, ...filtered]
                          .where((s) => favorites.contains(s.id))
                          .toList()
                      : const <RadioStation>[];
                  final featured = query.isEmpty
                      ? () {
                          final indexed = <int, RadioStation>{};
                          for (final s in filtered) {
                            final i = featuredIndex(s);
                            if (i != null && !indexed.containsKey(i)) {
                              indexed[i] = s;
                            }
                          }
                          final list = indexed.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key));
                          return [
                            cairoStation,
                            ...list.map((e) => e.value),
                          ];
                        }()
                      : const <RadioStation>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (favoriteRadios.isNotEmpty) ...[
                        Padding(
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
                        for (final station in favoriteRadios)
                          _stationTile(station),
                        const SizedBox(height: 8),
                      ],
                      if (featured.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'إذاعات مميزة',
                            style: TextStyle(
                              color: neu.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (final station in featured)
                          _stationTile(station),
                        const SizedBox(height: 8),
                      ],
                      if (query.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'كل الإذاعات',
                            style: TextStyle(
                              color: neu.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      for (final station in filtered)
                        if (!featured.contains(station))
                          _stationTile(station),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
