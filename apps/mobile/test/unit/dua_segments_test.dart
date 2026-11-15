import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/dua_segments.dart';

List<String> duas(String s) => [
  for (final p in duaParts(s))
    if (p.dua) p.text,
];

void main() {
  test('dua shading never changes the text and finds the duas (owner 2026-11-15)', () {
    final j = jsonDecode(File('assets/content/hajj.v1.json').readAsStringSync()) as Map<String, dynamic>;
    final all = <String>[];
    void walk(Object? x) {
      if (x is String) all.add(x);
      if (x is List) x.forEach(walk);
      if (x is Map) x.values.forEach(walk);
    }

    walk(j);
    for (final s in all) {
      expect(duaParts(s).map((p) => p.text).join(), s);
    }
    expect(duas('وقل: «بسم الله، والله أكبر».'), ['«بسم الله، والله أكبر»']);
    expect(duas('تقرأ فيهما «الكافرون» و«الإخلاص»'), isEmpty);
    expect(duas('يُسنّ للرجل الاضطباع (كشف الكتف الأيمن)'), isEmpty);
    expect(duas('قل: (لا إله إلا الله) . (الله أكبر) ثلاثًا'), ['(لا إله إلا الله)', '(الله أكبر)']);
    expect(duas('﴿رَبَّنَا آتِنَا﴾ [البقرة: ٢٠١] ثم'), ['﴿رَبَّنَا آتِنَا﴾ [البقرة: ٢٠١]']);
    expect(duas('لبيك عمرة: [لبيك اللهم لبيك] .'), ['[لبيك اللهم لبيك]']);
  });
}
