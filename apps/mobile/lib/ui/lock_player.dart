import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'stories_screen.dart' show SleepTimerButton;

/// "1:05" / "1:02:07" in the app's digits (always left to right).
String playerClock(BuildContext context, Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return context.numLtr(h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec');
}

/// The one look of every audio player in the app (owner 2026-11-22: like the lock-screen player,
/// shown right where the item is played): what is playing, a seek bar with the time gone and the
/// full length, and big controls: previous, back 30 s, play/pause, forward 30 s, next. ✕ closes it.
///
/// Test keys are built from [id]: `${id}Toggle`, `${id}Slider`, `${id}Stop`, `${id}Prev`,
/// `${id}Next`, `${id}Back30`, `${id}Fwd30`.
class LockPlayerCard extends StatefulWidget {
  const LockPlayerCard({
    super.key,
    required this.id,
    this.title,
    this.subtitle,
    required this.position,
    required this.total,
    required this.playing,
    this.loading = false,
    this.error,
    required this.onToggle,
    required this.onClose,
    this.onSeek,
    this.onPrevious,
    this.onNext,
    this.showSkip = false,
    this.live = false,
    this.sleepTimer = false,
    this.docked = false,
    this.onTitleTap,
    this.titleKey,
  });

  final String id;
  final String? title;
  final String? subtitle;
  final Duration position;

  /// Full length; null while it is not known yet.
  final Duration? total;
  final bool playing;
  final bool loading;

  /// Shown instead of the seek bar when the audio cannot play.
  final String? error;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  /// Jump to a position (seek bar and ±30 s). Null: not seekable.
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Show previous / next (disabled when the callback is null).
  final bool showSkip;

  /// A live stream: no seek bar, no ±30 s.
  final bool live;
  final bool sleepTimer;

  /// Drawn as a bar at the bottom of the screen (only when the item is not listed on this screen).
  final bool docked;
  final VoidCallback? onTitleTap;
  final Key? titleKey;

  @override
  State<LockPlayerCard> createState() => _LockPlayerCardState();
}

class _LockPlayerCardState extends State<LockPlayerCard> {
  /// Where the thumb is while the user drags it (the audio jumps when it is let go).
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = w.total != null && w.total!.inMilliseconds > 0 ? w.total : null;
    final seekable = !w.live && w.onSeek != null;
    void seekBy(int s) {
      var to = w.position + Duration(seconds: s);
      if (to < Duration.zero) to = Duration.zero;
      if (total != null && to > total) to = total;
      w.onSeek!(to);
    }

    final head = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
          alignment: Alignment.center,
          child: RIcon(RIcons.headphones, color: scheme.onPrimary, size: 24),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: InkWell(
            key: w.onTitleTap == null ? null : Key('${w.id}Open'),
            onTap: w.onTitleTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.title ?? l.playerTitle,
                  key: w.titleKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (w.subtitle != null || w.loading)
                  Text(
                    w.loading && !w.playing ? l.audioLoading : w.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
        if (w.sleepTimer) const SleepTimerButton(),
        IconButton(
          key: Key('${w.id}Stop'),
          tooltip: l.audioClose,
          icon: const RIcon(RIcons.close),
          onPressed: w.onClose,
        ),
      ],
    );

    Widget progress;
    if (w.error != null) {
      progress = Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
        child: Text(
          w.error!,
          style: TextStyle(color: scheme.error),
          textAlign: TextAlign.center,
        ),
      );
    } else if (w.live) {
      progress = Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: scheme.error),
            const SizedBox(width: DesignTokens.spaceXs),
            Text(l.libraryLive, style: theme.textTheme.labelMedium),
          ],
        ),
      );
    } else {
      final max = (total ?? Duration.zero).inMilliseconds.toDouble();
      final value = total == null ? 0.0 : (_drag ?? w.position.inMilliseconds.clamp(0, max.toInt()).toDouble());
      final shown = _drag == null ? w.position : Duration(milliseconds: _drag!.round());
      progress = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.primary.withValues(alpha: 0.18),
              thumbColor: scheme.primary,
            ),
            child: SizedBox(
              height: 32,
              child: Slider(
                key: Key('${w.id}Slider'),
                value: value,
                max: total == null ? 1 : max,
                semanticFormatterCallback: (v) => playerClock(context, Duration(milliseconds: v.round())),
                onChanged: total == null || !seekable ? null : (v) => setState(() => _drag = v),
                onChangeEnd: total == null || !seekable
                    ? null
                    : (v) {
                        setState(() => _drag = null);
                        w.onSeek!(Duration(milliseconds: v.round()));
                      },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
            child: Row(
              children: [
                Text(playerClock(context, shown), key: Key('${w.id}Elapsed'), style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(
                  total == null ? '--:--' : playerClock(context, total),
                  key: Key('${w.id}Total'),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final toggleIcon = w.loading && !w.playing
        ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.onPrimary))
        : RIcon(w.playing ? RIcons.pause : RIcons.play, size: 28, color: scheme.onPrimary);
    final controls = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (w.showSkip)
          IconButton(
            key: Key('${w.id}Prev'),
            tooltip: l.playerPrev,
            icon: const RIcon(RIcons.prev),
            onPressed: w.onPrevious,
          ),
        if (seekable)
          IconButton(
            key: Key('${w.id}Back30'),
            tooltip: l.storiesRewind,
            iconSize: 28,
            icon: const Icon(Icons.replay_30),
            onPressed: () => seekBy(-30),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
          child: IconButton.filled(
            key: Key('${w.id}Toggle'),
            tooltip: w.playing ? l.storiesPause : l.storiesPlay,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(56),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            icon: toggleIcon,
            onPressed: w.onToggle,
          ),
        ),
        if (seekable)
          IconButton(
            key: Key('${w.id}Fwd30'),
            tooltip: l.storiesForward,
            iconSize: 28,
            icon: const Icon(Icons.forward_30),
            onPressed: () => seekBy(30),
          ),
        if (w.showSkip)
          IconButton(
            key: Key('${w.id}Next'),
            tooltip: l.playerNext,
            icon: const RIcon(RIcons.next),
            onPressed: w.onNext,
          ),
      ],
    );

    final body = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
        DesignTokens.spaceXs,
        DesignTokens.spaceSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          const SizedBox(height: DesignTokens.spaceXs),
          progress,
          controls,
        ],
      ),
    );

    if (w.docked) {
      return Material(
        color: scheme.surfaceContainerHigh,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: body),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceXs,
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: body,
    );
  }
}
