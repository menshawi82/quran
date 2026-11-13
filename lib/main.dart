import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local_store.dart';
import 'features/downloads/downloads_service.dart';
import 'features/player/audio_handler.dart';
import 'features/player/player_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<_AppServices> _services = _initialize();

  Future<_AppServices> _initialize() async {
    await LocalStore.init();

    final downloads = DownloadsService();
    final audioHandler = await AudioService.init<QuranAudioHandler>(
      builder: () => QuranAudioHandler(downloads: downloads),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.talawat.quran.audio',
        androidNotificationChannelName: 'تلاوات',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      ),
    );

    // Session restore reloads the old queue into the player, which on web both
    // wastes a fetch and can race the user's first tap, so skip it there.
    if (!kIsWeb) {
      unawaited(audioHandler.restoreLastSession());
    }

    return _AppServices(audioHandler: audioHandler, downloads: downloads);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppServices>(
      future: _services,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupScreen(
            message: 'تعذر بدء التطبيق. يرجى إعادة تحميل الصفحة.',
            details: snapshot.error.toString(),
          );
        }

        final services = snapshot.data;
        if (services == null) {
          return const _StartupScreen(message: 'جارٍ تحميل التطبيق...');
        }

        return ProviderScope(
          overrides: [
            audioHandlerProvider.overrideWithValue(services.audioHandler),
            downloadsServiceProvider.overrideWithValue(services.downloads),
          ],
          child: const TalawatApp(),
        );
      },
    );
  }
}

class _AppServices {
  const _AppServices({required this.audioHandler, required this.downloads});

  final QuranAudioHandler audioHandler;
  final DownloadsService downloads;
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.message, this.details});

  final String message;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (details == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                ],
                Text(message, textAlign: TextAlign.center),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(details!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
