import 'package:flutter/material.dart';

/// Where the audio playing now was started, so the players at the bottom of the
/// app can take the user back there (owner 2026-11-15: after leaving the
/// recitation library there was no direct way back to what was playing).
class PlayOrigin {
  PlayOrigin._();

  static String? _series;
  static Route<dynamic>? _route;
  static WidgetBuilder? _builder;

  static Route<dynamic>? _readerRoute;

  /// Remembers the screen of [context] as the place of the narration [series]
  /// (recitation library, radio, nasheeds, al-Sha'rawi, stories…). The app's
  /// first screen (the tabs) is not remembered: the player is already there.
  static void remember(BuildContext context, String series) {
    final r = ModalRoute.of(context);
    _series = series;
    if (r == null || r.isFirst) {
      _route = null;
      _builder = null;
      return;
    }
    _route = r;
    _builder = r is MaterialPageRoute ? r.builder : null;
  }

  /// True when the narration of [series] can be reopened from [context]'s screen
  /// (not when that screen is the one it was started from).
  static bool canReturn(BuildContext context, String? series) {
    if (series == null || series != _series || _route == null) return false;
    if (ModalRoute.of(context) == _route) return false;
    return _route!.isActive || _builder != null;
  }

  /// Goes back to the screen the narration was started from: back down the stack
  /// when it is still open, or opens it again.
  static void open(BuildContext context) {
    final r = _route;
    if (r == null) return;
    if (r.isActive) {
      r.navigator?.popUntil((x) => x == r);
      return;
    }
    final b = _builder;
    if (b == null) return;
    final again = MaterialPageRoute<void>(builder: b);
    _route = again;
    Navigator.of(context).push(again);
  }

  /// The Quran reader registers its screen while it is open.
  static void readerOpened(BuildContext context) => _readerRoute = ModalRoute.of(context);

  /// Back to the open Quran reader; false when none is open.
  static bool backToReader(BuildContext context) {
    final r = _readerRoute;
    if (r == null || !r.isActive) return false;
    if (ModalRoute.of(context) != r) r.navigator?.popUntil((x) => x == r);
    return true;
  }

  /// Test hook.
  static void reset() {
    _series = null;
    _route = null;
    _builder = null;
    _readerRoute = null;
  }
}
