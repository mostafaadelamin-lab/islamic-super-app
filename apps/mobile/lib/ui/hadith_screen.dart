import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hadith.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'adhkar_screen.dart';
import 'dhikr_tools.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';

/// Western digits for Arabic-Indic ones, so "١٠٠٠" in the number box works too.
String _westernDigits(String s) =>
    String.fromCharCodes(s.runes.map((r) => r >= 0x0660 && r <= 0x0669 ? r - 0x0660 + 0x30 : r));

/// The nine hadith books, the saved hadiths and the source.
class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final catalog = context.services.content.hadith;
    return Scaffold(
      appBar: AppBar(title: Text(l.hadithTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('hadithBooks'),
          children: [
            if (!context.isArabic) ReviewNotice(l.adhkarArabicOnly),
            for (final b in catalog.books)
              ListTile(
                key: Key('hadithBook-${b.id}'),
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(b.name(context.isArabic)),
                subtitle: Text(l.hadithCount(context.num(b.count))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HadithBookScreen(book: b))),
              ),
            const Divider(),
            ListTile(
              key: const Key('hadithFavourites'),
              leading: const Icon(Icons.star_outline),
              title: Text(l.hadithFavourites),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HadithFavouritesScreen())),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Text(
                l.hadithAttribution(catalog.sourceName, catalog.licence),
                key: const Key('hadithAttribution'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One hadith: number, the source text unchanged, save, copy, share and report.
class HadithCard extends StatelessWidget {
  const HadithCard({super.key, required this.book, required this.item});
  final HadithBook book;
  final HadithItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    final text = item.text.trim();
    final source = l.hadithSource(book.name(context.isArabic), context.num(item.n));
    return Card(
      key: Key('hadith-${item.n}'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceSm, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Chip(label: Text(l.hadithNumber(context.num(item.n)))),
                const Spacer(),
                ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) {
                    final saved = settings.hadithFavourites.contains('${book.id}:${item.n}');
                    return IconButton(
                      key: Key('hadithFav-${item.n}'),
                      tooltip: saved ? l.hadithUnsave : l.hadithSave,
                      isSelected: saved,
                      icon: Icon(saved ? Icons.star : Icons.star_outline),
                      onPressed: () => settings.toggleHadithFavourite(book.id, item.n),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
              child: Text(text, textDirection: TextDirection.rtl, style: duaStyle(context)),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                CopyButton(text: text),
                DhikrActions(text: text, source: source, where: source, keyPrefix: 'hadith${item.n}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A hadith book read like a book: one hadith per page, turned with a swipe
/// (page-turn animation) or the arrows, with "go to number" and search.
class HadithBookScreen extends StatefulWidget {
  const HadithBookScreen({super.key, required this.book, this.start = 1});
  final HadithBook book;
  final int start;

  @override
  State<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends State<HadithBookScreen> {
  late final _pager = PageController(initialPage: widget.start.clamp(1, widget.book.count) - 1);
  late int _n = widget.start.clamp(1, widget.book.count);
  final _blocks = <int, Future<List<HadithItem>>>{};
  List<HadithItem>? _results;
  (int, int)? _progress;
  bool _searchFailed = false;
  bool _tools = false;
  final _go = TextEditingController();
  final _query = TextEditingController();

  @override
  void dispose() {
    _pager.dispose();
    _go.dispose();
    _query.dispose();
    super.dispose();
  }

  /// The twenty hadiths around [n], loaded once.
  Future<List<HadithItem>> _block(int n) {
    final from = hadithPageStart(n);
    return _blocks[from] ??= context.services.hadith.range(widget.book, from, from + hadithPageSize - 1);
  }

  void _open(int n) {
    final target = n.clamp(1, widget.book.count);
    setState(() {
      _results = null;
      _n = target;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pager.hasClients) _pager.jumpToPage(target - 1);
    });
  }

  void _turn(int by) => _pager.animateToPage(
    (_n - 1 + by).clamp(0, widget.book.count - 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeInOut,
  );

  Future<void> _search() async {
    final s = context.services;
    setState(() {
      _progress = (0, widget.book.chunks);
      _searchFailed = false;
    });
    try {
      final hits = await s.hadith.search(
        widget.book,
        _query.text,
        s.content.normalizer,
        onProgress: (d, t) {
          if (mounted) setState(() => _progress = (d, t));
        },
      );
      if (mounted) setState(() => _results = hits);
    } catch (_) {
      if (mounted) setState(() => _searchFailed = true);
    }
    if (mounted) setState(() => _progress = null);
  }

  Widget _toolsPanel(BuildContext context) {
    final l = context.l10n;
    final book = widget.book;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
      child: Column(
        children: [
          TextField(
            key: const Key('hadithGo'),
            controller: _go,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              labelText: l.hadithGoTo(context.num(book.count)),
              prefixIcon: const Icon(Icons.tag),
              isDense: true,
            ),
            onSubmitted: (v) {
              final n = int.tryParse(_westernDigits(v.trim()));
              if (n != null && n >= 1) _open(n);
            },
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          TextField(
            key: const Key('hadithQuery'),
            controller: _query,
            textDirection: TextDirection.rtl,
            textInputAction: TextInputAction.search,
            enabled: _progress == null,
            decoration: InputDecoration(
              labelText: l.hadithSearch(book.name(context.isArabic)),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onSubmitted: (_) => _search(),
          ),
          if (_progress case (final d, final t))
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
              child: Text(l.hadithSearching(context.num(d), context.num(t)), key: const Key('hadithProgress')),
            ),
          if (_searchFailed) Text(l.hadithLoadError, key: const Key('hadithError')),
        ],
      ),
    );
  }

  Widget _resultsList(BuildContext context, List<HadithItem> results) {
    final l = context.l10n;
    return ListView(
      key: const Key('hadithList'),
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  results.length >= hadithSearchLimit
                      ? l.hadithResultsMany(context.num(results.length))
                      : l.hadithResults(context.num(results.length)),
                  key: const Key('hadithResults'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                key: const Key('hadithClear'),
                onPressed: () => setState(() => _results = null),
                child: Text(l.hadithBackToBook),
              ),
            ],
          ),
        ),
        for (final h in results)
          InkWell(
            onTap: () => _open(h.n),
            child: HadithCard(book: widget.book, item: h),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final book = widget.book;
    final results = _results;
    final ar = context.isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.name(ar)),
        actions: [
          IconButton(
            key: const Key('hadithTools'),
            tooltip: l.hadithSearch(book.name(ar)),
            isSelected: _tools,
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _tools = !_tools),
          ),
        ],
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            if (_tools) _toolsPanel(context),
            Expanded(
              child: results != null
                  ? _resultsList(context, results)
                  : AnimatedBuilder(
                      animation: _pager,
                      builder: (context, _) {
                        final page = _pager.hasClients && _pager.position.haveDimensions
                            ? _pager.page ?? (_n - 1).toDouble()
                            : (_n - 1).toDouble();
                        return PageView.builder(
                          key: const Key('hadithBook'),
                          controller: _pager,
                          itemCount: book.count,
                          onPageChanged: (i) => setState(() => _n = i + 1),
                          itemBuilder: (context, i) => _PageTurn(
                            delta: i - page,
                            child: _BookPage(book: book, n: i + 1, items: _block(i + 1)),
                          ),
                        );
                      },
                    ),
            ),
            if (results == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceSm),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      key: const Key('hadithPrev'),
                      tooltip: l.hadithPrev,
                      onPressed: _n <= 1 ? null : () => _turn(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        l.hadithPageOf(context.num(_n), context.num(book.count)),
                        key: const Key('hadithRange'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const Key('hadithNext'),
                      tooltip: l.hadithNext,
                      onPressed: _n >= book.count ? null : () => _turn(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Turns a page about its spine as it slides away ([delta] -1..1 from the
/// page in view), with a soft shadow, like a paper book.
class _PageTurn extends StatelessWidget {
  const _PageTurn({required this.delta, required this.child});
  final double delta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = delta.clamp(-1.0, 1.0);
    if (d == 0) return child;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The page that is leaving folds about the edge it shares with the next one.
    final towardsStart = d < 0;
    final alignment = (towardsStart != rtl) ? Alignment.centerRight : Alignment.centerLeft;
    final angle = d * 1.2 * (rtl ? -1 : 1);
    return Transform(
      alignment: alignment,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.25 * d.abs())),
          ),
        ],
      ),
    );
  }
}

/// One page of the book: the hadith on paper, its number, and save/copy/share.
class _BookPage extends StatelessWidget {
  const _BookPage({required this.book, required this.n, required this.items});
  final HadithBook book;
  final int n;
  final Future<List<HadithItem>> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xFF26231D) : const Color(0xFFFBF6EA);
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, DesignTokens.spaceMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.secondary.withValues(alpha: 0.6), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FutureBuilder<List<HadithItem>>(
            future: items,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text(l.hadithLoadError, key: const Key('hadithError')));
              }
              final list = snap.data;
              if (list == null) return const Center(child: CircularProgressIndicator());
              final item = list.where((h) => h.n == n).firstOrNull;
              if (item == null) return const SizedBox.shrink();
              final text = item.text.trim();
              final source = l.hadithSource(book.name(context.isArabic), context.num(item.n));
              final settings = context.services.settings;
              return Column(
                key: Key('hadith-${item.n}'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.name(context.isArabic),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.secondary),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: settings,
                          builder: (context, _) {
                            final saved = settings.hadithFavourites.contains('${book.id}:${item.n}');
                            return IconButton(
                              key: Key('hadithFav-${item.n}'),
                              tooltip: saved ? l.hadithUnsave : l.hadithSave,
                              isSelected: saved,
                              icon: Icon(saved ? Icons.star : Icons.star_outline, color: scheme.secondary),
                              onPressed: () => settings.toggleHadithFavourite(book.id, item.n),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(l.hadithNumber(context.num(item.n)), style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Text(
                        text,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: duaStyle(context),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: DesignTokens.spaceLg, endIndent: DesignTokens.spaceLg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      CopyButton(text: text),
                      DhikrActions(text: text, source: source, where: source, keyPrefix: 'hadith${item.n}'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Saved hadiths, read from their books.
class HadithFavouritesScreen extends StatelessWidget {
  const HadithFavouritesScreen({super.key});

  Future<List<(HadithBook, HadithItem)>> _load(AppServices s, List<String> keys) async {
    final out = <(HadithBook, HadithItem)>[];
    for (final key in keys) {
      if (s.content.hadith.parseKey(key) case (final book, final n)) {
        final r = await s.hadith.range(book, n, n);
        if (r.isNotEmpty) out.add((book, r.first));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(l.hadithFavourites)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.settings,
          builder: (context, _) {
            final keys = s.settings.hadithFavourites;
            if (keys.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceXl),
                  child: Text(l.hadithNoFavourites, key: const Key('hadithFavEmpty'), textAlign: TextAlign.center),
                ),
              );
            }
            return FutureBuilder<List<(HadithBook, HadithItem)>>(
              key: ValueKey(keys.join(',')),
              future: _load(s, keys),
              builder: (context, snap) {
                final list = snap.data;
                if (list == null) return const Center(child: CircularProgressIndicator());
                return ListView(
                  key: const Key('hadithFavList'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [
                    for (final (book, item) in list) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignTokens.spaceLg,
                          DesignTokens.spaceMd,
                          DesignTokens.spaceLg,
                          0,
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HadithBookScreen(book: book, start: item.n),
                            ),
                          ),
                          child: Text(book.name(context.isArabic)),
                        ),
                      ),
                      HadithCard(book: book, item: item),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
