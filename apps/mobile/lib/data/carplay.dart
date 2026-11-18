// CarPlay (iPhone): the car screen shows a list «أذكار الصباح / أذكار المساء»; picking one
// starts driving mode here and the car switches to its Now Playing screen, which shows the
// live title and count that driving mode already gives the lock screen (audio_service).
//
// The list itself is drawn natively (ios/Runner/CarPlaySceneDelegate.swift). This side sends
// it the items (from DriveBrowser, the same list Android Auto shows) and plays what is picked.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'drive_mode.dart';
import 'settings.dart';

class CarPlayBridge {
  CarPlayBridge(this.browser, this.settings, {MethodChannel? channel})
    : channel = channel ?? const MethodChannel(channelName) {
    this.channel.setMethodCallHandler(_handle);
    settings.addListener(_onSettings);
    _lastLocale = settings.locale.languageCode;
    send();
  }

  static const channelName = 'org.rattil.app/carplay';

  final DriveBrowser browser;
  final SettingsController settings;
  final MethodChannel channel;
  late String _lastLocale;

  /// What the car's list shows: a title and one row per session.
  Map<String, Object> describe() {
    return {
      'title': lookupAppLocalizations(settings.locale).driveTitle,
      'items': [
        for (final m in browser.children(AudioService.browsableRootId))
          {
            'id': m.id,
            'title': m.title,
            'detail': m.artist ?? '',
            'icon': m.id == DriveBrowser.eveningId ? 'moon.stars' : 'sun.max',
          },
      ],
    };
  }

  /// Sends the list to the car side (it keeps it until a car connects).
  Future<void> send() async {
    try {
      await channel.invokeMethod<void>('items', describe());
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

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'play':
        await browser.play(call.arguments as String);
        // null = playing; otherwise the message the car shows.
        if (!browser.drive.failed) return null;
        return lookupAppLocalizations(settings.locale).driveFailed;
      case 'ready':
        await send();
        return null;
    }
    throw MissingPluginException(call.method);
  }

  void dispose() {
    settings.removeListener(_onSettings);
    channel.setMethodCallHandler(null);
  }
}
