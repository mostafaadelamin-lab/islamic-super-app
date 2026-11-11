import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads Arabic text aloud with the device's own text-to-speech voice
/// (used for the Names of Allah, which have no published recordings).
abstract class Speaker {
  Future<bool> speak(String text);
  Future<void> stop();
  void onDone(VoidCallback cb);
}

class DeviceSpeaker implements Speaker {
  DeviceSpeaker() {
    _tts.setCompletionHandler(() => _done?.call());
    _tts.setCancelHandler(() => _done?.call());
    _tts.setErrorHandler((_) => _done?.call());
  }

  final _tts = FlutterTts();
  VoidCallback? _done;
  bool _ready = false;

  @override
  void onDone(VoidCallback cb) => _done = cb;

  @override
  Future<bool> speak(String text) async {
    try {
      if (!_ready) {
        final ok = await _tts.isLanguageAvailable('ar');
        if (ok == false) return false;
        await _tts.setLanguage('ar');
        await _tts.setSpeechRate(kIsWeb ? 0.8 : 0.42);
        _ready = true;
      }
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
