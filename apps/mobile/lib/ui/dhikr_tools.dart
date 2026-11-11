import 'package:flutter/material.dart';

import '../app_services.dart';
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

/// Share and "report a mistake" for one dhikr, through the system share sheet
/// (the reader picks email, messages, …).
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
          onPressed: () => sharer.shareText(dhikrReportBody(l.adhkarReportIntro, where, text)),
          icon: const RIcon(RIcons.flag, size: 18),
          label: Text(l.adhkarReport),
        ),
      ],
    );
  }
}

/// App-bar button switching between a list and one card at a time (kept in settings).
class AdhkarViewToggle extends StatelessWidget {
  const AdhkarViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final cards = settings.adhkarCards;
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
