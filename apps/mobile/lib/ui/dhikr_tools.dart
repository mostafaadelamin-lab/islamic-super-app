import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../theme/design_tokens.dart';
import 'contact_screen.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// Text shared for a dhikr: the text unchanged, then where it comes from.
String dhikrShareBody(String text, String source) => '$text\n\n— $source';

/// A mistake report: what the reader thinks is wrong goes under the intro; [where] names the dhikr.
String dhikrReportBody(String intro, String where, String text) {
  const quoteChars = 80;
  final quote = text.length > quoteChars ? '${text.substring(0, quoteChars)}…' : text;
  return '$intro\n\n$where\n«$quote»\n\n';
}

/// Share (system share sheet) and "report a mistake" (the contact form) for one dhikr.
class DhikrActions extends StatelessWidget {
  const DhikrActions({
    super.key,
    required this.text,
    required this.source,
    required this.where,
    required this.keyPrefix,
  });
  final String text;
  final String source;
  final String where;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sharer = context.services.sharer;
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        TextButton.icon(
          key: Key('${keyPrefix}Share'),
          onPressed: () => sharer.shareText(dhikrShareBody(text, source)),
          icon: const RIcon(RIcons.share, size: 18),
          label: Text(l.adhkarShare),
        ),
        TextButton.icon(
          key: Key('${keyPrefix}Report'),
          // Opens the contact form, its title and message filled in (owner 2026-11-15).
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ContactScreen(
                initialTitle: l.adhkarReportTitle,
                initialMessage: dhikrReportBody(l.adhkarReportIntro, where, text),
              ),
            ),
          ),
          icon: const RIcon(RIcons.flag, size: 18),
          label: Text(l.adhkarReport),
        ),
      ],
    );
  }
}

/// Which colour a [TintedAction] uses.
enum ActionTint { gold, navy, soft, plain }

/// Our icon inside a coloured rounded square with its name under it (owner 2026-11-26, option 2:
/// the morning / evening adhkar top bar, modern look).
class TintedAction extends StatelessWidget {
  const TintedAction({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.tint = ActionTint.plain,
  });
  final RIconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final ActionTint tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tint) {
      ActionTint.gold => (scheme.secondary, scheme.onPrimary),
      ActionTint.navy => (scheme.primary, scheme.onPrimary),
      ActionTint.soft => (scheme.secondaryContainer, scheme.secondary),
      ActionTint.plain => (scheme.surfaceContainerHigh, scheme.primary),
    };
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        elevation: 2,
        shadowColor: scheme.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RIcon(icon, size: 22, color: fg),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App-bar button switching between a list and one card at a time (kept in settings).
class AdhkarViewToggle extends StatelessWidget {
  const AdhkarViewToggle({super.key, this.tinted = false});

  /// Drawn as a [TintedAction] (morning / evening adhkar).
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final cards = settings.adhkarCards;
        if (tinted) {
          return TintedAction(
            key: const Key('adhkarViewMode'),
            label: l.adhkarBarView,
            tooltip: cards ? l.adhkarList : l.adhkarCards,
            icon: cards ? RIcons.pages : RIcons.palette,
            onPressed: () => settings.setAdhkarCards(!cards),
          );
        }
        return IconButton(
          key: const Key('adhkarViewMode'),
          tooltip: cards ? l.adhkarList : l.adhkarCards,
          icon: RIcon(cards ? RIcons.pages : RIcons.palette),
          onPressed: () => settings.setAdhkarCards(!cards),
        );
      },
    );
  }
}

/// How long the "done" tick stays on screen before a finished adhkar list closes by itself.
const adhkarAutoExitDelay = Duration(milliseconds: 1200);

/// Owner 2026-11-15: when the reader completes the last dhikr of a list, the screen goes back to the
/// list it was opened from by itself, after a short moment so the last tap is seen to count.
/// Only a completion that happens while the screen is open triggers it (a list that was already
/// finished today opens normally), and undoing it (reset) before the delay cancels it.
class AdhkarAutoExit {
  Timer? _timer;
  bool? _wasComplete;

  /// Call on every rebuild with whether everything in the list is done now.
  void update(BuildContext context, {required bool complete}) {
    final was = _wasComplete;
    _wasComplete = complete;
    if (!complete) {
      _timer?.cancel();
      _timer = null;
    } else if (was == false) {
      _timer?.cancel();
      _timer = Timer(adhkarAutoExitDelay, () {
        if (!context.mounted) return;
        final route = ModalRoute.of(context);
        // Leave only when this screen is on top (not under a sheet or another page).
        if (route != null && !route.isCurrent) return;
        unawaited(Navigator.of(context).maybePop());
      });
    }
  }

  /// Forget the state, e.g. when the screen switches to another list (morning ↔ evening).
  void restart() {
    _timer?.cancel();
    _timer = null;
    _wasComplete = null;
  }

  void dispose() => _timer?.cancel();
}

/// One item at a time with previous / next and the position.
class CardPager extends StatefulWidget {
  const CardPager({super.key, required this.count, required this.builder, this.isDone, this.resetKey, this.onIndex});
  final ValueChanged<int>? onIndex;
  final int count;
  final Widget Function(BuildContext context, int i) builder;

  /// When it turns true for the shown card, the pager moves on by itself.
  final bool Function(int i)? isDone;
  final Object? resetKey;

  @override
  State<CardPager> createState() => _CardPagerState();
}

class _CardPagerState extends State<CardPager> {
  final _pages = PageController();
  int _at = 0;
  bool _wasDone = false;

  @override
  void didUpdateWidget(CardPager old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey) {
      _at = 0;
      _wasDone = false;
      if (_pages.hasClients) _pages.jumpToPage(0);
      widget.onIndex?.call(0);
      return;
    }
    final done = widget.isDone?.call(_at) ?? false;
    if (done && !_wasDone && _at < widget.count - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_at + 1));
    }
    _wasDone = done;
  }

  void _go(int i) {
    if (!mounted || !_pages.hasClients) return;
    _pages.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const Key('cardPager'),
            controller: _pages,
            itemCount: widget.count,
            onPageChanged: (i) {
              setState(() {
                _at = i;
                _wasDone = widget.isDone?.call(i) ?? false;
              });
              widget.onIndex?.call(i);
            },
            itemBuilder: (context, i) => SingleChildScrollView(child: widget.builder(context, i)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              TextButton(
                key: const Key('cardPrev'),
                onPressed: _at == 0 ? null : () => _go(_at - 1),
                child: Text(l.adhkarPrevCard),
              ),
              Expanded(
                child: Text(
                  '${context.num(_at + 1)} / ${context.num(widget.count)}',
                  key: const Key('cardPos'),
                  textAlign: TextAlign.center,
                ),
              ),
              FilledButton(
                key: const Key('cardNext'),
                onPressed: _at >= widget.count - 1 ? null : () => _go(_at + 1),
                child: Text(l.adhkarNextCard),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
