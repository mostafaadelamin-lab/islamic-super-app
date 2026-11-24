import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/drive_mode.dart';
import '../domain/adhkar.dart';
import '../theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import 'review_notice.dart' show duaStyle;
import 'l10n_ext.dart';
import 'r_icon.dart';

/// Opens driving mode for [session] and starts it.
Future<void> openDriveMode(BuildContext context, AdhkarSession session) {
  final drive = context.services.drive;
  if (drive == null) return Future.value();
  final s = context.services;
  if (s.recitation.isPlaying) unawaited(s.recitation.pause());
  if (s.narration.isPlaying) unawaited(s.narration.pause());
  unawaited(drive.start(session));
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DriveModeScreen(drive: drive)));
}

/// Driving mode (1.2.2): one dhikr at a time in big type, the count in a big ring, and three
/// big buttons. The same controls are on the car screen, the steering wheel and the lock screen.
class DriveModeScreen extends StatelessWidget {
  const DriveModeScreen({super.key, required this.drive});
  final DriveModeController drive;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([drive, context.services.settings]),
      builder: (context, _) {
        final session = drive.session;
        final title = session == AdhkarSession.evening ? l.adhkarEveningTitle : l.adhkarMorningTitle;
        return Scaffold(
          appBar: AppBar(
            title: Text('${l.driveTitle} · $title'),
            actions: [
              IconButton(
                key: const Key('driveSettings'),
                tooltip: l.driveSettings,
                icon: const RIcon(RIcons.settings),
                onPressed: () =>
                    showModalBottomSheet<void>(context: context, builder: (_) => const DriveSettingsSheet()),
              ),
            ],
          ),
          body: SafeArea(child: _body(context, l, scheme)),
        );
      },
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, ColorScheme scheme) {
    if (drive.isPreparing) {
      return Center(
        key: const Key('drivePreparing'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(l.drivePreparing),
          ],
        ),
      );
    }
    if (drive.failed) {
      return Center(
        key: const Key('driveFailed'),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.driveFailed, textAlign: TextAlign.center),
              const SizedBox(height: DesignTokens.spaceMd),
              FilledButton(
                key: const Key('driveRetry'),
                onPressed: () => drive.start(drive.session ?? AdhkarSession.morning),
                child: Text(l.driveRetry),
              ),
            ],
          ),
        ),
      );
    }
    final item = drive.current;
    if (item == null) return const SizedBox.shrink();
    final count = item.count;
    final saying = drive.saying;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.driveDhikrOf(context.num(drive.index + 1), context.num(drive.items.length)),
                  key: const Key('driveDhikrOf'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            child: LinearProgressIndicator(value: (drive.index + 1) / drive.items.length, minHeight: 5),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
            child: Text(
              item.dhikr.text,
              key: const Key('driveText'),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: duaStyle(context, size: 22),
            ),
          ),
        ),
        if (drive.finished)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              children: [
                Text(l.driveFinished, key: const Key('driveFinished'), textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.spaceSm),
                FilledButton(
                  key: const Key('driveAgain'),
                  onPressed: () => drive.start(drive.session!),
                  child: Text(l.driveAgain),
                ),
              ],
            ),
          )
        else
          _Counter(saying: saying, count: count),
        Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
          // Media buttons keep the usual order (previous left, next right), as on the car screen.
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BigButton(
                key: const Key('drivePrevious'),
                icon: RIcons.prev,
                label: l.drivePrevious,
                onTap: drive.previous,
              ),
              _BigButton(
                key: const Key('drivePlayPause'),
                icon: drive.isPlaying ? RIcons.pause : RIcons.play,
                label: drive.isPlaying ? l.drivePause : l.drivePlay,
                big: true,
                onTap: drive.toggle,
              ),
              _BigButton(key: const Key('driveNext'), icon: RIcons.next, label: l.driveNext, onTap: drive.next),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RIcon(RIcons.car, color: scheme.primary, size: 22),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Text(
                  l.driveCarHint,
                  key: const Key('driveCarHint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.saying, required this.count});
  final int saying;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: count == 0 ? 0 : saying / count,
              strokeWidth: 10,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.num(saying),
                key: const Key('driveCount'),
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
              ),
              Text(l.driveOutOf(context.num(count)), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({super.key, required this.icon, required this.label, required this.onTap, this.big = false});
  final RIconData icon;
  final String label;
  final Future<void> Function() onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = big ? 96.0 : 76.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: big ? scheme.primary : scheme.primaryContainer,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => unawaited(onTap()),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: RIcon(
                  icon,
                  size: big ? 44 : 34,
                  color: big ? scheme.onPrimary : scheme.onPrimaryContainer,
                  semanticLabel: label,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Tick sounds on/off and how often the count is said out loud.
class DriveSettingsSheet extends StatelessWidget {
  const DriveSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    return SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.driveSettings, style: Theme.of(context).textTheme.titleLarge),
              SwitchListTile(
                key: const Key('driveCuesSwitch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.driveCues),
                subtitle: Text(l.driveCuesSub),
                value: settings.driveCues,
                onChanged: settings.setDriveCues,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(l.driveSayEvery, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DesignTokens.spaceXs),
              SegmentedButton<int>(
                key: const Key('driveSayEvery'),
                segments: [
                  ButtonSegment(value: 0, label: Text(l.driveSayOff)),
                  for (final n in const [10, 33])
                    ButtonSegment(value: n, label: Text(l.driveSayEveryN(context.num(n)))),
                ],
                selected: {settings.driveSayEvery},
                onSelectionChanged: (v) => settings.setDriveSayEvery(v.single),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
