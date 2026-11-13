import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../player/player_providers.dart';
import '../radio/radio_controller.dart';
import '../settings/settings_controller.dart';
import 'athkar_data.dart';

class AthkarScreen extends ConsumerWidget {
  const AthkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأذكار',
                style: TextStyle(
                  color: neu.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'حصن المسلم من أذكار الصباح والمساء والرقية',
                style: TextStyle(color: neu.subtext, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _athkarCard(
            context,
            icon: Icons.wb_sunny_rounded,
            title: 'أذكار الصباح',
            subtitle: '${morningAthkar.length} ذكرا بأسانيده من حصن المسلم',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AthkarListScreen(
                  title: 'أذكار الصباح',
                  items: morningAthkar,
                ),
              ),
            ),
          ),
          _athkarCard(
            context,
            icon: Icons.nights_stay_rounded,
            title: 'أذكار المساء',
            subtitle: '${eveningAthkar.length} ذكرا بأسانيده من حصن المسلم',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AthkarListScreen(
                  title: 'أذكار المساء',
                  items: eveningAthkar,
                ),
              ),
            ),
          ),
          _athkarCard(
            context,
            icon: Icons.healing_rounded,
            title: 'الرقية الشرعية',
            subtitle: 'استماع مباشر لبث الرقية الشرعية',
            disabled: settings.offlineMode,
            disabledHint: 'تحتاج اتصالا بالإنترنت',
            onTap: () {
              if (settings.offlineMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرقية الشرعية تحتاج اتصالا بالإنترنت'),
                  ),
                );
                return;
              }
              ref.read(playerControllerProvider).playRadio(ruqyahStation);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _athkarCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool disabled = false,
    String? disabledHint,
  }) {
    final neu = context.neu;
    final foreground = disabled ? neu.subtext : neu.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuContainer(
        padding: const EdgeInsets.all(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: disabled
                    ? neu.subtext.withValues(alpha: 0.10)
                    : neu.accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: disabled ? neu.subtext : neu.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disabled ? (disabledHint ?? subtitle) : subtitle,
                    style: TextStyle(color: neu.subtext, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: neu.subtext),
          ],
        ),
      ),
    );
  }
}

class AthkarListScreen extends ConsumerStatefulWidget {
  const AthkarListScreen({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<AthkarItem> items;

  @override
  ConsumerState<AthkarListScreen> createState() => _AthkarListScreenState();
}

class _AthkarListScreenState extends ConsumerState<AthkarListScreen> {
  late List<int> _remaining = widget.items.map((e) => e.count).toList();

  void _tap(int index) {
    setState(() {
      if (_remaining[index] > 0) _remaining[index]--;
    });
  }

  void _reset() => setState(() {
        _remaining = widget.items.map((e) => e.count).toList();
      });

  @override
  Widget build(BuildContext context) {
    final neu = context.neu;
    final done = _remaining.where((r) => r == 0).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                NeuIconButton(
                  icon: Icons.arrow_forward_rounded,
                  size: 52,
                  iconSize: 24,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: neu.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'أنجزت $done من ${widget.items.length}',
                        style: TextStyle(color: neu.subtext, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                NeuIconButton(
                  icon: Icons.restart_alt_rounded,
                  size: 52,
                  iconSize: 24,
                  onTap: _reset,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: widget.items.isEmpty
                      ? 0
                      : done / widget.items.length,
                  minHeight: 8,
                  backgroundColor: neu.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(neu.accent),
                ),
              ),
            ),
            for (var i = 0; i < widget.items.length; i++)
              _athkarItem(i, widget.items[i], _remaining[i]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _athkarItem(int index, AthkarItem item, int remaining) {
    final neu = context.neu;
    final isDone = remaining == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuContainer(
        pressed: true,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: TextStyle(
                      color: isDone ? neu.subtext : neu.text,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'التكرار: ${item.count}',
                    style: TextStyle(color: neu.subtext, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _tap(index),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? neu.accent
                      : neu.accent.withValues(alpha: 0.12),
                  boxShadow: neu.softShadows,
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 28)
                    : Text(
                        '$remaining',
                        style: TextStyle(
                          color: neu.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
