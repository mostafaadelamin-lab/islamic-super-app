#!/bin/sh
# Builds the headless copy of the integration test: storage mocked, a silent audio backend
# (flutter-tester has no platform plugins). Run from apps/mobile.
sed -e 's/^    final prefs = await SharedPreferences.getInstance();$/    SharedPreferences.setMockInitialValues({});\n&/' \
    -e 's/await app.bootstrap();/await app.bootstrap(audioBackend: _SilentAudio.new);/' \
    -e "s#^import 'package:rattil/app.dart';#import 'dart:async';\n\nimport 'package:rattil/app.dart';\nimport 'package:rattil/data/recitation.dart';#" \
    integration_test/app_test.dart > test/zz_e2e_headless_copy_test.dart
cat >> test/zz_e2e_headless_copy_test.dart <<'X'

/// Accepts every file and never finishes it (no audio plugin on flutter-tester).
class _SilentAudio implements AudioBackend {
  final _done = StreamController<void>.broadcast();
  @override
  Future<void> load(String url) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Stream<void> get completed => _done.stream;
  @override
  Future<void> dispose() => _done.close();
}
X
