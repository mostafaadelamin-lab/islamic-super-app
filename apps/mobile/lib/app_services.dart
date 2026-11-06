import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/account.dart';
import 'data/bookmarks.dart';
import 'data/content.dart';
import 'data/settings.dart';

/// Everything screens need, created once in main() (or in a test).
class AppServices {
  AppServices({
    required this.content,
    required this.settings,
    required this.bookmarks,
    required this.account,
    required this.clock,
  });

  factory AppServices.create({
    required AppContent content,
    required SharedPreferences prefs,
    required http.Client httpClient,
    Clock? clock,
  }) {
    final c = clock ?? DateTime.now;
    final settings = SettingsController(prefs, defaultCityId: content.cities.first.id);
    final bookmarks = BookmarksController(prefs, clock: c);
    return AppServices(
      content: content,
      settings: settings,
      bookmarks: bookmarks,
      account: AccountController(prefs, settings, bookmarks, httpClient, clock: c),
      clock: c,
    );
  }

  final AppContent content;
  final SettingsController settings;
  final BookmarksController bookmarks;
  final AccountController account;
  final Clock clock;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}

extension ServicesX on BuildContext {
  AppServices get services => AppScope.of(this);
}
