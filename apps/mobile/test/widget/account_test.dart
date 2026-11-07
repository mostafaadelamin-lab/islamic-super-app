import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/domain/quran.dart';

import '../fake_server.dart';
import '../helpers.dart';

void main() {
  setUpAll(() async {
    registerHttpFallbacks();
    await loadContent();
  });

  late FakeApiServer server;
  late MockHttpClient client;

  setUp(() {
    server = FakeApiServer();
    client = MockHttpClient();
    when(
      () => client.send(any()),
    ).thenAnswer((inv) => server.handle(inv.positionalArguments.first as http.BaseRequest));
  });

  Future<TestApp> open(WidgetTester tester, {String locale = 'en', Map<String, Object> prefs = const {}}) async {
    final app = await pumpApp(tester, locale: locale, prefs: prefs, httpClient: client, size: tallPhone);
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('accountTile')));
    await tester.pumpAndSettle();
    return app;
  }

  String message(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('accountMessage'))).data!;

  testWidgets('shows default server address and the optional-account note', (tester) async {
    await open(tester);
    expect(tester.widget<TextField>(find.byKey(const Key('serverUrlField'))).controller!.text, 'http://10.0.2.2:8000');
    expect(find.text('An account is optional. Everything works offline without one.'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(find.byKey(const Key('registerButton')), findsOneWidget);
    expect(find.byKey(const Key('syncNowButton')), findsNothing);
  });

  testWidgets('save server address: invalid then valid', (tester) async {
    final app = await open(tester);
    await tester.enterText(find.byKey(const Key('serverUrlField')), 'example');
    await tester.tap(find.byKey(const Key('saveServerButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Enter an http:// or https:// address');
    await tester.enterText(find.byKey(const Key('serverUrlField')), 'http://192.168.1.5:8000');
    await tester.tap(find.byKey(const Key('saveServerButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Server address saved');
    expect(app.prefs.getString('apiBaseUrl'), 'http://192.168.1.5:8000');
  });

  testWidgets('validation messages for email and password', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('emailField')), 'bad');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Enter a valid email address');
    await tester.enterText(find.byKey(const Key('emailField')), 'me@x.org');
    await tester.enterText(find.byKey(const Key('passwordField')), 'short');
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Password must be at least 10 characters');
    verifyNever(() => client.send(any()));
  });

  testWidgets('register, then duplicate, then wrong password, then sign in, sync, sign out', (tester) async {
    final app = await open(tester);
    await tester.enterText(find.byKey(const Key('emailField')), 'me@x.org');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Account created. You can sign in now.');
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'This email is already registered');
    await tester.enterText(find.byKey(const Key('passwordField')), 'wrongpassword');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Incorrect email or password');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as me@x.org'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsNothing);

    await app.services.bookmarks.add(const AyahRef(2, 255));
    server.seed({'id': 'b-1-1', 'surah': 1, 'ayah': 1, 'updatedAt': 1, 'deleted': false});
    await tester.tap(find.byKey(const Key('syncNowButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Sync complete: 2 bookmarks');
    expect(find.byKey(const Key('lastSync')), findsOneWidget);
    expect(server.bookmarks, contains('b-2-255'));
    expect(app.services.bookmarks.isBookmarked(const AyahRef(1, 1)), isTrue);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(app.prefs.getString('account.token'), isNull);
  });

  testWidgets('offline: clear error message, nothing lost', (tester) async {
    when(() => client.send(any())).thenThrow(const SocketException('Network is unreachable'));
    final app = await open(tester, prefs: {'account.token': FakeApiServer.token, 'account.email': 'me@x.org'});
    await app.services.bookmarks.add(const AyahRef(3, 3));
    await tester.tap(find.byKey(const Key('syncNowButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Cannot reach the server. Check your internet connection and the server address.');
    expect(app.services.bookmarks.dirty, contains('b-3-3'));
    expect(find.text('Signed in as me@x.org'), findsOneWidget);
  });

  testWidgets('offline sign-in in Arabic shows the Arabic message', (tester) async {
    when(() => client.send(any())).thenThrow(const SocketException('Network is unreachable'));
    await open(tester, locale: 'ar');
    await tester.enterText(find.byKey(const Key('emailField')), 'me@x.org');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'تعذّر الوصول إلى الخادم. تحقّق من اتصالك بالإنترنت ومن عنوان الخادم.');
  });

  testWidgets('expired session during sync signs out', (tester) async {
    await open(tester, prefs: {'account.token': 'stale', 'account.email': 'me@x.org'});
    await tester.tap(find.byKey(const Key('syncNowButton')));
    await tester.pumpAndSettle();
    expect(message(tester), 'Your session has expired. Please sign in again.');
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('buttons are disabled and a spinner shows while busy', (tester) async {
    when(() => client.send(any())).thenAnswer((inv) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return server.handle(inv.positionalArguments.first as http.BaseRequest);
    });
    await open(tester, prefs: {'account.token': FakeApiServer.token, 'account.email': 'me@x.org'});
    await tester.tap(find.byKey(const Key('syncNowButton')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('syncNowButton'))).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('logoutButton'))).onPressed, isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(message(tester), 'Sync complete: 0 bookmarks');
  });
}
