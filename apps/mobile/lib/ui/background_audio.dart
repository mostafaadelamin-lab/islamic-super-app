import 'package:flutter/foundation.dart';

import '../data/media_session.dart';
import '../data/settings.dart';
import 'dhikr_audio.dart';

/// The dhikr recordings (Hisn al-Muslim, one dhikr at a time) on the lock screen
/// and notification, so they also go on in the background.
class DhikrMediaSource extends ChangeNotifier implements MediaSource {
  DhikrMediaSource(this.player, this.settings) {
    player.addListener(_changed);
  }

  final DhikrPlayer player;
  final SettingsController settings;
  NowPlaying? _last;

  void _changed() {
    final d = describe();
    if (d == _last) return;
    _last = d;
    notifyListeners();
  }

  @override
  NowPlaying? describe() {
    final url = player.url;
    if (url == null || player.failed) return null;
    final ar = settings.isArabic;
    return NowPlaying(
      id: 'dhikr/$url',
      title: ar ? 'ذكر' : 'Dhikr',
      artist: ar ? 'رتّل' : 'Rattil',
      playing: player.playing || player.loading,
      canSkip: false,
    );
  }

  @override
  void act(String action) {
    switch (action) {
      case 'play':
        player.resume();
      case 'pause':
        player.pause();
      case 'stop':
        player.stop();
    }
  }

  @override
  void dispose() {
    player.removeListener(_changed);
    super.dispose();
  }
}

/// A single recording played by a screen of its own (e.g. the morning and
/// evening adhkar): the screen updates [title] / [playing] and handles the buttons.
class SimpleMediaSource extends ChangeNotifier implements MediaSource {
  SimpleMediaSource({required this.id, required this.title, required this.artist, required this.onAction});

  final String id;
  final String title;
  final String artist;
  final void Function(String action) onAction;
  bool _playing = false;
  bool _loaded = true;

  set playing(bool v) {
    if (v == _playing) return;
    _playing = v;
    notifyListeners();
  }

  /// False once the recording is closed.
  set loaded(bool v) {
    if (v == _loaded) return;
    _loaded = v;
    notifyListeners();
  }

  @override
  NowPlaying? describe() =>
      _loaded ? NowPlaying(id: id, title: title, artist: artist, playing: _playing, canSkip: false) : null;

  @override
  void act(String action) => onAction(action);
}
