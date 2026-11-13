import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import 'player_providers.dart';
import 'spinning_disc.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final handler = ref.watch(audioHandlerProvider);
    final mediaItem = ref.watch(currentMediaItemProvider).valueOrNull;
    final playback = ref.watch(playbackStateStreamProvider).valueOrNull;
    final position = ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationStreamProvider).valueOrNull ?? Duration.zero;

    final playing = playback?.playing ?? false;
    final isLocal = mediaItem?.extras?['url']?.toString().startsWith('file:') ?? false;
    final isLive = mediaItem?.extras?['live'] == true;
    final buffering = playback?.processingState == AudioProcessingState.buffering || playback?.processingState == AudioProcessingState.loading;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    final artwork = Container(
      width: landscape ? 170.0 : 220,
      height: landscape ? 170.0 : 220,
      decoration: BoxDecoration(shape: BoxShape.circle, color: neu.surface, boxShadow: neu.raisedShadows),
      child: Center(
        child: SpinningDisc(size: landscape ? 116.0 : 150, letter: mediaItem?.album ?? '', playing: playing),
      ),
    );

    final title = Text(
      mediaItem?.title ?? '',
      textAlign: TextAlign.center,
      style: TextStyle(color: neu.text, fontSize: landscape ? 22 : 28, fontWeight: FontWeight.w800),
    );

    final subtitle = Text(
      '${mediaItem?.album ?? ''} · ${mediaItem?.artist ?? ''}',
      textAlign: TextAlign.center,
      style: TextStyle(color: neu.subtext, fontSize: 15),
    );

    final seekBar = Directionality(
      textDirection: Directionality.of(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: NeuSeekBar(position: position, duration: duration, onSeek: handler.seek, height: 22),
      ),
    );

    final timeRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formatDuration(position), style: TextStyle(color: neu.subtext, fontSize: 13)),
          Text(formatDuration(duration), style: TextStyle(color: neu.subtext, fontSize: 13)),
        ],
      ),
    );

    final progressSection = isLive
        ? Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.podcasts_rounded, color: neu.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    buffering ? 'جاري الاتصال بالبث...' : 'بث مباشر',
                    style: TextStyle(color: neu.accent, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (playing && !buffering) ...[const SizedBox(width: 8), _LiveDot(color: Colors.redAccent)],
                ],
              ),
            ],
          )
        : Column(children: [seekBar, const SizedBox(height: 8), timeRow]);

    final controlsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!isLive)
          NeuIconButton(icon: Icons.skip_next_rounded, size: landscape ? 60 : 72, onTap: handler.skipToPrevious)
        else
          SizedBox(width: landscape ? 60 : 72),
        NeuContainer(
          width: landscape ? 84 : 96,
          height: landscape ? 84 : 96,
          radius: 32,
          color: neu.accent,
          onTap: playing ? handler.pause : handler.play,
          alignment: Alignment.center,
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48, color: Colors.white),
        ),
        if (!isLive)
          NeuIconButton(icon: Icons.skip_previous_rounded, size: landscape ? 60 : 72, onTap: handler.skipToNext)
        else
          SizedBox(width: landscape ? 60 : 72),
      ],
    );

    final centerContent = landscape
        ? Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [artwork, const SizedBox(height: 16), title, const SizedBox(height: 8), subtitle],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [progressSection, const SizedBox(height: 32), controlsRow]),
              ),
            ],
          )
        : Column(
            children: [
              const Spacer(),
              artwork,
              const SizedBox(height: 32),
              title,
              const SizedBox(height: 8),
              subtitle,
              const SizedBox(height: 28),
              progressSection,
              const Spacer(),
              controlsRow,
              const SizedBox(height: 24),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  NeuIconButton(icon: Icons.keyboard_arrow_down_rounded, size: 56, onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Column(
                    children: [
                      Text('نستمع الآن إلى', style: TextStyle(color: neu.subtext, fontSize: 13)),
                      if (isLocal)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 14, color: neu.accent),
                              const SizedBox(width: 4),
                              Text('ملف محلي', style: TextStyle(color: neu.accent, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 56),
                ],
              ),
              Expanded(child: centerContent),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
