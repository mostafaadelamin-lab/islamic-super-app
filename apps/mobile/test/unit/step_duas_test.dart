import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/step_duas.dart';

/// Owner 2026-11-15: every dua and ayah written in full at the place it is said, and never a letter
/// changed: the texts are Hisn al-Muslim chapters (whole, or an exact part) and Quran ayah references.
void main() {
  final raw = jsonDecode(File('assets/content/hisn.json').readAsStringSync()) as List<dynamic>;
  final hisn = [
    for (var i = 0; i < raw.length; i++)
      HisnChapter(
        i,
        (raw[i] as List<dynamic>)[0] as String,
        ((raw[i] as List<dynamic>)[1] as List<dynamic>).cast<String>(),
      ),
  ];
  final json = jsonDecode(File('assets/content/step-duas.v1.json').readAsStringSync()) as Map<String, dynamic>;
  final duas = StepDuas.fromJson(json, hisn);

  test('the bundled copy is the shared content file, byte for byte', () {
    expect(
      File('assets/content/step-duas.v1.json').readAsStringSync(),
      File('../../content/pilgrimage/step-duas.v1.json').readAsStringSync(),
    );
  });

  test('each place shows its Hisn chapter whole, and every other text is an exact part of it', () {
    for (final title in ['طواف العمرة', 'سعي العمرة', 'الوقوف بعرفة', 'المبيت بمزدلفة', 'رمي الجمرات الثلاث']) {
      final groups = duas.forStep(title);
      expect(groups, isNotEmpty, reason: title);
      for (final g in groups) {
        final c = hisn.firstWhere((x) => x.title == g.title);
        final full = c.items.join('\n');
        expect(g.say.any((x) => x.text == full), isTrue, reason: g.title);
        for (final x in g.say) {
          if (x.text != null) expect(full.contains(x.text!), isTrue, reason: x.text);
        }
      }
    }
  });

  test('Yemeni Corner: the Hisn dua and Al-Baqarah 201; Safa: Al-Baqarah 158', () {
    final tawaf = duas.forStep('الطواف حول الكعبة').expand((g) => g.say).toList();
    expect(tawaf.map((x) => x.ayah), contains(const AyahRef(2, 201)));
    expect(tawaf.any((x) => x.text?.contains('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً') ?? false), isTrue);
    final sai = duas.forStep('السعي بين الصفا والمروة').expand((g) => g.say).toList();
    expect(sai.map((x) => x.ayah), contains(const AyahRef(2, 158)));
    expect(duas.placesFor('البقاء على الإحرام'), isEmpty);
  });

  test('a part that is not in its chapter is refused', () {
    final bad = {
      'places': {
        'x': [
          {
            'hisn': 117,
            'say': [
              {'hisn': 117, 'part': 'نص ليس في الكتاب', 'kind': 'dua'},
            ],
          },
        ],
      },
      'rules': <dynamic>[],
    };
    expect(() => StepDuas.fromJson(bad, hisn), throwsFormatException);
  });
}
