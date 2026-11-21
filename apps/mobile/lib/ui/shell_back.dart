import 'package:flutter/material.dart';

/// The main tabs (Quran, Prayer, Adhkar, Videos, More) open from the home page's tiles without a
/// new page, so they had no way back (owner 2026-11-21: «زرار الرجوع» on every page). [HomeShell]
/// puts this above the open tab; the tab's app bar shows a back arrow that returns to Home.
class ShellBack extends InheritedWidget {
  const ShellBack({super.key, required this.goHome, required super.child});

  /// Returns to the Home tab; null on the Home tab itself.
  final VoidCallback? goHome;

  static VoidCallback? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellBack>()?.goHome;

  @override
  bool updateShouldNotify(ShellBack old) => (old.goHome == null) != (goHome == null);
}

/// The back arrow for a main tab's app bar, or null when there is nothing to go back to (Home, or a
/// page that was opened on top, which gets Flutter's own back arrow).
Widget? shellBackButton(BuildContext context) {
  final goHome = ShellBack.of(context);
  if (goHome == null || Navigator.of(context).canPop()) return null;
  return BackButton(key: const Key('shellBack'), onPressed: goHome);
}
