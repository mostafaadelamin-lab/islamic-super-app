import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/about_screen.dart';
import 'package:rattil/ui/in_app_doc_screen.dart';

import '../helpers.dart';

/// Owner 2026-11-27: «المصادر والإثبات» and the privacy policy open inside the app, from bundled copies.
void main() {
  setUpAll(loadContent);

  test('links: anchors stay, «رجوع للتطبيق» closes, others open outside', () {
    expect(docLinkAction(Uri.parse('https://rattilwasalli.com/#hadith-check')), DocLink.stay);
    expect(docLinkAction(Uri.parse('about:blank')), DocLink.stay);
    expect(docLinkAction(Uri.parse('https://rattilwasalli.com/ar/')), DocLink.back);
    expect(docLinkAction(Uri.parse('https://sunnah.com/bukhari')), DocLink.external);
    expect(docLinkAction(Uri.parse('https://rattilwasalli.com/fonts/OFL.txt')), DocLink.external);
  });

  test('the bundled pages carry the proof and the new sources', () {
    final sources = File(InAppDocScreen.sourcesAsset).readAsStringSync();
    expect(sources, contains('id="proof"'));
    expect(sources, contains('8b1625a83df9a17896490e474e521efaa0e9e1560de73a5044e4b2db38c84e0b'));
    final privacy = File(InAppDocScreen.privacyAsset).readAsStringSync();
    expect(privacy, contains('static.qurancdn.com'));
    expect(privacy, contains('sunnah.com'));
  });

  testWidgets('«المصادر والإثبات» opens inside the app', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await pushScreen(tester, const AboutScreen());
    await tester.tap(find.byKey(const Key('aboutProof')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppDoc')), findsOneWidget);
    expect(find.text('المصادر والإثبات'), findsWidgets);
  });
}
