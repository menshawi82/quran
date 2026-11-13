import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../core/storage_info.dart';
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
  final Dio _dio = Dio();

  final Map<String, double> _progress = {};
  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  BatchProgress? _batch;
  CancelToken? _batchCancelToken;
  final _batchController = StreamController<BatchProgress?>.broadcast();
  Stream<BatchProgress?> get batchStream => _batchController.stream;

  var _version = 0;
  final _changedController = StreamController<int>.broadcast();
  Stream<int> get changedStream => _changedController.stream;

  void _updateProgress(String key, double? value) {
    if (value == null) {
      _progress.remove(key);
    } else {
      _progress[key] = value;
    }
    _progressController.add(Map.unmodifiable(_progress));
  }

  void _bumpVersion() => _changedController.add(++_version);

  static String keyOf(int moshafId, int surahNumber) =>
      LocalStore.downloadKey(moshafId, surahNumber);

  bool isDownloaded(int moshafId, int surahNumber) =>
      LocalStore.isDownloaded(moshafId, surahNumber);

  Future<Directory>? _cachedRoot;
  String? _cachedRootKey;

  Future<Directory> _downloadsRoot() {
    final key = LocalStore.storageLocation;
    final cached = _cachedRoot;
    if (cached != null && _cachedRootKey == key) return cached;
    final future = _resolveRoot();
    _cachedRoot = future;
    _cachedRootKey = key;
    return future;
  }

  Future<Directory> _resolveRoot() async {
    if (LocalStore.storageLocation == 'external') {
      final external = await _externalDir();
      if (external != null) return external;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final root = Directory('${appDir.path}/downloads');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<Directory?> _externalDir() async {
    final dirs = await getExternalStorageDirectories();
    if (dirs == null || dirs.length < 2) return null;
    final root = Directory('${dirs.last.path}/downloads');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<bool> hasExternalStorage() async => (await _externalDir()) != null;

  Future<int?> freeSpaceBytes() async {
    final root = await _downloadsRoot();
    return StorageInfo.freeBytes(root.path);
  }

  Future<Directory> _moshafDir(int moshafId) async {
    final root = await _downloadsRoot();
    final dir = Directory('${root.path}/$moshafId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> localPath(int moshafId, int surahNumber) async {
    final meta = LocalStore.getDownload(moshafId, surahNumber);
    if (meta == null) return null;
    final saved = meta['filePath'] as String?;
    if (saved != null && File(saved).existsSync()) return saved;
    final root = await _downloadsRoot();
    final candidate = '${root.path}/$moshafId/${surahFileName(surahNumber)}';
    if (File(candidate).existsSync()) return candidate;
    return null;
  }

  Future<void> download({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNumber,
    CancelToken? cancelToken,
  }) async {
    final key = keyOf(moshaf.id, surahNumber);
    if (LocalStore.isDownloaded(moshaf.id, surahNumber)) return;

    _updateProgress(key, 0);
    final dir = await _moshafDir(moshaf.id);
    final filePath = '${dir.path}/${surahFileName(surahNumber)}';
    try {
      await _dio.download(
        surahAudioUrl(moshaf.server, surahNumber),
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) _updateProgress(key, received / total);
        },
      );
      await LocalStore.putDownload(moshaf.id, surahNumber, {
        'moshafId': moshaf.id,
        'surahNumber': surahNumber,
        'reciterName': reciter.name,
        'moshafName': moshaf.name,
        'server': moshaf.server,
        'filePath': filePath,
      });
      _bumpVersion();
    } on DioException catch (e) {
      final partial = File(filePath);
      if (await partial.exists()) await partial.delete();
      if (e.type != DioExceptionType.cancel) rethrow;
    } catch (_) {
      final partial = File(filePath);
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      _updateProgress(key, null);
    }
  }

  bool get isBatchRunning => _batch != null;

  Future<void> downloadMoshaf({
    required Reciter reciter,
    required Moshaf moshaf,
  }) async {
    if (_batch != null) return;
    final numbers = List<int>.generate(
      114,
      (i) => i + 1,
    ).where(moshaf.hasSurah).toList();
    final pending = numbers
        .where((n) => !LocalStore.isDownloaded(moshaf.id, n))
        .toList();
    if (pending.isEmpty) return;
    final cancelToken = CancelToken();
    _batchCancelToken = cancelToken;
    var done = numbers.length - pending.length;
    void emit(int current) {
      _batch = BatchProgress(
        moshafId: moshaf.id,
        done: done,
        total: numbers.length,
        currentSurah: current,
      );
      _batchController.add(_batch);
    }

    emit(pending.first);
    try {
      for (final n in pending) {
        if (cancelToken.isCancelled) break;
        emit(n);
        await download(
          reciter: reciter,
          moshaf: moshaf,
          surahNumber: n,
          cancelToken: cancelToken,
        );
        if (cancelToken.isCancelled) break;
        done++;
        emit(n);
      }
    } finally {
      _batch = null;
      _batchCancelToken = null;
      _batchController.add(null);
    }
  }

  void cancelBatch() => _batchCancelToken?.cancel();

  Future<void> migrateToCurrentStorage() async {
    final metas = LocalStore.allDownloads;
    if (metas.isEmpty) return;
    final root = await _downloadsRoot();
    for (final meta in metas) {
      final oldPath = meta['filePath'] as String?;
      if (oldPath == null) continue;
      final oldFile = File(oldPath);
      if (!await oldFile.exists()) continue;
      final moshafId = meta['moshafId'] as int;
      final surah = meta['surahNumber'] as int;
      final dir = Directory('${root.path}/$moshafId');
      if (!await dir.exists()) await dir.create(recursive: true);
      final newPath = '${dir.path}/${surahFileName(surah)}';
      if (newPath == oldPath) continue;
      await oldFile.copy(newPath);
      await oldFile.delete();
      meta['filePath'] = newPath;
      await LocalStore.putDownload(
        moshafId,
        surah,
        Map<String, dynamic>.from(meta),
      );
    }
    _bumpVersion();
  }

  Future<void> delete(int moshafId, int surahNumber) async {
    final meta = LocalStore.getDownload(moshafId, surahNumber);
    final filePath = meta?['filePath'] as String?;
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    }
    await LocalStore.deleteDownload(moshafId, surahNumber);
    _bumpVersion();
  }

  int fileSizeBytes(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  List<DownloadedSurah> all() {
    final items = LocalStore.allDownloads
        .map(
          (e) => DownloadedSurah(
            moshafId: e['moshafId'] as int,
            surahNumber: e['surahNumber'] as int,
            reciterName: e['reciterName'] as String? ?? '',
            moshafName: e['moshafName'] as String? ?? '',
            server: e['server'] as String? ?? '',
            filePath: e['filePath'] as String? ?? '',
          ),
        )
        .toList();
    items.sort((a, b) {
      final byReciter = a.reciterName.compareTo(b.reciterName);
      if (byReciter != 0) return byReciter;
      final byMoshaf = a.moshafName.compareTo(b.moshafName);
      if (byMoshaf != 0) return byMoshaf;
      return a.surahNumber.compareTo(b.surahNumber);
    });
    return items;
  }
}
