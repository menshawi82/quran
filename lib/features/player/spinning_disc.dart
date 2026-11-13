import 'package:flutter/material.dart';

import '../../core/theme/neu_colors.dart';

class SpinningDisc extends StatefulWidget {
  const SpinningDisc({
    super.key,
    required this.size,
    required this.letter,
    required this.playing,
  });

  final double size;
  final String letter;
  final bool playing;

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFF3A3F47), Color(0xFF14161A)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final f in const [0.86, 0.68, 0.50])
              Container(
                width: widget.size * f,
                height: widget.size * f,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            Container(
              width: widget.size * 0.38,
              height: widget.size * 0.38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neu.accent,
              ),
              child: Text(
                widget.letter.isEmpty ? '' : widget.letter.substring(0, 1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
