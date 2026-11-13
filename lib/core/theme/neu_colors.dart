import 'package:flutter/material.dart';

@immutable
class NeuColors extends ThemeExtension<NeuColors> {
  const NeuColors({
    required this.background,
    required this.surface,
    required this.lightShadow,
    required this.darkShadow,
    required this.accent,
    required this.text,
    required this.subtext,
  });

  final Color background;
  final Color surface;
  final Color lightShadow;
  final Color darkShadow;
  final Color accent;
  final Color text;
  final Color subtext;

  List<BoxShadow> get raisedShadows => [
        BoxShadow(
          color: darkShadow,
          offset: const Offset(6, 6),
          blurRadius: 14,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: lightShadow,
          offset: const Offset(-6, -6),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];

  List<BoxShadow> get softShadows => [
        BoxShadow(
          color: darkShadow.withValues(alpha: 0.55),
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: lightShadow.withValues(alpha: 0.9),
          offset: const Offset(-4, -4),
          blurRadius: 10,
        ),
      ];

  @override
  NeuColors copyWith({
    Color? background,
    Color? surface,
    Color? lightShadow,
    Color? darkShadow,
    Color? accent,
    Color? text,
    Color? subtext,
  }) {
    return NeuColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      lightShadow: lightShadow ?? this.lightShadow,
      darkShadow: darkShadow ?? this.darkShadow,
      accent: accent ?? this.accent,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
    );
  }

  @override
  NeuColors lerp(ThemeExtension<NeuColors>? other, double t) {
    if (other is! NeuColors) return this;
    return NeuColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      lightShadow: Color.lerp(lightShadow, other.lightShadow, t)!,
      darkShadow: Color.lerp(darkShadow, other.darkShadow, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      text: Color.lerp(text, other.text, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
    );
  }
}

extension NeuTheme on BuildContext {
  NeuColors get neu => Theme.of(this).extension<NeuColors>()!;
}
