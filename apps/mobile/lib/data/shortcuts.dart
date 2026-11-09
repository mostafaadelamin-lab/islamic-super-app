import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

/// Home-screen shortcut the app was opened from ('quran', 'prayer', 'adhkar', 'tasbih'); the shell acts on it.
final shortcutRequests = ValueNotifier<String?>(null);

/// Long-press shortcuts on the app icon (Android app shortcuts / iOS quick actions).
Future<void> setUpShortcuts({required Map<String, String> labels}) async {
  try {
    const actions = QuickActions();
    await actions.initialize((type) => shortcutRequests.value = type);
    await actions.setShortcutItems([
      for (final e in labels.entries) ShortcutItem(type: e.key, localizedTitle: e.value),
    ]);
  } catch (_) {
    // no plugin (tests) or an old launcher: the app works without shortcuts
  }
}
