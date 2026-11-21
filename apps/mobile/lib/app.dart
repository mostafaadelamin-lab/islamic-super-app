import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_services.dart';
import 'data/notifications.dart';
import 'data/home_widget_sync.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'ui/background_audio.dart';
import 'ui/dhikr_audio.dart';
import 'ui/adhan_now_bar.dart';
import 'ui/home_shell.dart';
import 'ui/onboarding_screen.dart';

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
    // downloaded muezzin recordings are known). A chosen muezzin that is not on the phone (only the
    // defaults are bundled since 1.2.1) is then downloaded quietly; until then the default one sounds.
    unawaited(
      services.adhanVoices.init().whenComplete(() async {
        await services.adhan.sync(force: true);
        await _continueAdhan();
        final s = services.settings;
        await services.adhanVoices.fetchMissing([s.adhanVoice, s.adhanFajrVoice]);
      }),
    );
    unawaited(_widget.sync(force: true));
    final b = services.adhan.backend;
    if (b is LocalNotificationsBackend) {
      _tapSub = b.adhanTaps.listen((p) => unawaited(services.adhan.continueFrom(p, services.adhanPreview)));
    }
    // Dhikr recordings also show on the lock screen and keep playing in the background.
    services.media?.attach(_dhikrSource);
  }

  late final _dhikrSource = DhikrMediaSource(DhikrPlayer.instance, services.settings);

  late final _widget = HomeWidgetSync(widget.services);

  StreamSubscription<String>? _tapSub;

  /// iPhone: the app was opened from an adhan notification or the alarm's "continue" button, so the rest
  /// of the adhan plays here.
  Future<void> _continueAdhan() async {
    final b = services.adhan.backend;
    final tap =
        (b is LocalNotificationsBackend ? b.takeLaunchTap() : null) ?? await services.adhan.parts?.takeAlarmTap();
    if (tap != null) await services.adhan.continueFrom(tap, services.adhanPreview);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
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
      unawaited(_continueAdhan());
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
        builder: (context, _) {
          AppTheme.palette = services.settings.palette;
          return MaterialApp(
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
            // A stop bar while an adhan opened from its alert plays (iPhone).
            builder: (context, child) => AdhanNowBar(preview: services.adhanPreview, child: child!),
            // First run: the welcome tour and the permissions setup, once.
            home: services.settings.onboardingDone
                ? const HomeShell()
                : OnboardingScreen(onDone: () => services.settings.setOnboardingDone(true)),
          );
        },
      ),
    );
  }
}
