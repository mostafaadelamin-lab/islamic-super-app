import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/parent_lock.dart';

import '../helpers.dart';

Future<void> _type(WidgetTester tester, String v) async {
  await tester.enterText(find.byKey(const Key('parentGate.pin')), v);
  await tester.tap(find.byKey(const Key('parentGate.submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadContent);

  test('PIN rules and hash', () {
    expect(isValidPin('1234'), isTrue);
    expect(isValidPin('123'), isFalse);
    expect(isValidPin('12a4'), isFalse);
    expect(pinMatches('1234', hashPin('1234')), isTrue);
    expect(pinMatches('1235', hashPin('1234')), isFalse);
    expect(pinMatches('1234', null), isFalse);
    expect(hashPin('1234'), isNot(contains('1234')));
    final (a, b) = parentChallenge(Random(1));
    expect(a, inInclusiveRange(6, 9));
    expect(b, inInclusiveRange(12, 19));
  });

  testWidgets('videos tab: parent sets a PIN, then it opens the videos; wrong PIN stays locked', (tester) async {
    final app = await pumpApp(tester, locale: 'en', videosUnlocked: false);
    await tester.tap(find.text('Videos').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('parentGate')), findsOneWidget);
    expect(find.byKey(const Key('reels.search')), findsNothing);
    expect(find.text('Parent: choose a 4-digit PIN'), findsOneWidget);

    await _type(tester, '2468');
    expect(find.text('Type the PIN again to confirm'), findsOneWidget);
    await _type(tester, '1111');
    expect(find.text("The two PINs don't match, start again"), findsOneWidget);
    await _type(tester, '2468');
    await _type(tester, '2468');
    expect(find.byKey(const Key('parentGate')), findsNothing);
    expect(app.services.settings.parentPinHash, hashPin('2468'));

    // Going to the background locks again.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Type the PIN to open videos'), findsOneWidget);
    await _type(tester, '0000');
    expect(find.text('Wrong PIN, try again'), findsOneWidget);
    expect(find.byKey(const Key('parentGate')), findsOneWidget);
    await _type(tester, '2468');
    expect(find.byKey(const Key('parentGate')), findsNothing);
  });

  testWidgets('forgot the PIN: the multiplication question leads to a new PIN', (tester) async {
    final app = await pumpApp(tester, locale: 'en', videosUnlocked: false, prefs: {'parentLock.pin': hashPin('1357')});
    await tester.tap(find.text('Videos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('parentGate.forgot')));
    await tester.pumpAndSettle();
    final prompt = tester.widget<Text>(find.byKey(const Key('parentGate.prompt'))).data!;
    final m = RegExp(r'(\d+) × (\d+)').firstMatch(prompt)!;
    await _type(tester, '1');
    expect(find.text('Wrong answer'), findsOneWidget);
    final prompt2 = tester.widget<Text>(find.byKey(const Key('parentGate.prompt'))).data!;
    final m2 = RegExp(r'(\d+) × (\d+)').firstMatch(prompt2)!;
    expect(m.groupCount, 2);
    await _type(tester, '${int.parse(m2[1]!) * int.parse(m2[2]!)}');
    expect(find.text('Parent: choose a 4-digit PIN'), findsOneWidget);
    await _type(tester, '9753');
    await _type(tester, '9753');
    expect(find.byKey(const Key('parentGate')), findsNothing);
    expect(app.services.settings.parentPinHash, hashPin('9753'));
  });
}
