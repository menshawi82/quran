import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/neu_colors.dart';
import '../../core/widgets/neu_widgets.dart';
import '../downloads/downloads_service.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _downloadAndroidApk(BuildContext context) async {
    final apkUri = Uri.base.resolve('downloads/talawat-android.apk');
    final launched = await launchUrl(
      apkUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط تنزيل تطبيق أندرويد')),
      );
    }
  }

  Future<void> _pickStorageLocation(
    BuildContext context,
    WidgetRef ref,
    AppStorageLocation location,
  ) async {
    final settings = ref.read(settingsProvider);
    if (settings.storageLocation == location) return;

    var migrate = false;
    final hasDownloads = ref.read(downloadsServiceProvider).all().isNotEmpty;
    if (hasDownloads) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final neu = dialogContext.neu;
          return AlertDialog(
            backgroundColor: neu.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text('نقل التنزيلات؟', style: TextStyle(color: neu.text)),
            content: Text(
              'لديك تنزيلات محفوظة. هل تريد نقلها إلى الموقع الجديد؟',
              style: TextStyle(color: neu.subtext),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('cancel'),
                child: Text('إلغاء', style: TextStyle(color: neu.subtext)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('keep'),
                child: Text(
                  'تركها في مكانها',
                  style: TextStyle(color: neu.subtext),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('migrate'),
                child: Text('نقلها', style: TextStyle(color: neu.accent)),
              ),
            ],
          );
        },
      );
      if (choice == null || choice == 'cancel') return;
      migrate = choice == 'migrate';
    }

    ref.read(settingsProvider.notifier).setStorageLocation(location);
    ref.invalidate(freeSpaceProvider);
    if (migrate) {
      await ref.read(downloadsServiceProvider).migrateToCurrentStorage();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تم نقل التنزيلات')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neu = context.neu;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final hasExternal = ref.watch(externalStorageProvider).valueOrNull ?? false;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Text(
            'الإعدادات',
            style: TextStyle(
              color: neu.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          NeuContainer(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: settings.offlineMode
                        ? neu.accent.withValues(alpha: 0.15)
                        : neu.subtext.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    settings.offlineMode
                        ? Icons.wifi_off_rounded
                        : Icons.wifi_rounded,
                    color: settings.offlineMode ? neu.accent : neu.subtext,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وضع الأوفلاين الدائم',
                        style: TextStyle(
                          color: neu.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إيقاف كل طلبات الإنترنت والتشغيل من الملفات المحفوظة فقط',
                        style: TextStyle(color: neu.subtext, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                NeuSwitch(
                  value: settings.offlineMode,
                  onChanged: controller.setOfflineMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeuContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المظهر',
                  style: TextStyle(
                    color: neu.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final entry in const [
                      (
                        AppThemeMode.system,
                        Icons.brightness_auto_rounded,
                        'تلقائي',
                      ),
                      (AppThemeMode.light, Icons.wb_sunny_rounded, 'فاتح'),
                      (AppThemeMode.dark, Icons.dark_mode_rounded, 'داكن'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: NeuContainer(
                            pressed: settings.themeMode != entry.$1,
                            color: settings.themeMode == entry.$1
                                ? neu.accent
                                : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onTap: () => controller.setThemeMode(entry.$1),
                            child: Column(
                              children: [
                                Icon(
                                  entry.$2,
                                  color: settings.themeMode == entry.$1
                                      ? Colors.white
                                      : neu.subtext,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.$3,
                                  style: TextStyle(
                                    color: settings.themeMode == entry.$1
                                        ? Colors.white
                                        : neu.subtext,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (hasExternal)
            NeuContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مكان التنزيل',
                    style: TextStyle(
                      color: neu.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final entry in const [
                        (
                          AppStorageLocation.internal,
                          Icons.smartphone_rounded,
                          'الداخلية',
                        ),
                        (
                          AppStorageLocation.external,
                          Icons.sd_storage_rounded,
                          'بطاقة SD',
                        ),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: NeuContainer(
                              pressed: settings.storageLocation != entry.$1,
                              color: settings.storageLocation == entry.$1
                                  ? neu.accent
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onTap: () =>
                                  _pickStorageLocation(context, ref, entry.$1),
                              child: Column(
                                children: [
                                  Icon(
                                    entry.$2,
                                    color: settings.storageLocation == entry.$1
                                        ? Colors.white
                                        : neu.subtext,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.$3,
                                    style: TextStyle(
                                      color:
                                          settings.storageLocation == entry.$1
                                          ? Colors.white
                                          : neu.subtext,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (hasExternal) const SizedBox(height: 14),
          NeuContainer(
            pressed: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عن التطبيق',
                  style: TextStyle(
                    color: neu.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تلاوات — استماع للقرآن الكريم اونلاين واوفلاين',
                  style: TextStyle(color: neu.subtext, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'مصدر التلاوات: موقع mp3quran.net',
                  style: TextStyle(color: neu.subtext, fontSize: 13),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 14),
                  NeuContainer(
                    padding: const EdgeInsets.all(14),
                    onTap: () => _downloadAndroidApk(context),
                    child: Row(
                      children: [
                        Icon(Icons.android_rounded, color: neu.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تحميل تطبيق أندرويد',
                                style: TextStyle(
                                  color: neu.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تنزيل ملف APK',
                                style: TextStyle(
                                  color: neu.subtext,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.download_rounded, color: neu.accent),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'تطوير أكيد سوفت',
                      style: TextStyle(color: neu.text, fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    NeuIconButton(
                      icon: Icons.open_in_new_rounded,
                      size: 40,
                      iconSize: 20,
                      onTap: () => launchUrl(
                        Uri.parse('https://www.akeedsoft.com/ar/'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
