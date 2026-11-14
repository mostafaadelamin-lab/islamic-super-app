import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/shortcuts.dart';
import 'package:rattil/domain/app_links.dart';
import 'package:rattil/ui/help_screen.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/tasbih_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  test('share suggestion: on the fifth distinct day, never again once answered', () {
    var days = <String>[];
    final shows = <bool>[];
    for (var d = 1; d <= sharePromptAfterDays; d++) {
      final r = sharePromptVisit(days, false, '2026-11-0$d');
      days = r.days;
      shows.add(r.show);
    }
    expect(shows, [false, false, false, false, true]);
    expect(sharePromptVisit(['2026-11-01'], false, '2026-11-01').days, ['2026-11-01']);
    expect(sharePromptVisit(days, true, '2026-11-09').show, isFalse);
    expect(AppLinks.fromJson({'contactEmail': ' ', 'website': 'https://x.test'}).contactEmail, isNull);
  });

  test('rate link: App Store on iPhone/iPad, Google Play on Android, never the other store', () {
    const links = AppLinks(playStore: 'https://play.test', appStore: null);
    expect(links.storeFor(TargetPlatform.android), 'https://play.test');
    expect(links.storeFor(TargetPlatform.iOS), isNull);
    expect(const AppLinks(appStore: 'https://apps.test').storeFor(TargetPlatform.iOS), 'https://apps.test');
  });

  testWidgets('Help: FAQ opens, contact form, share and rate the app', (tester) async {
    final sharer = FakeSharer();
    await pumpApp(tester, size: tallPhone, sharer: sharer, locale: 'en');
    await pushScreen(tester, const HelpScreen());
    await tester.tap(find.text('Is Rattil wa Salli really free?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no ads, no subscriptions'), findsOneWidget);
    expect(find.byKey(const Key('helpContactForm')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('helpShareApp')), 200);
    await tester.tap(find.byKey(const Key('helpShareApp')));
    await tester.pump();
    expect(sharer.texts.single, startsWith('Rattil wa Salli: Quran, prayer times and adhkar, free with no ads.'));
    expect(find.byKey(const Key('helpRate')), findsOneWidget);
  });

  testWidgets('no share suggestion on the first day of use', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    expect(find.byKey(const Key('sharePrompt')), findsNothing);
    expect(app.services.settings.sharePromptDays, hasLength(1));
  });

  testWidgets('the share suggestion appears on the fifth day of use and only once', (tester) async {
    final sharer = FakeSharer();
    final app = await pumpApp(
      tester,
      size: tallPhone,
      sharer: sharer,
      locale: 'en',
      prefs: {
        'sharePrompt.days': ['2000-01-01', '2000-01-02', '2000-01-03', '2000-01-04'],
      },
    );
    expect(find.byKey(const Key('sharePrompt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sharePromptShare')));
    await tester.pumpAndSettle();
    expect(sharer.texts, hasLength(1));
    expect(app.services.settings.sharePromptDone, isTrue);
  });

  testWidgets('home-screen shortcuts open their section', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final shell = tester.state<HomeShellState>(find.byType(HomeShell));
    shortcutRequests.value = 'prayer';
    await tester.pumpAndSettle();
    expect(shell.index, 2);
    shortcutRequests.value = 'tasbih';
    await tester.pumpAndSettle();
    expect(find.byType(TasbihScreen), findsOneWidget);
  });
}
