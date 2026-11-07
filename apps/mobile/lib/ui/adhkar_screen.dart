import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/adhkar.dart';
import '../theme/design_tokens.dart';
import 'hisn_screen.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'review_notice.dart';

/// Morning / evening adhkar with a counter on every item (persisted for the
/// day), plus the way into Hisn al-Muslim.
class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key, this.initial});
  final AdhkarSession? initial;

  @override
  State<AdhkarScreen> createState() => AdhkarScreenState();
}

class AdhkarScreenState extends State<AdhkarScreen> {
  AdhkarSession? _session;
  AdhkarSession get session => _session!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session ??= widget.initial ?? _defaultSession();
  }

  /// Morning from Fajr until Asr, evening otherwise.
  AdhkarSession _defaultSession() {
    final s = context.services;
    final pv = PrayerView.compute(s);
    final today = pv.today;
    if (today == null) return AdhkarSession.morning;
    final now = s.clock().toUtc();
    final fajr = today.day.utc['fajr']!;
    final asr = today.day.utc['asr']!;
    return !now.isBefore(fajr) && now.isBefore(asr) ? AdhkarSession.morning : AdhkarSession.evening;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navAdhkar),
        actions: [
          IconButton(
            key: const Key('adhkarReset'),
            tooltip: l.adhkarReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => s.adhkar.reset(session),
          ),
          IconButton(
            key: const Key('openHisn'),
            tooltip: l.adhkarHisn,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HisnScreen())),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: s.adhkar,
        builder: (context, _) {
          final p = s.adhkar.progress(session);
          return ListView(
            key: const Key('adhkarList'),
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
                child: SegmentedButton<AdhkarSession>(
                  key: const Key('adhkarSession'),
                  segments: [
                    ButtonSegment(
                      value: AdhkarSession.morning,
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: Text(l.adhkarMorning),
                    ),
                    ButtonSegment(
                      value: AdhkarSession.evening,
                      icon: const Icon(Icons.nights_stay_outlined),
                      label: Text(l.adhkarEvening),
                    ),
                  ],
                  selected: {session},
                  onSelectionChanged: (v) => setState(() => _session = v.single),
                ),
              ),
              ReviewNotice(l.adhkarReviewNotice, key: const Key('adhkarNotice')),
              Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session == AdhkarSession.morning ? l.adhkarMorningTitle : l.adhkarEveningTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      l.adhkarProgress(context.num(p.completedItems), context.num(p.items.length)),
                      key: const Key('adhkarProgress'),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                      child: LinearProgressIndicator(value: p.fraction, minHeight: 6),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(l.adhkarTapToCount, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              for (final d in p.items) _DhikrCard(dhikr: d, session: session, progress: p),
            ],
          );
        },
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({required this.dhikr, required this.session, required this.progress});
  final Dhikr dhikr;
  final AdhkarSession session;
  final AdhkarProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    final done = progress.isDone(dhikr);
    final remaining = progress.remaining(dhikr);
    return Card(
      key: Key('dhikr-${dhikr.index}'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      color: done ? scheme.surfaceContainer : null,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: InkWell(
              key: Key('dhikrTap-${dhikr.index}'),
              onTap: done
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      s.adhkar.tap(session, dhikr);
                    },
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(dhikr.text, textDirection: TextDirection.rtl, style: duaStyle(context)),
                    const SizedBox(height: DesignTokens.spaceMd),
                    Row(
                      children: [
                        Chip(label: Text(l.adhkarRepeat(context.num(dhikr.meta.count)))),
                        const Spacer(),
                        Container(
                          key: Key('dhikrCount-${dhikr.index}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceMd,
                            vertical: DesignTokens.spaceSm,
                          ),
                          decoration: BoxDecoration(
                            color: done ? scheme.primary : scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                done ? Icons.check : Icons.touch_app_outlined,
                                size: 18,
                                color: done ? scheme.onPrimary : scheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: DesignTokens.spaceXs),
                              Text(
                                done ? l.adhkarDone : l.adhkarRemaining(context.num(remaining)),
                                style: TextStyle(
                                  color: done ? scheme.onPrimary : scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CopyButton(text: dhikr.text, buttonKey: Key('dhikrCopy-${dhikr.index}')),
          ),
        ],
      ),
    );
  }
}

/// Copies [text] and confirms with a snackbar.
class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.text, this.buttonKey});
  final String text;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextButton.icon(
      key: buttonKey,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: text));
        messenger.showSnackBar(SnackBar(content: Text(l.adhkarCopied)));
      },
      icon: const Icon(Icons.copy, size: 18),
      label: Text(l.adhkarCopy),
    );
  }
}
