import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../downloads/downloads_service.dart';
import 'audio_handler.dart';

final audioHandlerProvider = Provider<QuranAudioHandler>(
    (ref) => throw UnimplementedError('override in main'));

final playbackStateStreamProvider = StreamProvider<PlaybackState>(
    (ref) => ref.watch(audioHandlerProvider).playbackState);

final currentMediaItemProvider = StreamProvider<MediaItem?>(
    (ref) => ref.watch(audioHandlerProvider).mediaItem);

final positionStreamProvider = StreamProvider<Duration>(
    (ref) => ref.watch(audioHandlerProvider).positionStream);

final durationStreamProvider = StreamProvider<Duration?>(
    (ref) => ref.watch(audioHandlerProvider).durationStream);

class PlayerController {
  PlayerController(this._ref);

  final Ref _ref;

  QuranAudioHandler get _handler => _ref.read(audioHandlerProvider);
  DownloadsService get _downloads => _ref.read(downloadsServiceProvider);

  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNumber,
  }) async {
    final numbers =
        List<int>.generate(114, (i) => i + 1).where(moshaf.hasSurah).toList();
    if (numbers.isEmpty) return;
    final items = numbers
        .map((n) => QueueItem(
              moshafId: moshaf.id,
              server: moshaf.server,
              surahNumber: n,
              reciterName: reciter.name,
              moshafName: moshaf.name,
              useLocalFile: _downloads.isDownloaded(moshaf.id, n),
            ))
        .toList();
    final startIndex = numbers.indexOf(surahNumber);
    await _handler.playQueue(items, startIndex < 0 ? 0 : startIndex);
  }

  Future<void> playDownloaded(DownloadedSurah item) async {
    final items = _downloads.all();
    final start = items.indexWhere((d) =>
        d.moshafId == item.moshafId && d.surahNumber == item.surahNumber);
    if (start < 0) return;
    await playItems(items, start);
  }

  Future<void> playItems(List<DownloadedSurah> items, int startIndex) async {
    if (items.isEmpty) return;
    final queue = items
        .map((d) => QueueItem(
              moshafId: d.moshafId,
              server: d.server,
              surahNumber: d.surahNumber,
              reciterName: d.reciterName,
              moshafName: d.moshafName,
              useLocalFile: true,
            ))
        .toList();
    final start = startIndex.clamp(0, queue.length - 1);
    await _handler.playQueue(queue, start);
  }

  Future<void> playRadio(RadioStation station) =>
      _handler.playRadio(station);
}

final playerControllerProvider =
    Provider<PlayerController>((ref) => PlayerController(ref));
