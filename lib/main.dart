import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local_store.dart';
import 'features/downloads/downloads_service.dart';
import 'features/player/audio_handler.dart';
import 'features/player/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();

  final downloads = DownloadsService();

  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(downloads: downloads),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.talawat.quran.audio',
      androidNotificationChannelName: 'تلاوات',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        downloadsServiceProvider.overrideWithValue(downloads),
      ],
      child: const TalawatApp(),
    ),
  );

  // Session restore reloads the old queue into the player, which on web both
  // wastes a fetch and can race the user's first tap, so skip it there.
  if (!kIsWeb) {
    unawaited(audioHandler.restoreLastSession());
  }
}
