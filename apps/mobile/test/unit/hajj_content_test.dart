import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';

import '../helpers.dart';

/// assets/content/hajj.v1.json is extracted mechanically from the prototype
/// (tool/extract_hajj.mjs). Every string must appear verbatim in the source.
void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  test('three sections with the prototype\'s cards; review status recorded', () {
    final g = c.hajj;
    expect(g.sections.keys, ['umrah', 'hajj', 'ihram']);
    expect(g.sections['umrah']!.where((b) => b.label?.startsWith('الخطوة') ?? false), hasLength(4));
    expect(g.sections['hajj']!.where((b) => b.label?.startsWith('المرحلة') ?? false), hasLength(5));
    expect(g.reviewStatus, contains('pending religious review'));
  });

  test('every string is verbatim from content/pilgrimage/source-hajj.js', () {
    final src = File('$repoRoot/content/pilgrimage/source-hajj.js').readAsStringSync();
    final generatedLabel = RegExp(r'^(الخطوة|المرحلة) [٠-٩]+$');
    var n = 0;
    expect(src.contains(c.hajj.talbiya), isTrue);
    for (final blocks in c.hajj.sections.values) {
      for (final b in blocks) {
        for (final s in b.strings) {
          n++;
          if (generatedLabel.hasMatch(s)) {
            expect(src.contains('"${s.split(' ').first} "+ar(i+1)'), isTrue, reason: s);
          } else {
            expect(src.contains(s), isTrue, reason: s);
          }
        }
      }
    }
    expect(n, greaterThan(60));
  });
}
