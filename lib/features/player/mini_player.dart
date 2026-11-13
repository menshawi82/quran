import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import 'player_providers.dart';
import 'player_screen.dart';
import 'spinning_disc.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final mediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final playback = ref.watch(playbackStateStreamProvider).valueOrNull;
    if (mediaItem == null) return const SizedBox.shrink();

    final playing = playback?.playing ?? false;

    return NeuContainer(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(8),
      radius: 24,
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
      ),
      child: Row(
        children: [
          NeuIconButton(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 56,
            iconSize: 30,
            onTap: () {
              final handler = ref.read(audioHandlerProvider);
              playing ? handler.pause() : handler.play();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: neu.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mediaItem.album} · ${mediaItem.artist ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: neu.subtext, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Icon(Icons.keyboard_arrow_up_rounded,
                color: neu.subtext, size: 28),
          ),
        ],
      ),
    );
  }
}

class MiniPlayerRail extends ConsumerWidget {
  const MiniPlayerRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final mediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final playback = ref.watch(playbackStateStreamProvider).valueOrNull;
    if (mediaItem == null) return const SizedBox.shrink();

    final playing = playback?.playing ?? false;
    final isLive = mediaItem.extras?['live'] == true;
    final handler = ref.read(audioHandlerProvider);

    return NeuContainer(
      width: 220,
      padding: const EdgeInsets.all(12),
      radius: 24,
      child: Column(
        children: [
          NeuContainer(
            width: 110,
            height: 110,
            radius: 55,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
            ),
            child: SpinningDisc(
              size: 84,
              letter: mediaItem.album ?? '',
              playing: playing,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mediaItem.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: neu.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mediaItem.album} · ${mediaItem.artist ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: neu.subtext, fontSize: 12),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLive) ...[
                NeuIconButton(
                  icon: Icons.skip_next_rounded,
                  size: 44,
                  iconSize: 22,
                  onTap: handler.skipToPrevious,
                ),
                const SizedBox(width: 10),
              ],
              NeuIconButton(
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 60,
                iconSize: 30,
                onTap: () => playing ? handler.pause() : handler.play(),
              ),
              if (!isLive) ...[
                const SizedBox(width: 10),
                NeuIconButton(
                  icon: Icons.skip_previous_rounded,
                  size: 44,
                  iconSize: 22,
                  onTap: handler.skipToNext,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
            ),
            child: Icon(Icons.keyboard_arrow_up_rounded,
                color: neu.subtext, size: 26),
          ),
        ],
      ),
    );
  }
}
