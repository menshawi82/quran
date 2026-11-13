import 'dart:async';

import 'package:dio/dio.dart';

import '../../data/local_store.dart';
import '../../data/models.dart';

class DownloadedSurah {
  const DownloadedSurah({
    required this.moshafId,
    required this.surahNumber,
    required this.reciterName,
    required this.moshafName,
    required this.server,
    required this.filePath,
  });

  final int moshafId;
  final int surahNumber;
  final String reciterName;
  final String moshafName;
  final String server;
  final String filePath;
}

class BatchProgress {
  const BatchProgress({
    required this.moshafId,
    required this.done,
    required this.total,
    required this.currentSurah,
  });

  final int moshafId;
  final int done;
  final int total;
  final int currentSurah;

  double get fraction => total == 0 ? 0 : done / total;
}

class DownloadsService {
  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  final _batchController = StreamController<BatchProgress?>.broadcast();
  Stream<BatchProgress?> get batchStream => _batchController.stream;

  final _changedController = StreamController<int>.broadcast();
  Stream<int> get changedStream => _changedController.stream;

  static String keyOf(int moshafId, int surahNumber) =>
      LocalStore.downloadKey(moshafId, surahNumber);

  bool isDownloaded(int moshafId, int surahNumber) => false;

  Future<bool> hasExternalStorage() async => false;

  Future<int?> freeSpaceBytes() async => null;

  Future<String?> localPath(int moshafId, int surahNumber) async => null;

  int fileSizeBytes(String path) => 0;

  Future<void> download({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNumber,
    CancelToken? cancelToken,
  }) async {}

  bool get isBatchRunning => false;

  Future<void> downloadMoshaf({
    required Reciter reciter,
    required Moshaf moshaf,
  }) async {}

  void cancelBatch() {}

  Future<void> migrateToCurrentStorage() async {}

  Future<void> delete(int moshafId, int surahNumber) async {}

  List<DownloadedSurah> all() => const [];
}
