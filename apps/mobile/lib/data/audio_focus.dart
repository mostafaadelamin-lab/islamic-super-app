import 'package:flutter/foundation.dart';

/// One sound at a time (owner 2026-11-14): when a player of the app starts (the
/// Quran recitation, adhkar, nasheeds, lessons, radios), every other one pauses.
/// Each keeps its own position, so the recitation resumes from its ayah.
class AudioFocus {
  AudioFocus._();

  static final Map<Object, VoidCallback> _pausers = {};

  /// [owner] pauses itself with [pause] when another player claims the sound.
  static void register(Object owner, VoidCallback pause) => _pausers[owner] = pause;

  static void unregister(Object owner) => _pausers.remove(owner);

  /// [owner] starts playing: pause everyone else.
  static void claim(Object owner) {
    for (final e in _pausers.entries.toList()) {
      if (!identical(e.key, owner)) e.value();
    }
  }

  @visibleForTesting
  static void reset() => _pausers.clear();
}
