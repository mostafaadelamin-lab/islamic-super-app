import 'dart:async';

import 'package:rattil/ui/page_reader_screen.dart';

/// Most reader tests drive the tabs, player and bars, so the reader opens with
/// its controls; the full-screen start has its own tests (mushaf_fullscreen_test.dart).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PageReaderScreen.startFullScreen = false;
  await testMain();
}
