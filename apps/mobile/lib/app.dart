import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_services.dart';
import 'data/home_widget_sync.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'ui/background_audio.dart';
import 'ui/dhikr_audio.dart';
import 'ui/home_shell.dart';

class RattilApp extends StatefulWidget {
  const RattilApp({super.key, required this.services});
  final AppServices services;

  @override
  State<RattilApp> createState() => _RattilAppState();
}

class _RattilAppState extends State<RattilApp> with WidgetsBindingObserver {
  AppServices get services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    services.settings.addListener(_syncAdhan);
    services.adhanVoices.addListener(_syncAdhan);
    // Renew the next days of adhan notifications on every start (once the
    // downloaded muezzin recordings are known).
    unawaited(services.adhanVoices.init().whenComplete(() => services.adhan.sync(force: true)));
    unawaited(_widget.sync(force: true));
    // Dhikr recordings also show on the lock screen and keep playing in the background.
    services.media?.attach(_dhikrSource);
  }

  late final _dhikrSource = DhikrMediaSource(DhikrPlayer.instance, services.settings);

  late final _widget = HomeWidgetSync(widget.services);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    services.settings.removeListener(_syncAdhan);
    services.adhanVoices.removeListener(_syncAdhan);
    services.media?.detach(_dhikrSource);
    _dhikrSource.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(services.adhan.sync());
      unawaited(_widget.sync());
    }
  }

  void _syncAdhan() {
    unawaited(services.adhan.sync());
    unawaited(_widget.sync());
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appName,
          debugShowCheckedModeBanner: false,
          locale: services.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: services.settings.themeMode,
          theme: AppTheme.build(Brightness.light),
          darkTheme: AppTheme.build(Brightness.dark),
          home: const HomeShell(),
        ),
      ),
    );
  }
}
