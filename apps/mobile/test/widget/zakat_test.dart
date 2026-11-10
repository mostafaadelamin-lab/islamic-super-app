import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/zakat.dart';
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

  for (final locale in ['ar', 'en']) {
    testWidgets('zakat screen works out the zakat and keeps the numbers ($locale)', (tester) async {
      final app = await pumpApp(tester, locale: locale, size: tallPhone);
      await pushScreen(tester, const ZakatScreen());
      expect(find.byKey(const Key('zakatReview')), findsOneWidget);
      expect(find.byKey(const Key('zakatResult-needPrice')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('zakatPrice')), locale == 'ar' ? '٤٠٠٠' : '4000');
      await tester.enterText(find.byKey(const Key('zakat-cash')), '400000');
      await tester.pump();
      expect(find.byKey(const Key('zakatResult-yearNotPassed')), findsOneWidget);
      await tester.tap(find.byKey(const Key('zakatYear')));
      await tester.pump();
      expect(find.text(locale == 'ar' ? 'الزكاة الواجبة: ١٠,٠٠٠' : 'Zakat due: 10,000'), findsOneWidget);
      expect(app.services.settings.zakatValues, {'cash': 400000.0});
      expect(app.services.settings.zakatGoldPrice, 4000);
      expect(app.services.settings.zakatYearPassed, isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('zakatAdornment')),
        300,
        scrollable: find.descendant(of: find.byKey(const Key('zakatList')), matching: find.byType(Scrollable)).first,
      );
      expect(
        find.textContaining('لا زكاة على المرأة في الذهب الذي تملكه بقصد استعماله في التزيُّنِ به والتحلي'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('zakat is reachable from More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 4);
    await tester.tap(find.byKey(const Key('more.zakat')));
    await tester.pumpAndSettle();
    expect(find.byType(ZakatScreen), findsOneWidget);
  });
}
