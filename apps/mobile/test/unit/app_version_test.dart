import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/about_screen.dart';

void main() {
  test('the About page shows the version in pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(AboutScreen.appVersion, line.split(':')[1].trim().split('+').first);
  });
}
