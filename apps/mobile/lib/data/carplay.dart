// CarPlay (iPhone): the car screen lists «أذكار الصباح / أذكار المساء» and the listening sections
// (radio, recitation library, al-Sha'rawi, prophets' stories, nasheeds). Picking an item plays it
// here and the car switches to its Now Playing screen, which shows the live title the lock screen
// shows (audio_service). In driving mode its «نص الذكر» button opens the whole dhikr in lines.
//
// The lists are drawn natively (ios/Runner/CarPlaySceneDelegate.swift). This side gives it the
// items (from CarBrowser, the same lists Android Auto shows) and plays what is picked.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'car_browser.dart';
import 'settings.dart';

class CarPlayBridge {
  CarPlayBridge(this.browser, this.settings, {MethodChannel? channel})
    : channel = channel ?? const MethodChannel(channelName) {
    this.channel.setMethodCallHandler(_handle);
    settings.addListener(_onSettings);
    browser.drive.addListener(_onDrive);
    _lastLocale = settings.locale.languageCode;
    _textOn = browser.drive.isActive;
    send();
  }

  static const channelName = 'org.rattil.app/carplay';

  final CarBrowser browser;
  final SettingsController settings;
  final MethodChannel channel;
  late String _lastLocale;
  late bool _textOn;

  AppLocalizations get _l => lookupAppLocalizations(settings.locale);

  /// One list for the car: its title and rows. A row with 'browsable' opens another list.
  Future<Map<String, Object>> describe([String parentId = AudioService.browsableRootId]) async {
    return {
      'title': parentId == AudioService.browsableRootId ? _l.driveTitle : '',
      'items': [
        for (final m in await browser.children(parentId))
          {
            'id': m.id,
            'title': m.title,
            'detail': m.artist ?? '',
            'icon': (m.extras?['icon'] as String?) ?? 'play.circle',
            'browsable': m.playable == false,
            if (m.extras?['section'] case final String s) 'section': s,
          },
      ],
    };
  }

  /// What the Now Playing screen's «نص الذكر» button shows: the button title, and whether it is on
  /// (only in driving mode).
  Map<String, Object> textButton() => {'title': _l.carText, 'on': browser.drive.isActive};

  /// Sends the root list and the text button to the car side (it keeps them until a car connects).
  Future<void> send() async {
    try {
      await channel.invokeMethod<void>('items', await describe());
      await channel.invokeMethod<void>('textButton', textButton());
    } on MissingPluginException {
      // Not on iPhone, or the native side is not there (tests).
    } on PlatformException {
      // Nothing to do: the car keeps the last list it had.
    }
  }

  void _onSettings() {
    if (settings.locale.languageCode == _lastLocale) return;
    _lastLocale = settings.locale.languageCode;
    send();
  }

  void _onDrive() {
    if (browser.drive.isActive == _textOn) return;
    _textOn = browser.drive.isActive;
    channel.invokeMethod<void>('textButton', textButton()).catchError((_) {});
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'children':
        return describe(call.arguments as String);
      case 'play':
        await browser.play(call.arguments as String);
        // null = playing; otherwise the message the car shows.
        if (!browser.failed) return null;
        return _l.driveFailed;
      case 'text':
        return {'title': _l.carText, 'lines': browser.drive.textLines()};
      case 'ready':
        await send();
        return null;
    }
    throw MissingPluginException(call.method);
  }

  void dispose() {
    settings.removeListener(_onSettings);
    browser.drive.removeListener(_onDrive);
    channel.setMethodCallHandler(null);
  }
}
