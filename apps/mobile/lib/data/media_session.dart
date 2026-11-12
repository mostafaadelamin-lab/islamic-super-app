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
  });
  final String id;
  final String title;
  final String artist;
  final bool playing;

  /// Show the previous / next buttons (off for live radio and single recordings).
  final bool canSkip;

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.playing == playing &&
      other.canSkip == canSkip;

  @override
  int get hashCode => Object.hash(id, title, artist, playing, canSkip);
}

/// The system media controls (lock screen, notification, headset buttons).
abstract class MediaSession {
  /// [onAction] receives 'play', 'pause', 'next', 'previous' and 'stop'.
  void bind(void Function(String action) onAction);
  void show(NowPlaying? now);
}

/// No system controls (tests, platforms without audio_service).
class NoMediaSession implements MediaSession {
  const NoMediaSession();
  @override
  void bind(void Function(String action) onAction) {}
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
    session.bind(_onAction);
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
    if (now == _last) return;
    _last = now;
    session.show(now);
  }

  void _onAction(String action) => _active?.act(action);

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
    narration.addListener(_changed);
  }
  final NarrationController narration;
  final SettingsController settings;
  NowPlaying? _last;

  // The narrator notifies on every position tick; the controls only change with these.
  void _changed() {
    final d = describe();
    if (d == _last) return;
    _last = d;
    notifyListeners();
  }

  @override
  NowPlaying? describe() {
    final e = narration.episode;
    if (e == null || !narration.isActive) return null;
    final ar = settings.isArabic;
    return NowPlaying(
      id: '${narration.seriesId}/${e.id}',
      title: e.title(ar),
      artist: ar ? 'رتّل' : 'Rattil',
      playing: narration.isPlaying,
      canSkip: narration.hasNext || narration.hasPrevious,
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

/// audio_service implementation of [MediaSession].
class AudioServiceMediaSession extends BaseAudioHandler implements MediaSession {
  void Function(String action)? _onAction;

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
  void bind(void Function(String action) onAction) => _onAction = onAction;

  @override
  void show(NowPlaying? now) {
    if (now == null) {
      playbackState.add(PlaybackState(processingState: AudioProcessingState.idle, playing: false));
      mediaItem.add(null);
      return;
    }
    mediaItem.add(MediaItem(id: now.id, title: now.title, artist: now.artist, album: 'Rattil'));
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
        },
        androidCompactActionIndices: now.canSkip ? const [0, 1, 2] : const [0, 1],
        processingState: AudioProcessingState.ready,
        playing: now.playing,
      ),
    );
  }

  @override
  Future<void> play() async => _onAction?.call('play');
  @override
  Future<void> pause() async => _onAction?.call('pause');
  @override
  Future<void> skipToNext() async => _onAction?.call('next');
  @override
  Future<void> skipToPrevious() async => _onAction?.call('previous');
  @override
  Future<void> stop() async {
    _onAction?.call('stop');
    await super.stop();
  }
}
