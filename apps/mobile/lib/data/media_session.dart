import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../domain/text.dart';
import 'content.dart';
import 'recitation.dart';
import 'settings.dart';

/// What the lock screen / notification shows for the audio playing now.
class NowPlaying {
  const NowPlaying({
    required this.id,
    required this.title,
    required this.artist,
    required this.playing,
    this.canSkip = true,
    this.duration,
    this.position = Duration.zero,
    this.speed = 1.0,
  });
  final String id;
  final String title;
  final String artist;
  final bool playing;

  /// Show the previous / next buttons (off for live radio and single recordings).
  final bool canSkip;

  /// Length of the recording (null for live radio and per-ayah recitation): the lock screen
  /// then shows the elapsed time, the length and a seek bar that moves.
  final Duration? duration;

  /// Where playback is now. Not part of ==: the system moves its own bar from the last
  /// position it was given, so it only needs a new one when playback jumps (see the bridge).
  final Duration position;
  final double speed;

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.playing == playing &&
      other.canSkip == canSkip &&
      other.duration == duration &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(id, title, artist, playing, canSkip, duration, speed);
}

/// The system media controls (lock screen, notification, headset buttons).
abstract class MediaSession {
  /// [onAction] receives 'play', 'pause', 'next', 'previous' and 'stop';
  /// [onSeek] the position picked on the lock-screen seek bar.
  void bind(void Function(String action) onAction, {void Function(Duration to)? onSeek});
  void show(NowPlaying? now);
}

/// No system controls (tests, platforms without audio_service).
class NoMediaSession implements MediaSession {
  const NoMediaSession();
  @override
  void bind(void Function(String action) onAction, {void Function(Duration to)? onSeek}) {}
  @override
  void show(NowPlaying? now) {}
}

/// One of the app's players as the system media controls see it.
abstract class MediaSource implements Listenable {
  /// What it plays now; null when it has nothing loaded.
  NowPlaying? describe();

  /// 'play', 'pause', 'next', 'previous' or 'stop' from the lock screen / notification.
  void act(String action);
}

/// Keeps the system media controls in step with whichever player is in use
/// (recitation, Quran radio, live radio stations, the recitation library,
/// al-Sha'rawi, stories, nasheeds, adhkar recordings) and sends their buttons
/// back to it. With audio_service this also runs the Android media foreground
/// service, so the audio goes on when the user leaves the app or turns the screen off.
class RecitationMediaBridge {
  RecitationMediaBridge({
    required this.recitation,
    required this.content,
    required this.settings,
    required this.session,
    NarrationController? narration,
  }) {
    session.bind(_onAction, onSeek: _onSeek);
    _sources.add(_RecitationSource(this));
    if (narration != null) _sources.add(_NarrationSource(narration, settings));
    for (final src in _sources) {
      src.addListener(_sync);
    }
  }

  final RecitationController recitation;
  final AppContent content;
  final SettingsController settings;
  final MediaSession session;
  final _sources = <MediaSource>[];
  MediaSource? _active;
  NowPlaying? _last;
  DateTime _lastAt = DateTime.now();

  /// The clock (tests replace it).
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  /// What is shown now (null when nothing plays).
  NowPlaying? get nowPlaying => _last;

  /// Adds another player (e.g. the adhkar recordings); [detach] removes it.
  void attach(MediaSource src) {
    if (_sources.contains(src)) return;
    _sources.add(src);
    src.addListener(_sync);
    _sync();
  }

  void detach(MediaSource src) {
    if (!_sources.remove(src)) return;
    src.removeListener(_sync);
    if (_active == src) _active = null;
    _sync();
  }

  /// The recitation's lock-screen entry (kept for callers and tests).
  NowPlaying? describe() => _describeRecitation();

  NowPlaying? _describeRecitation() {
    final item = recitation.current;
    if (item == null) return null;
    final ar = settings.isArabic;
    final surah = content.quran.surah(item.ref.surah);
    final name = ar ? surah.nameAr : surah.translit;
    final title = item.isBasmala ? name : '$name ${ar ? toArabicIndic(item.ref.ayah) : item.ref.ayah}';
    return NowPlaying(
      id: '${item.ref.surah}:${item.ref.ayah}${item.isBasmala ? ':b' : ''}',
      title: title,
      artist: recitation.reciter.name(ar),
      playing: recitation.isPlaying,
    );
  }

  void _sync() {
    // The player that is playing wins; otherwise the last one in use stays on
    // the controls (paused), so it can be resumed from the lock screen.
    MediaSource? pick;
    NowPlaying? now;
    for (final src in _sources) {
      final d = src.describe();
      if (d != null && d.playing) {
        pick = src;
        now = d;
        break;
      }
    }
    if (pick == null && _active != null) {
      final d = _active!.describe();
      if (d != null) {
        pick = _active;
        now = d;
      }
    }
    if (pick == null) {
      for (final src in _sources) {
        final d = src.describe();
        if (d != null) {
          pick = src;
          now = d;
          break;
        }
      }
    }
    _active = pick;
    if (now == _last && !_jumped(now)) return;
    _last = now;
    _lastAt = clock();
    session.show(now);
  }

  /// True when the position is not where the lock screen's own bar would be by now
  /// (a seek, ±30 s, or the saved position restored after loading).
  bool _jumped(NowPlaying? now) {
    final last = _last;
    if (now == null || last == null || now.duration == null) return false;
    final elapsed = last.playing ? clock().difference(_lastAt) * last.speed : Duration.zero;
    final expected = last.position + elapsed;
    return (now.position - expected).abs() > const Duration(seconds: 2);
  }

  void _onAction(String action) => _active?.act(action);

  void _onSeek(Duration to) {
    final src = _active;
    if (src is _NarrationSource) unawaited(src.narration.seekBy(to - src.narration.position));
  }

  void dispose() {
    for (final src in _sources) {
      src.removeListener(_sync);
    }
  }
}

class _RecitationSource extends ChangeNotifier implements MediaSource {
  _RecitationSource(this.bridge) {
    bridge.recitation.addListener(notifyListeners);
  }
  final RecitationMediaBridge bridge;

  @override
  NowPlaying? describe() => bridge._describeRecitation();

  @override
  void act(String action) {
    final r = bridge.recitation;
    switch (action) {
      case 'play':
        r.resume();
      case 'pause':
        r.pause();
      case 'next':
        r.next();
      case 'previous':
        r.previous();
      case 'stop':
        r.stop();
    }
  }
}

/// Live radio stations, the recitation library, al-Sha'rawi, stories and nasheeds.
class _NarrationSource extends ChangeNotifier implements MediaSource {
  _NarrationSource(this.narration, this.settings) {
    // Every position tick too: the bridge only updates the controls when something changed
    // or the position jumped.
    narration.addListener(notifyListeners);
  }
  final NarrationController narration;
  final SettingsController settings;

  @override
  NowPlaying? describe() {
    final e = narration.episode;
    if (e == null || !narration.isActive) return null;
    final ar = settings.isArabic;
    return NowPlaying(
      id: '${narration.seriesId}/${e.id}',
      title: e.title(ar),
      artist: ar ? 'رتّل وصلِّ' : 'Rattil wa Salli',
      playing: narration.isPlaying,
      canSkip: narration.hasNext || narration.hasPrevious,
      duration: narration.isLive ? null : narration.duration,
      position: narration.position,
    );
  }

  @override
  void act(String action) {
    switch (action) {
      case 'play':
        narration.resume();
      case 'pause':
        narration.pause();
      case 'next':
        narration.next();
      case 'previous':
        narration.previous();
      case 'stop':
        narration.stop();
    }
  }
}

/// What the car screen (Android Auto) lists for the app and what picking an item starts.
abstract class MediaBrowser {
  /// Items under [parentId] (audio_service's root is [AudioService.browsableRootId]).
  List<MediaItem> children(String parentId);

  /// Starts the item with [id] picked on the car screen.
  Future<void> play(String id);
}

/// audio_service implementation of [MediaSession].
class AudioServiceMediaSession extends BaseAudioHandler implements MediaSession {
  void Function(String action)? _onAction;
  void Function(Duration to)? _onSeek;

  /// The app's own list on the Android Auto screen (driving mode for the adhkar).
  MediaBrowser? browser;

  /// Starts the Android media service / iOS remote commands. Call once from main().
  static Future<AudioServiceMediaSession> init({required String channelName}) => AudioService.init(
    builder: AudioServiceMediaSession.new,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'org.rattil.app.recitation',
      androidNotificationChannelName: channelName,
      androidNotificationIcon: 'mipmap/ic_launcher',
      // Paused audio keeps its notification (and the service) so it can be resumed from there.
      androidStopForegroundOnPause: false,
    ),
  );

  @override
  void bind(void Function(String action) onAction, {void Function(Duration to)? onSeek}) {
    _onAction = onAction;
    _onSeek = onSeek;
  }

  @override
  void show(NowPlaying? now) {
    if (now == null) {
      playbackState.add(PlaybackState(processingState: AudioProcessingState.idle, playing: false));
      mediaItem.add(null);
      return;
    }
    final d = now.duration;
    final seekable = d != null && d > Duration.zero;
    mediaItem.add(MediaItem(id: now.id, title: now.title, artist: now.artist, album: 'Rattil wa Salli', duration: d));
    playbackState.add(
      PlaybackState(
        controls: [
          if (now.canSkip) MediaControl.skipToPrevious,
          if (now.playing) MediaControl.pause else MediaControl.play,
          if (now.canSkip) MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: {
          if (now.canSkip) MediaAction.skipToPrevious,
          if (now.canSkip) MediaAction.skipToNext,
          MediaAction.stop,
          if (seekable) MediaAction.seek,
        },
        androidCompactActionIndices: now.canSkip ? const [0, 1, 2] : const [0, 1],
        processingState: AudioProcessingState.ready,
        playing: now.playing,
        updatePosition: now.position,
        speed: now.speed,
      ),
    );
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async =>
      browser?.children(parentMediaId) ?? const [];

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async => browser?.play(mediaId);

  @override
  Future<void> play() async => _onAction?.call('play');
  @override
  Future<void> pause() async => _onAction?.call('pause');
  @override
  Future<void> skipToNext() async => _onAction?.call('next');
  @override
  Future<void> skipToPrevious() async => _onAction?.call('previous');
  @override
  Future<void> seek(Duration position) async => _onSeek?.call(position);
  @override
  Future<void> stop() async {
    _onAction?.call('stop');
    await super.stop();
  }
}
