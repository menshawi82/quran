import 'package:flutter/material.dart';

import '../theme/neu_colors.dart';

class NeuContainer extends StatelessWidget {
  const NeuContainer({
    super.key,
    required this.child,
    this.radius = 20,
    this.pressed = false,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.color,
    this.alignment,
  });

  final Widget child;
  final double radius;
  final bool pressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? color;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    final bg = color ?? neu.surface;
    final decorationColor = pressed
        ? Color.alphaBlend(neu.darkShadow.withValues(alpha: 0.18), bg)
        : bg;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: decorationColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: pressed ? null : neu.softShadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 64,
    this.pressed = false,
    this.iconSize = 28,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool pressed;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    return NeuContainer(
      width: size,
      height: size,
      radius: size / 3.2,
      pressed: pressed,
      onTap: onTap,
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: iconColor ?? neu.text),
    );
  }
}

class NeuSwitch extends StatelessWidget {
  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 92,
    this.height = 48,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: neu.surface,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: neu.softShadows,
        ),
        padding: const EdgeInsets.all(5),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: height - 10,
            height: height - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? neu.accent : neu.subtext.withValues(alpha: 0.5),
              boxShadow: neu.softShadows,
            ),
            child: Icon(
              value ? Icons.check : Icons.close,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class NeuSeekBar extends StatefulWidget {
  const NeuSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.height = 20,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final double height;

  @override
  State<NeuSeekBar> createState() => _NeuSeekBarState();
}

class _NeuSeekBarState extends State<NeuSeekBar> {
  double? _dragFraction;

  void _seekFromLocalPosition(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final raw = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final fraction = isRtl ? 1.0 - raw : raw;
    setState(() => _dragFraction = fraction);
  }

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    final totalMs = widget.duration.inMilliseconds;
    final fraction = _dragFraction ??
        (totalMs <= 0
            ? 0.0
            : (widget.position.inMilliseconds / totalMs).clamp(0.0, 1.0));
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final progressAlignment =
        isRtl ? const Alignment(1, 0) : const Alignment(-1, 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (d) => _seekFromLocalPosition(context, d.localPosition),
          onTapUp: (d) {
            final box = context.findRenderObject()! as RenderBox;
            final raw = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
            final isRtl =
                Directionality.of(context) == TextDirection.rtl;
            final fraction = isRtl ? 1.0 - raw : raw;
            widget.onSeek(Duration(milliseconds: (fraction * totalMs).round()));
            setState(() => _dragFraction = null);
          },
          onHorizontalDragUpdate: (d) =>
              _seekFromLocalPosition(context, d.localPosition),
          onHorizontalDragEnd: (_) {
            if (_dragFraction != null) {
              widget.onSeek(
                  Duration(milliseconds: (_dragFraction! * totalMs).round()));
              setState(() => _dragFraction = null);
            }
          },
          child: NeuContainer(
            height: widget.height,
            radius: widget.height / 2,
            pressed: true,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Align(
                alignment: progressAlignment,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          neu.accent.withValues(alpha: 0.75),
                          neu.accent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NeuTextField extends StatelessWidget {
  const NeuTextField({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.prefixIcon,
    this.height = 56,
  });

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    return NeuContainer(
      height: height,
      radius: height / 2,
      pressed: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (prefixIcon != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Icon(prefixIcon, color: neu.subtext, size: 22),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.start,
              style: TextStyle(color: neu.text, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: neu.subtext),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
