import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/home_shell.dart';

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

  testWidgets('back returns to the tab opened before, not straight to Home', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final bar = find.byKey(const Key('navBar'));
    HomeShellState shell() => tester.state<HomeShellState>(find.byType(HomeShell));
    for (final label in ['القرآن', 'الصلاة', 'الأذكار']) {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
    }
    expect(shell().index, 3);
    // The arrow: Adhkar → Prayer.
    await tester.tap(find.byKey(const Key('shellBack')));
    await tester.pumpAndSettle();
    expect(shell().index, 2);
    // The phone's back button: Prayer → Quran → Home, and only then does the app close.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell().index, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell().index, 0);
    expect(find.byKey(const Key('shellBack')), findsNothing);
  });

  testWidgets('a tab opened again moves to the top of the way back; Home starts over', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final bar = find.byKey(const Key('navBar'));
    HomeShellState shell() => tester.state<HomeShellState>(find.byType(HomeShell));
    Future<void> open(String label) async {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    await open('القرآن');
    await open('الصلاة');
    await open('القرآن'); // way back: Home, Prayer
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell().index, 2);
    await open('الرئيسية');
    await open('المزيد');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(shell().index, 0);
  });
}
