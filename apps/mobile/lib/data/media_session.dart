import 'package:audio_service/audio_service.dart';

import '../domain/text.dart';
import 'content.dart';
import 'recitation.dart';
import 'settings.dart';

/// What the lock screen / notification shows for the recitation.
class NowPlaying {
  const NowPlaying({required this.id, required this.title, required this.artist, required this.playing});
  final String id;
  final String title;
  final String artist;
  final bool playing;

  @override
  bool operator ==(Object other) =>
      other is NowPlaying &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.playing == playing;

  @override
  int get hashCode => Object.hash(id, title, artist, playing);
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

/// Keeps the system media controls in step with the recitation player and
/// sends their buttons back to it. With audio_service this also runs the
/// Android media foreground service, so recitation goes on with the screen off.
class RecitationMediaBridge {
  RecitationMediaBridge({
    required this.recitation,
    required this.content,
    required this.settings,
    required this.session,
  }) {
    session.bind(_onAction);
    recitation.addListener(_sync);
  }

  final RecitationController recitation;
  final AppContent content;
  final SettingsController settings;
  final MediaSession session;
  NowPlaying? _last;

  /// What is shown now (null when the player is idle).
  NowPlaying? get nowPlaying => _last;

  NowPlaying? describe() {
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
    final now = describe();
    if (now == _last) return;
    _last = now;
    session.show(now);
  }

  void _onAction(String action) {
    switch (action) {
      case 'play':
        recitation.resume();
      case 'pause':
        recitation.pause();
      case 'next':
        recitation.next();
      case 'previous':
        recitation.previous();
      case 'stop':
        recitation.stop();
    }
  }

  void dispose() => recitation.removeListener(_sync);
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
      androidStopForegroundOnPause: true,
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
          MediaControl.skipToPrevious,
          if (now.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.skipToPrevious, MediaAction.skipToNext, MediaAction.stop},
        androidCompactActionIndices: const [0, 1, 2],
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
