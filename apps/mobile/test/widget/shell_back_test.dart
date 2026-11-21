import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Owner 2026-11-21: every page needs a back button. The main tabs open from Home without a new
/// page, so each one shows a back arrow that returns to Home; the phone's back button does the same.
void main() {
  setUpAll(loadContent);

  testWidgets('each main tab has a back arrow to Home; Home has none', (tester) async {
    await pumpApp(tester, size: tallPhone);
    expect(find.byKey(const Key('shellBack')), findsNothing);
    final bar = find.byKey(const Key('navBar'));
    for (final label in ['القرآن', 'الصلاة', 'الأذكار', 'المزيد']) {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shellBack')), findsOneWidget, reason: label);
      await tester.tap(find.byKey(const Key('shellBack')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shellBack')), findsNothing, reason: label);
    }
  });

  testWidgets("the phone's back button on a tab returns to Home", (tester) async {
    await pumpApp(tester, size: tallPhone);
    final bar = find.byKey(const Key('navBar'));
    await tester.tap(find.descendant(of: bar, matching: find.text('المزيد')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shellBack')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shellBack')), findsNothing);
    expect(find.byKey(const Key('navBar')), findsOneWidget);
  });
}
