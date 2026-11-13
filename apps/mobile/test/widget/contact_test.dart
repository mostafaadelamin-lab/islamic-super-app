import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/contact_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  testWidgets('contact form: title is required, then title, name, phone, WhatsApp and message are sent', (
    tester,
  ) async {
    final sent = <Map<String, String>>[];
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(
      tester,
      ContactScreen(
        sender: (uri, fields) async {
          sent.add(Map<String, String>.from(fields));
          return true;
        },
      ),
    );
    await tester.enterText(find.byKey(const Key('contactMessage')), 'The adhan did not play');
    await tester.tap(find.byKey(const Key('contactSend')));
    await tester.pumpAndSettle();
    expect(find.text('Please write a title'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.enterText(find.byKey(const Key('contactTitle')), 'Adhan problem');
    await tester.enterText(find.byKey(const Key('contactName')), 'Ahmed');
    await tester.enterText(find.byKey(const Key('contactPhone')), '0100');
    await tester.enterText(find.byKey(const Key('contactWhatsapp')), '0111');
    await tester.tap(find.byKey(const Key('contactSend')));
    await tester.pumpAndSettle();
    expect(sent.single['title'], 'Adhan problem');
    expect(sent.single['name'], 'Ahmed');
    expect(sent.single['phone'], '0100');
    expect(sent.single['whatsapp'], '0111');
    expect(sent.single['message'], 'The adhan did not play');
    expect(find.byKey(const Key('contactSent')), findsOneWidget);
  });
}
