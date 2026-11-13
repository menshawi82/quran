import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants.dart';
import '../../data/local_store.dart';
import '../../data/models.dart';
import '../downloads/downloads_service.dart';

class QueueItem {
  const QueueItem({
    required this.moshafId,
    required this.server,
    required this.surahNumber,
    required this.reciterName,
    required this.moshafName,
    required this.useLocalFile,
  });

  final int moshafId;
  final String server;
  final int surahNumber;
  final String reciterName;
  final String moshafName;
  final bool useLocalFile;

  String get key => '${moshafId}_$surahNumber';
}

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final DownloadsService _downloads;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  QuranAudioHandler({required DownloadsService downloads})
      : _downloads = downloads {
    _player.playbackEventStream
        .map(_transformEvent)
        .pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
        unawaited(_persistSession());
      }
    });

    Timer? positionSaver;
    _player.playingStream.listen((playing) {
      positionSaver?.cancel();
      if (playing) {
        positionSaver = Timer.periodic(const Duration(seconds: 5), (_) {
          unawaited(_persistSession());
        });
      } else {
        unawaited(_persistSession());
      }
    });

    playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.completed) {
        unawaited(_persistSession());
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> playQueue(
    List<QueueItem> items,
    int startIndex, {
    Duration? resumeAt,
    bool autoplay = true,
  }) async {
    if (items.isEmpty) return;
    final sources = <AudioSource>[];
    final mediaItems = <MediaItem>[];
    var effectiveStart = startIndex.clamp(0, items.length - 1);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      var uri = surahAudioUrl(item.server, item.surahNumber);
      if (item.useLocalFile) {
        final local = await _downloads.localPath(item.moshafId, item.surahNumber);
        if (local != null) uri = 'file://$local';
      }
      mediaItems.add(
        MediaItem(
          id: item.key,
          title: 'سورة ${kSurahNames[item.surahNumber - 1]}',
          album: item.reciterName,
          artist: item.moshafName,
          extras: <String, dynamic>{
            'url': uri,
            'surahNumber': item.surahNumber,
            'moshafId': item.moshafId,
            'server': item.server,
            'reciterName': item.reciterName,
            'moshafName': item.moshafName,
          },
        ),
      );
      sources.add(AudioSource.uri(Uri.parse(uri)));
    }

    // If the requested starting surah has no playable source, start at 0.
    if (sources.isEmpty) return;
    effectiveStart = effectiveStart.clamp(0, sources.length - 1);

    queue.add(mediaItems);
    mediaItem.add(mediaItems[effectiveStart]);
    if (kIsWeb) {
      // just_audio_web can keep serving the old audio element when the source
      // is swapped mid-playback, so stop before loading a new queue.
      await _player.stop();
    }
    await _player.setAudioSources(
      sources,
      initialIndex: effectiveStart,
      initialPosition: resumeAt,
    );
    if (autoplay) {
      await play();
    } else {
      await _persistSession();
    }
  }

  Future<void> playRadio(RadioStation station) async {
    final item = MediaItem(
      id: 'radio_${station.id}',
      title: station.name,
      album: 'إذاعة مباشرة',
      artist: 'بث مباشر',
      isLive: true,
      extras: <String, dynamic>{'url': station.url, 'live': true},
    );
    queue.add([item]);
    mediaItem.add(item);
    if (kIsWeb) {
      await _player.stop();
    }
    await _player.setUrl(station.url);
    await play();
  }

  Future<void> restoreLastSession() async {
    final saved = LocalStore.lastSession;
    if (saved == null) return;
    final itemsJson = (saved['queue'] as List?) ?? [];
    if (itemsJson.isEmpty) return;

    final items = <QueueItem>[];
    for (final raw in itemsJson) {
      final map = Map<String, dynamic>.from(raw as Map);
      final moshafId = map['moshafId'] as int? ?? 0;
      final surahNumber = map['surahNumber'] as int? ?? 0;
      final server = map['server'] as String? ?? '';
      final downloaded =
          await _downloads.localPath(moshafId, surahNumber) != null;
      items.add(
        QueueItem(
          moshafId: moshafId,
          server: server,
          surahNumber: surahNumber,
          reciterName: map['reciterName'] as String? ?? '',
          moshafName: map['moshafName'] as String? ?? '',
          useLocalFile: downloaded,
        ),
      );
    }

    final index = (saved['index'] as int?) ?? 0;
    final positionMs = (saved['positionMs'] as int?) ?? 0;
    await playQueue(
      items,
      index,
      resumeAt: Duration(milliseconds: positionMs),
      autoplay: false,
    );
  }

  Future<void> _persistSession() async {
    if (queue.value.isEmpty) return;
    final index = _player.currentIndex ?? 0;
    if (index < 0 || index >= queue.value.length) return;
    if (queue.value[index].extras?['live'] == true) return;
    await LocalStore.saveLastSession({
      'queue': queue.value
          .map((m) => {
                'moshafId': m.extras?['moshafId'],
                'surahNumber': m.extras?['surahNumber'],
                'server': m.extras?['server'],
                'reciterName': m.extras?['reciterName'],
                'moshafName': m.extras?['moshafName'],
              })
          .toList(),
      'index': index,
      'positionMs': _player.position.inMilliseconds,
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _persistSession();
    await _player.stop();
    await super.stop();
  }

  Future<void> disposeHandler() => _player.dispose();
}
