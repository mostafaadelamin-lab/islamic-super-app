import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/r_icon.dart';

final _all = <String, RIconData>{
  'home': RIcons.home,
  'quran': RIcons.quran,
  'prayer': RIcons.prayer,
  'dua': RIcons.dua,
  'more': RIcons.more,
  'beads': RIcons.beads,
  'compass': RIcons.compass,
  'kaaba': RIcons.kaaba,
  'zakat': RIcons.zakat,
  'hisn': RIcons.hisn,
  'settings': RIcons.settings,
  'help': RIcons.help,
  'location': RIcons.location,
  'moon': RIcons.moon,
  'star': RIcons.star,
  'headphones': RIcons.headphones,
  'reels': RIcons.reels,
  'khatma': RIcons.khatma,
  'share': RIcons.share,
  'chevron': RIcons.chevron,
  'chevronForward': RIcons.chevronForward,
  'play': RIcons.play,
  'bulb': RIcons.bulb,
};

/// Bounds of the drawn outline (Path.getBounds also counts curve control points).
Rect _drawnBounds(Path path) {
  Rect? r;
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d <= m.length; d += 0.1) {
      final p = m.getTangentForOffset(d)!.position;
      r = r == null ? Rect.fromPoints(p, p) : r.expandToInclude(Rect.fromPoints(p, p));
    }
  }
  return r ?? Rect.zero;
}

void main() {
  test('SVG path parser: lines, relative moves, close', () {
    final b = parseSvgPath('M4 4h6v6H4zM14 4h6v6h-6z').getBounds();
    expect(b, const Rect.fromLTRB(4, 4, 20, 10));
  });

  test('SVG path parser: arcs (circle via two half arcs)', () {
    final b = parseSvgPath('M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18Z').getBounds();
    expect(b.left, closeTo(3, 0.01));
    expect(b.right, closeTo(21, 0.01));
    expect(b.top, closeTo(3, 0.01));
    expect(b.bottom, closeTo(21, 0.01));
  });

  test('every shared icon parses and stays inside the 24×24 grid', () {
    for (final e in _all.entries) {
      final b = _drawnBounds(parseSvgPath(e.value.path));
      expect(b.isEmpty, isFalse, reason: e.key);
      expect(b.left >= 0.5 && b.top >= 0.5 && b.right <= 23.5 && b.bottom <= 23.5, isTrue, reason: '${e.key}: $b');
    }
  });

  testWidgets('RIcon takes size and colour from IconTheme, and is decorative', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: IconTheme(
          data: IconThemeData(size: 30, color: Color(0xFF0F5C4A)),
          child: Center(child: RIcon(RIcons.chevronForward)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(RIcon)), const Size(30, 30));
    expect(find.byType(Transform), findsOneWidget, reason: 'directional icons mirror in RTL');
    expect(tester.getSemantics(find.byType(RIcon)).label, isEmpty);
  });
}
