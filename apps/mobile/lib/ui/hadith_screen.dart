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
            ReviewNotice(l.hadithReview),
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

/// A book twenty hadiths at a time, with "go to number" and search.
class HadithBookScreen extends StatefulWidget {
  const HadithBookScreen({super.key, required this.book, this.start = 1});
  final HadithBook book;
  final int start;

  @override
  State<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends State<HadithBookScreen> {
  late int _from = hadithPageStart(widget.start.clamp(1, widget.book.count));
  Future<List<HadithItem>>? _page;
  List<HadithItem>? _results;
  (int, int)? _progress;
  bool _searchFailed = false;
  final _go = TextEditingController();
  final _query = TextEditingController();
  final _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _page ??= _load();
  }

  @override
  void dispose() {
    _go.dispose();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<List<HadithItem>> _load() => context.services.hadith.range(widget.book, _from, _from + hadithPageSize - 1);

  void _open(int n) {
    setState(() {
      _from = hadithPageStart(n.clamp(1, widget.book.count));
      _results = null;
      _page = _load();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

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

  Widget _tools(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final book = widget.book;
    final last = (_from + hadithPageSize - 1).clamp(1, book.count);
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(book.name(context.isArabic))),
      body: ReadableWidth(
        child: FutureBuilder<List<HadithItem>>(
          future: _page,
          builder: (context, snap) {
            final items = results ?? snap.data ?? const <HadithItem>[];
            return ListView(
              key: const Key('hadithList'),
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                ReviewNotice(l.hadithReview),
                _tools(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceMd,
                    DesignTokens.spaceLg,
                    0,
                  ),
                  child: results != null
                      ? Row(
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
                        )
                      : Text(
                          l.hadithRange(context.num(_from), context.num(last), context.num(book.count)),
                          key: const Key('hadithRange'),
                        ),
                ),
                if (results == null && snap.hasError)
                  Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    child: Text(l.hadithLoadError, key: const Key('hadithError')),
                  )
                else if (results == null && snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(DesignTokens.spaceXl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                for (final h in items) HadithCard(book: book, item: h),
                if (results == null)
                  Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          key: const Key('hadithPrev'),
                          onPressed: _from <= 1 ? null : () => _open(_from - hadithPageSize),
                          child: Text(l.hadithPrev),
                        ),
                        OutlinedButton(
                          key: const Key('hadithNext'),
                          onPressed: last >= book.count ? null : () => _open(_from + hadithPageSize),
                          child: Text(l.hadithNext),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
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
