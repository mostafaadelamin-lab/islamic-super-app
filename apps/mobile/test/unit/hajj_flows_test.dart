import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/hajj_flows.dart';

/// Owner, 2026-11-14: steps per Hajj type, with Muzdalifah after Arafah and what comes before
/// the day of Tarwiyah; explanations are the official guide's own words.
void main() {
  final guide = OfficialHajjGuide.fromJson(
    jsonDecode(File('assets/content/dalil-hajj.v1.json').readAsStringSync()) as Map<String, dynamic>,
  );

  test('bundled guide is the same file as content/pilgrimage', () {
    expect(
      File('assets/content/dalil-hajj.v1.json').readAsStringSync(),
      File('../../content/pilgrimage/dalil-hajj.v1.json').readAsStringSync(),
    );
  });

  test('every step has an explanation', () {
    for (final e in hajjFlows.entries) {
      for (final s in e.value) {
        if (s.ref == 'types' || s.ref == 'farewell') continue;
        expect(guide.paragraph(s.ref), isNotNull, reason: '${e.key}: ${s.title}');
      }
    }
  });

  test('Mina, Arafah, Muzdalifah, then Jamrat al-Aqaba in every type; ends with the farewell tawaf', () {
    for (final steps in hajjFlows.values) {
      final t = [for (final s in steps) s.title];
      final mina = t.indexOf('منى يوم التروية');
      expect(mina, greaterThan(0));
      expect(t.sublist(mina, mina + 4), ['منى يوم التروية', 'الوقوف بعرفة', 'المبيت بمزدلفة', 'رمي جمرة العقبة']);
      expect(t.last, 'طواف الوداع');
    }
    expect(guide.paragraph('h4'), contains('مزدلفة'));
  });

  test("tamattu' starts with a full Umrah; only tamattu' and qiran have the hady", () {
    expect([for (final s in hajjFlows[HajjType.tamattu]!.take(4)) s.ref], ['u1', 'u2', 'u3', 'u4']);
    bool hady(HajjType t) => hajjFlows[t]!.any((s) => s.title == 'ذبح الهدي');
    expect([hady(HajjType.tamattu), hady(HajjType.qiran), hady(HajjType.ifrad)], [true, true, false]);
  });

  test('same lists as the website', () {
    final web = File('../web/src/lib/hajj-flows.ts').readAsStringSync();
    for (final steps in hajjFlows.values) {
      for (final s in steps) {
        expect(web, contains('"${s.title}"'));
      }
    }
  });
}
