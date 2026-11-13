import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/neu_colors.dart';
import '../core/widgets/neu_widgets.dart';
import '../features/athkar/athkar_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/player/mini_player.dart';
import '../features/radio/radio_screen.dart';
import '../features/reciters/reciters_screen.dart';
import '../features/settings/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'الرئيسية'),
    (icon: Icons.radio_rounded, label: 'الإذاعات'),
    (icon: Icons.self_improvement_rounded, label: 'الأذكار'),
    (icon: Icons.download_rounded, label: 'التنزيلات'),
    (icon: Icons.settings_rounded, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final content = IndexedStack(
      index: _index,
      children: const [
        RecitersScreen(),
        RadioScreen(),
        AthkarScreen(),
        DownloadsScreen(),
        SettingsScreen(),
      ],
    );

    if (landscape) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _VerticalNav(
                  index: _index,
                  onChanged: (i) => setState(() => _index = i),
                ),
                const SizedBox(width: 12),
                Expanded(child: content),
                const SizedBox(width: 12),
                const MiniPlayerRail(),
              ],
            ),
          ),
        ),
      );
    }

    final neu = context.neu;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: content),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NeuContainer(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(6),
          radius: 28,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 64,
                      decoration: BoxDecoration(
                        color: _index == i
                            ? neu.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _tabs[i].icon,
                            size: 26,
                            color: _index == i ? neu.accent : neu.subtext,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _index == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _index == i ? neu.accent : neu.subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalNav extends StatelessWidget {
  const _VerticalNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'الرئيسية'),
    (icon: Icons.radio_rounded, label: 'الإذاعات'),
    (icon: Icons.self_improvement_rounded, label: 'الأذكار'),
    (icon: Icons.download_rounded, label: 'التنزيلات'),
    (icon: Icons.settings_rounded, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const padding = 8.0;
        final itemHeight =
            ((constraints.maxHeight - padding * 2 - gap * (_tabs.length - 1)) /
                    _tabs.length)
                .clamp(48.0, 80.0);
        final compact = itemHeight < 62;
        return NeuContainer(
          padding: const EdgeInsets.all(padding),
          radius: 28,
          child: Column(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == _tabs.length - 1 ? 0 : gap,
                  ),
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 88,
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: index == i
                            ? neu.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _tabs[i].icon,
                            size: compact ? 22 : 26,
                            color: index == i ? neu.accent : neu.subtext,
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              fontWeight: index == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: index == i ? neu.accent : neu.subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
