import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../app_services.dart';
import '../data/home_widget_sync.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'widgets.dart';

/// The prayer widget, offered at the first run and in the settings (owner 2026-11-21). Android adds it with
/// one system message (most launchers); Apple lets no app add a widget, so iPhone shows the steps for the
/// home screen and the lock screen. On Android the lock screen gets the next-prayer notice instead
/// (phones have no lock-screen widgets), switched here.
class PrayerWidgetCard extends StatefulWidget {
  const PrayerWidgetCard({super.key});

  @override
  State<PrayerWidgetCard> createState() => _PrayerWidgetCardState();
}

class _PrayerWidgetCardState extends State<PrayerWidgetCard> with WidgetsBindingObserver {
  int _widgets = 0;
  bool _canPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final d = context.services.deviceSetup;
    var widgets = 0;
    var canPin = false;
    if (d.isAndroid || d.isIos) {
      try {
        widgets = (await HomeWidget.getInstalledWidgets()).length;
        if (d.isAndroid) canPin = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _widgets = widgets;
      _canPin = canPin;
    });
  }

  Future<void> _add() async {
    try {
      await HomeWidget.requestPinWidget(qualifiedAndroidName: HomeWidgetSync.androidMediumProvider);
    } catch (e) {
      debugPrint('pin widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final d = s.deviceSetup;
    if (!d.isAndroid && !d.isIos) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    return SectionCard(
      key: const Key('prayerWidgetCard'),
      children: [
        Row(
          children: [
            RIcon(RIcons.prayer, color: theme.colorScheme.primary),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(child: Text(l.setupWidgetTitle, style: theme.textTheme.titleMedium)),
            if (_widgets > 0) RIcon(RIcons.checkCircle, color: theme.colorScheme.primary, key: const Key('widgetDone')),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(l.setupWidgetBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: DesignTokens.spaceSm),
        if (d.isAndroid && _canPin)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: const Key('setupWidgetAction'),
              onPressed: _add,
              icon: const RIcon(RIcons.plus),
              label: Text(l.setupWidgetAction),
            ),
          ),
        if (d.isAndroid && !_canPin) Text(l.setupWidgetAndroidManual, style: small),
        if (d.isIos) ...[
          Text(l.setupWidgetIos, key: const Key('setupWidgetIos'), style: small),
          const SizedBox(height: DesignTokens.spaceXs),
          Text(l.setupLockIos, style: small),
        ],
        if (d.isAndroid)
          ListenableBuilder(
            listenable: s.settings,
            builder: (context, _) => SwitchListTile(
              key: const Key('lockNotice'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.lockNoticeSetting),
              subtitle: Text(l.lockNoticeHint, style: small),
              value: s.settings.lockNotice,
              onChanged: s.settings.setLockNotice,
            ),
          ),
      ],
    );
  }
}
