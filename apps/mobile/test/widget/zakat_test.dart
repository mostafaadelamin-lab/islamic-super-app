import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/zakat.dart';
import 'package:rattil/domain/zakat_simple.dart';
import 'package:rattil/ui/zakat_screen.dart';

import '../helpers.dart';

void main() {
  late ZakatGuide guide;
  setUpAll(() async => guide = (await loadContent()).zakat);

  group('ZakatGuide (Dar al-Ifta al-Misriyya)', () {
    test('loads the published rules, pending review, and every field cites a fatwa', () {
      expect(guide.nisabGoldGrams, 85);
      expect(guide.nisabKarat, 21);
      expect(guide.rate, 0.025);
      expect(guide.reviewStatus, 'pending');
      for (final f in guide.fields) {
        for (final id in f.sources) {
          expect(guide.source(id), isNotNull, reason: f.id);
        }
      }
      expect(readAppJson('assets/content/zakat.v1.json'), readRepoJson('content/zakat/dar-alifta.v1.json'));
    });

    test('2.5% once the nisab is reached and a year has passed', () {
      const price = 4000.0;
      final r = guide.compute({'cash': 400000}, price, true);
      expect(r.status, ZakatStatus.due);
      expect(r.nisab, 85 * price);
      expect(r.zakat, 10000);
      expect(guide.compute({'cash': 85 * price - 1}, price, true).status, ZakatStatus.belowNisab);
      expect(guide.compute({'cash': 85 * price}, price, false).status, ZakatStatus.yearNotPassed);
      expect(guide.compute({'cash': 1e9}, 0, true).status, ZakatStatus.needPrice);
    });

    test('debts are subtracted and gold of other karats is priced by purity', () {
      expect(guide.compute({'cash': 500000, 'debts': 100000}, 4000, true).zakat, 10000);
      expect(guide.compute({'gold24': 21}, 1, false).net, 24);
      expect(guide.compute({'gold18': 21}, 1, false).net, 18);
      expect(guide.compute({'cash': -5}, 1, false).net, 0);
    });
  });

  group('simple zakat rules', () {
    test('gold: 85 g of 24 carat, 21 carat priced by purity, 2.5%', () {
      expect(goldZakat(80, 24, 4000).reached, isFalse);
      final r = goldZakat(100, 21, 4000);
      expect(r.reached, isTrue);
      expect(r.dueGrams, 2.5);
      expect(r.dueMoney, closeTo(100 * 21 / 24 * 0.025 * 4000, 1e-6));
      expect(goldZakat(90, 18, null).reached, isFalse);
    });
    test('silver, money, crops', () {
      expect(silverZakat(594, 50).reached, isFalse);
      expect(silverZakat(600, 50).dueMoney, 600 * 0.025 * 50);
      expect(moneyZakat(400000, 85 * 4000).due, 10000);
      expect(moneyZakat(100, 85 * 4000).reached, isFalse);
      expect(cropsZakat(1000, rainFed: true).dueKg, 100);
      expect(cropsZakat(1000, rainFed: false).dueKg, 50);
      expect(cropsZakat(600, rainFed: true).reached, isFalse);
    });
    test('livestock tables', () {
      expect(livestockZakat(Livestock.sheep, 39), isEmpty);
      expect(livestockZakat(Livestock.sheep, 121), [(2, 'sheep')]);
      expect(livestockZakat(Livestock.camels, 10), [(2, 'sheep')]);
      expect(livestockZakat(Livestock.camels, 30), [(1, 'bintMakhad')]);
      expect(livestockZakat(Livestock.camels, 130), [(2, 'bintLabun'), (1, 'hiqqa')]);
      expect(livestockZakat(Livestock.cattle, 30), [(1, 'tabi')]);
      expect(livestockZakat(Livestock.cattle, 70), [(1, 'tabi'), (1, 'musinna')]);
    });
  });

  testWidgets('zakat screen: five tabs; gold result and the value is kept', (tester) async {
    await pumpApp(tester, locale: 'en', size: tallPhone);
    await pushScreen(tester, const ZakatScreen());
    for (final t in ['Silver', 'Gold', 'Money', 'Livestock', 'Crops']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Gold'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('zakat.gold')), '100');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zakatResult')), findsOneWidget);
    expect(find.textContaining('Zakat due: 2.5 g of 21-carat gold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zakat is reachable from More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 5);
    await tester.tap(find.byKey(const Key('more.zakat')));
    await tester.pumpAndSettle();
    expect(find.byType(ZakatScreen), findsOneWidget);
  });
}
