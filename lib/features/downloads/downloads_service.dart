import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'downloads_service_stub.dart'
    if (dart.library.io) 'downloads_service_io.dart';
export 'downloads_service_stub.dart'
    if (dart.library.io) 'downloads_service_io.dart';

final downloadsServiceProvider = Provider<DownloadsService>(
  (ref) => DownloadsService(),
);

final downloadProgressProvider = StreamProvider<Map<String, double>>(
  (ref) => ref.watch(downloadsServiceProvider).progressStream,
);

final downloadsChangedProvider = StreamProvider<int>(
  (ref) => ref.watch(downloadsServiceProvider).changedStream,
);

final batchProgressProvider = StreamProvider<BatchProgress?>(
  (ref) => ref.watch(downloadsServiceProvider).batchStream,
);

final externalStorageProvider = FutureProvider<bool>((ref) async {
  return ref.read(downloadsServiceProvider).hasExternalStorage();
});

final freeSpaceProvider = FutureProvider<int?>((ref) async {
  ref.watch(downloadsChangedProvider);
  return ref.read(downloadsServiceProvider).freeSpaceBytes();
});

final downloadsListProvider = Provider<List<DownloadedSurah>>((ref) {
  ref.watch(downloadsChangedProvider);
  return ref.read(downloadsServiceProvider).all();
});
