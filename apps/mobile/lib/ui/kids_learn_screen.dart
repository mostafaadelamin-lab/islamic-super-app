import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/kids_learn.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// The kids' learning corner (owner, 2026-11-20): book shelf, «احفظ حديث»,
/// adhkar cards, and wudu / salah steps. Religious text and pictures come
/// unchanged from published books (see lib/domain/kids_learn.dart).
Future<KidsLearnContent> loadKidsLearn() async =>
    KidsLearnContent.parse(await rootBundle.loadString('assets/content/kids-learn.v1.json'));

const _memorizedKey = 'kidsHadithMemorized';
const _cardsKey = 'kidsCardsDone';

/// Hadith numbers the child marked «حفظته».
Future<Set<int>> readMemorized() async {
  try {
    final p = await SharedPreferences.getInstance();
    return {for (final s in p.getStringList(_memorizedKey) ?? const <String>[]) int.parse(s)};
  } catch (_) {
    return {};
  }
}

Future<void> writeMemorized(Set<int> s) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(_memorizedKey, [for (final n in s.toList()..sort()) '$n']);
}

/// Opens one of the four corners from the kids hub.
class _Frame extends StatefulWidget {
  const _Frame({required this.title, required this.child, this.loader = loadKidsLearn});
  final String title;
  final Widget Function(KidsLearnContent) child;
  final Future<KidsLearnContent> Function() loader;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  late final Future<KidsLearnContent> _future = widget.loader();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<KidsLearnContent>(
      future: _future,
      builder: (context, snap) {
        final k = snap.data;
        if (k == null) return const Center(child: CircularProgressIndicator());
        return widget.child(k);
      },
    ),
  );
}

// ───────────────────────────── Book shelf ─────────────────────────────

String shelfTitle(BuildContext context, String id) {
  final l = context.l10n;
  return switch (id) {
    'adhkar' => l.kidsLearnShelfAdhkar,
    'aqeedah' => l.kidsLearnShelfAqeedah,
    'akhlaq' => l.kidsLearnShelfAkhlaq,
    'fiqh' => l.kidsLearnShelfFiqh,
    'quran' => l.kidsLearnShelfQuran,
    'stories' => l.kidsLearnShelfStories,
    'ramadan' => l.kidsLearnShelfRamadan,
    _ => l.kidsLearnShelfParents,
  };
}

/// «مكتبة كتب الأطفال»: shelves of covers; a book opens page by page.
class KidsBooksScreen extends StatelessWidget {
  const KidsBooksScreen({super.key, this.loader = loadKidsLearn});
  final Future<KidsLearnContent> Function() loader;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Frame(
      title: l.kidsLearnBooks,
      loader: loader,
      child: (k) => ReadableWidth(
        maxWidth: Adaptive.tabWidth,
        child: ListView(
          key: const Key('kidsBooks'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Text(l.kidsLearnBooksNote, style: Theme.of(context).textTheme.bodyMedium),
            ),
            for (final s in k.shelves)
              if (k.onShelf(s).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceMd,
                    DesignTokens.spaceLg,
                    DesignTokens.spaceXs,
                  ),
                  child: Text(
                    shelfTitle(context, s),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
                SizedBox(
                  height: 236,
                  child: ListView(
                    key: Key('kidsShelf.$s'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                    children: [for (final b in k.onShelf(s)) _BookCover(book: b, base: k.booksBase)],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book, required this.base});
  final KidsBook book;
  final String base;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: InkWell(
      key: Key('kidsBook.${book.id}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KidsBookScreen(book: book, base: base),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                book.cover,
                height: 160,
                width: 122,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(height: 160, color: Theme.of(context).colorScheme.surfaceContainerHighest),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.25),
            ),
            Text(context.l10n.kidsLearnPages(context.num(book.pages)), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Where a saved book lives: `<documents>/kids-books/<id>/<page>.webp`.
Future<Directory> kidsBookDir(int id) async {
  final d = await getApplicationDocumentsDirectory();
  return Directory('${d.path}/kids-books/$id');
}

Future<bool> kidsBookSaved(KidsBook b) async {
  try {
    final d = await kidsBookDir(b.id);
    return File('${d.path}/${b.pages}.webp').existsSync() && File('${d.path}/1.webp').existsSync();
  } catch (_) {
    return false;
  }
}

/// One book: its published pages, swiped like a book, pinch to zoom, saved for offline on request.
class KidsBookScreen extends StatefulWidget {
  const KidsBookScreen({super.key, required this.book, required this.base, this.client});
  final KidsBook book;
  final String base;
  final http.Client? client;

  @override
  State<KidsBookScreen> createState() => _KidsBookScreenState();
}

class _KidsBookScreenState extends State<KidsBookScreen> {
  final _pages = PageController();
  int _page = 1;
  Directory? _dir;
  bool _saved = false;
  double? _progress;
  bool _cancel = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final d = await kidsBookDir(widget.book.id);
      final saved = await kidsBookSaved(widget.book);
      if (mounted) setState(() => (_dir = d, _saved = saved));
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancel = true;
    _pages.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final d = _dir ?? await kidsBookDir(widget.book.id);
    await d.create(recursive: true);
    final client = widget.client ?? http.Client();
    setState(() => _progress = 0);
    try {
      for (var p = 1; p <= widget.book.pages; p++) {
        if (_cancel) return;
        final f = File('${d.path}/$p.webp');
        if (!f.existsSync()) {
          final res = await client.get(Uri.parse(widget.book.pageUrl(widget.base, p)));
          if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
          final part = File('${f.path}.part');
          await part.writeAsBytes(res.bodyBytes, flush: true);
          await part.rename(f.path);
        }
        if (mounted) setState(() => _progress = p / widget.book.pages);
      }
      if (mounted) setState(() => (_saved = true, _progress = null));
    } catch (_) {
      if (mounted) {
        setState(() => _progress = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.kidsLearnSaveFailed)));
      }
    } finally {
      if (widget.client == null) client.close();
    }
  }

  Future<void> _delete() async {
    final d = _dir;
    if (d != null && d.existsSync()) await d.delete(recursive: true);
    if (mounted) setState(() => _saved = false);
  }

  Widget _image(int p) {
    final d = _dir;
    final local = d == null ? null : File('${d.path}/$p.webp');
    final img = local != null && local.existsSync()
        ? Image.file(local, fit: BoxFit.contain)
        : Image.network(
            widget.book.pageUrl(widget.base, p),
            fit: BoxFit.contain,
            loadingBuilder: (c, child, ev) => ev == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (c, _, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Text(c.l10n.kidsLearnOffline, textAlign: TextAlign.center),
              ),
            ),
          );
    return InteractiveViewer(maxScale: 4, child: Center(child: img));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = widget.book;
    final p = _progress;
    return Scaffold(
      appBar: AppBar(
        title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (p != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, value: p > 0 ? p : null),
              ),
            )
          else
            IconButton(
              key: const Key('kidsBook.save'),
              tooltip: _saved ? l.kidsLearnDelete : l.kidsLearnSave,
              icon: Icon(
                _saved ? Icons.download_done : Icons.download_for_offline_outlined,
                color: _saved ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _saved ? _delete : _save,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('kidsBook.pages'),
              controller: _pages,
              itemCount: b.pages,
              onPageChanged: (i) => setState(() => _page = i + 1),
              itemBuilder: (_, i) => _image(i + 1),
            ),
          ),
          _PagerBar(
            label: l.kidsLearnPage(context.num(_page), context.num(b.pages)),
            onPrev: _page > 1 ? () => _pages.previousPage(duration: _turn, curve: Curves.easeOut) : null,
            onNext: _page < b.pages ? () => _pages.nextPage(duration: _turn, curve: Curves.easeOut) : null,
          ),
        ],
      ),
    );
  }
}

const _turn = Duration(milliseconds: 260);

/// «السابق · صفحة ٣ من ١٢ · التالي» under a picture pager.
class _PagerBar extends StatelessWidget {
  const _PagerBar({required this.label, this.onPrev, this.onNext, this.extra});
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceXs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?extra,
            Row(
              children: [
                TextButton.icon(
                  key: const Key('pager.prev'),
                  onPressed: onPrev,
                  icon: const RIcon(RIcons.prev),
                  label: Text(l.kidsLearnPrev),
                ),
                Expanded(child: Text(label, textAlign: TextAlign.center)),
                TextButton.icon(
                  key: const Key('pager.next'),
                  onPressed: onNext,
                  icon: const RIcon(RIcons.next),
                  label: Text(l.kidsLearnNext),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── احفظ حديث ─────────────────────────────

/// «احفظ حديث»: four levels from the book, with how many the child has memorised.
class KidsHadithScreen extends StatefulWidget {
  const KidsHadithScreen({super.key, this.loader = loadKidsLearn});
  final Future<KidsLearnContent> Function() loader;

  @override
  State<KidsHadithScreen> createState() => _KidsHadithScreenState();
}

class _KidsHadithScreenState extends State<KidsHadithScreen> {
  Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final s = await readMemorized();
    if (mounted) setState(() => _done = s);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Frame(
      title: l.kidsLearnHadith,
      loader: widget.loader,
      child: (k) => ReadableWidth(
        child: ListView(
          key: const Key('kidsHadith'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Text(l.kidsLearnHadithNote, style: Theme.of(context).textTheme.bodyMedium),
            ),
            for (final lv in k.levels)
              Builder(
                builder: (context) {
                  final got = _done.where(lv.contains).length;
                  return Card(
                    key: Key('kidsHadith.level${lv.level}'),
                    margin: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                      vertical: DesignTokens.spaceXs,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceLg,
                        vertical: DesignTokens.spaceSm,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Color(lv.color),
                        foregroundColor: Colors.white,
                        child: Text(context.num(lv.level), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      title: Text(
                        l.kidsLearnLevel(context.num(lv.level)),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.kidsLearnLevelSub(context.num(lv.from), context.num(lv.to))),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: got / lv.count,
                            color: Color(lv.color),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 2),
                          Text(l.kidsLearnProgress(context.num(got), context.num(lv.count))),
                        ],
                      ),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => KidsHadithLevelScreen(content: k, level: lv),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One level: the list, each hadith opening as a big card to read, repeat and mark «حفظته».
class KidsHadithLevelScreen extends StatefulWidget {
  const KidsHadithLevelScreen({super.key, required this.content, required this.level});
  final KidsLearnContent content;
  final HadithLevel level;

  @override
  State<KidsHadithLevelScreen> createState() => _KidsHadithLevelScreenState();
}

class _KidsHadithLevelScreenState extends State<KidsHadithLevelScreen> {
  Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    unawaited(readMemorized().then((s) => mounted ? setState(() => _done = s) : null));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lv = widget.level;
    return Scaffold(
      appBar: AppBar(title: Text(l.kidsLearnLevel(context.num(lv.level)))),
      body: ReadableWidth(
        child: ListView.builder(
          key: const Key('kidsHadith.list'),
          itemCount: lv.count,
          itemBuilder: (context, i) {
            final n = lv.from + i;
            final done = _done.contains(n);
            return ListTile(
              key: Key('kidsHadith.$n'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: done ? Color(lv.color) : Color(lv.color).withValues(alpha: 0.18),
                foregroundColor: done ? Colors.white : null,
                child: done
                    ? const Icon(Icons.check, size: 18)
                    : Text(context.num(n), style: const TextStyle(fontSize: 11)),
              ),
              title: Text(widget.content.hadithText(n), maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KidsHadithCardScreen(content: widget.content, level: lv, start: n),
                  ),
                );
                final s = await readMemorized();
                if (mounted) setState(() => _done = s);
              },
            );
          },
        ),
      ),
    );
  }
}

class KidsHadithCardScreen extends StatefulWidget {
  const KidsHadithCardScreen({super.key, required this.content, required this.level, required this.start});
  final KidsLearnContent content;
  final HadithLevel level;
  final int start;

  @override
  State<KidsHadithCardScreen> createState() => _KidsHadithCardScreenState();
}

class _KidsHadithCardScreenState extends State<KidsHadithCardScreen> {
  late final PageController _pages = PageController(initialPage: widget.start - widget.level.from);
  late int _n = widget.start;
  Set<int> _done = {};
  int _reads = 0;

  @override
  void initState() {
    super.initState();
    unawaited(readMemorized().then((s) => mounted ? setState(() => _done = s) : null));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final s = {..._done};
    if (!s.remove(_n)) s.add(_n);
    setState(() => _done = s);
    await writeMemorized(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lv = widget.level;
    final color = Color(lv.color);
    final done = _done.contains(_n);
    return Scaffold(
      appBar: AppBar(title: Text(l.kidsLearnHadithNo(context.num(_n)))),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('kidsHadith.cards'),
              controller: _pages,
              itemCount: lv.count,
              onPageChanged: (i) => setState(() => (_n = lv.from + i, _reads = 0)),
              itemBuilder: (context, i) => ReadableWidth(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SelectableText(
                      widget.content.hadithText(lv.from + i),
                      key: Key('kidsHadith.text${lv.from + i}'),
                      style: const TextStyle(fontSize: 22, height: 1.9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _PagerBar(
            label: l.kidsLearnHadithNo(context.num(_n)),
            onPrev: _n > lv.from ? () => _pages.previousPage(duration: _turn, curve: Curves.easeOut) : null,
            onNext: _n < lv.to ? () => _pages.nextPage(duration: _turn, curve: Curves.easeOut) : null,
            extra: Wrap(
              alignment: WrapAlignment.center,
              spacing: DesignTokens.spaceSm,
              children: [
                OutlinedButton.icon(
                  key: const Key('kidsHadith.repeat'),
                  onPressed: () => setState(() => _reads++),
                  icon: const RIcon(RIcons.repeat),
                  label: Text(l.kidsLearnReads(context.num(_reads))),
                ),
                FilledButton.icon(
                  key: const Key('kidsHadith.memorized'),
                  style: done ? FilledButton.styleFrom(backgroundColor: color) : null,
                  onPressed: _toggle,
                  icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(done ? l.kidsLearnMemorized : l.kidsLearnMarkMemorized),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Adhkar cards ─────────────────────────────

/// Today's key: cards finished today are stored per day, so the stars start fresh each morning.
String _today() {
  final d = DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

/// «بطاقات الأذكار»: the published cards (boys' or girls' edition), card by card.
class KidsCardsScreen extends StatefulWidget {
  const KidsCardsScreen({super.key, this.loader = loadKidsLearn});
  final Future<KidsLearnContent> Function() loader;

  @override
  State<KidsCardsScreen> createState() => _KidsCardsScreenState();
}

class _KidsCardsScreenState extends State<KidsCardsScreen> {
  final _pages = PageController();
  bool _girls = false;
  int _i = 0;
  Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final m = jsonDecode(p.getString(_cardsKey) ?? '{}') as Map<String, dynamic>;
      final today = m[_today()];
      if (mounted && today is List) setState(() => _done = {for (final x in today) x as int});
    } catch (_) {}
  }

  Future<void> _toggle(int page) async {
    final s = {..._done};
    if (!s.remove(page)) s.add(page);
    setState(() => _done = s);
    final p = await SharedPreferences.getInstance();
    await p.setString(_cardsKey, jsonEncode({_today(): s.toList()}));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Frame(
      title: l.kidsLearnCards,
      loader: widget.loader,
      child: (k) {
        final cards = k.cards;
        final page = cards[_i.clamp(0, cards.length - 1)];
        final done = _done.contains(page);
        final stars = cards.where(_done.contains).length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              child: SegmentedButton<bool>(
                key: const Key('kidsCards.edition'),
                segments: [
                  ButtonSegment(value: false, label: Text(l.kidsLearnBoys)),
                  ButtonSegment(value: true, label: Text(l.kidsLearnGirls)),
                ],
                selected: {_girls},
                onSelectionChanged: (s) => setState(() => _girls = s.first),
              ),
            ),
            if (stars > 0) Text('${'⭐' * stars.clamp(0, 8)}  ${l.kidsLearnCardsToday(context.num(stars))}'),
            Expanded(
              child: PageView.builder(
                key: const Key('kidsCards.pages'),
                controller: _pages,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: Image.asset('assets/kids/cards/${_girls ? 'g' : 'b'}${cards[i]}.webp', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            _PagerBar(
              label: l.kidsLearnPage(context.num(_i + 1), context.num(cards.length)),
              onPrev: _i > 0 ? () => _pages.previousPage(duration: _turn, curve: Curves.easeOut) : null,
              onNext: _i < cards.length - 1 ? () => _pages.nextPage(duration: _turn, curve: Curves.easeOut) : null,
              extra: FilledButton.icon(
                key: const Key('kidsCards.done'),
                onPressed: () => _toggle(page),
                icon: Icon(done ? Icons.star : Icons.star_border),
                label: Text(done ? l.kidsLearnCardDone : l.kidsLearnCardMark),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────────── Wudu / salah steps ─────────────────────────────

/// «أتعلم الوضوء» / «أتعلم الصلاة»: the book's pictured steps, one by one.
class KidsStepsScreen extends StatefulWidget {
  const KidsStepsScreen({super.key, required this.salah, this.loader = loadKidsLearn});
  final bool salah;
  final Future<KidsLearnContent> Function() loader;

  @override
  State<KidsStepsScreen> createState() => _KidsStepsScreenState();
}

class _KidsStepsScreenState extends State<KidsStepsScreen> {
  final _pages = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Frame(
      title: widget.salah ? l.kidsLearnSalah : l.kidsLearnWudu,
      loader: widget.loader,
      child: (k) {
        final pages = widget.salah ? k.salah : k.wudu;
        final last = _i == pages.length - 1;
        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: Key(widget.salah ? 'kidsSalah.pages' : 'kidsWudu.pages'),
                controller: _pages,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(child: Image.asset('assets/kids/wudu/${pages[i]}.webp', fit: BoxFit.contain)),
                ),
              ),
            ),
            _PagerBar(
              label: l.kidsLearnStep(context.num(_i + 1), context.num(pages.length)),
              onPrev: _i > 0 ? () => _pages.previousPage(duration: _turn, curve: Curves.easeOut) : null,
              onNext: !last ? () => _pages.nextPage(duration: _turn, curve: Curves.easeOut) : null,
              extra: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (last)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        l.kidsLearnStepsDone,
                        key: const Key('kidsSteps.done'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  Text(l.kidsLearnCredit(k.stepsCredit), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
