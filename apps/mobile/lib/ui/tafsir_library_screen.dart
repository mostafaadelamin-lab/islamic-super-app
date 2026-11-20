import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/tafsir_books.dart';
import '../domain/quran.dart';
import '../domain/tafsir_books.dart';
import '../theme/design_tokens.dart';
import 'ayah_study.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'adaptive.dart';
import 'ayah_sheet.dart' show stepAyah;
import 'widgets.dart';

/// «التفسير» in More (owner 2026-11-20): every tafsir book to read ayah by ayah (with the gharib, i'rab, sarf,
/// balagha and fawa'id tabs), the books side by side for one ayah, search inside a book, and downloads for
/// reading without the internet.
class TafsirLibraryScreen extends StatelessWidget {
  const TafsirLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void open(Widget Function() screen) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen()));
    return Scaffold(
      appBar: AppBar(title: Text(l.tafsirLibTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: TafsirBooks.instance,
          builder: (context, _) => ListView(
            key: const Key('tafsirLibList'),
            children: [
              SectionCard(
                children: [
                  ListTile(
                    key: const Key('tafsirLib.compare'),
                    leading: const RIconBadge(RIcons.openBook),
                    title: Text(l.tafsirLibCompare),
                    subtitle: Text(l.tafsirLibCompareSub),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () => open(() => const TafsirCompareScreen()),
                  ),
                  ListTile(
                    key: const Key('tafsirLib.search'),
                    leading: const RIconBadge(RIcons.search),
                    title: Text(l.tafsirLibSearch),
                    subtitle: Text(l.tafsirLibSearchSub),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () => open(() => const TafsirSearchScreen()),
                  ),
                ],
              ),
              _Heading(l.tafsirLibBooks),
              SectionCard(
                children: [
                  for (final b in TafsirBookId.values)
                    _BookTile(
                      key: Key('tafsirLib.book.${b.id}'),
                      title: b.nameAr,
                      subtitle: '${b.authorAr} · ${_lengthLabel(context, b.length)}',
                      storeId: b == TafsirBookId.muyassar ? null : b.id,
                      onOpen: () => open(() => TafsirReadScreen(book: b, tab: StudyTab.tafsir)),
                    ),
                  _BookTile(
                    key: const Key('tafsirLib.book.irab'),
                    title: l.tafsirLibIrabName,
                    subtitle: l.tafsirLibIrabSub,
                    storeId: TafsirBooks.irabId,
                    onOpen: () => open(() => const TafsirReadScreen(book: TafsirBookId.muyassar, tab: StudyTab.irab)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Text(l.tafsirLibDownloadsNote, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _lengthLabel(BuildContext context, BookLength len) {
  final l = context.l10n;
  return switch (len) {
    BookLength.short => l.tafsirLibLenShort,
    BookLength.medium => l.tafsirLibLenMedium,
    BookLength.long => l.tafsirLibLenLong,
  };
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// A book with its download state (al-Muyassar is in the app: [storeId] null).
class _BookTile extends StatelessWidget {
  const _BookTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.storeId,
    required this.onOpen,
  });
  final String title;
  final String subtitle;
  final String? storeId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = TafsirBooks.instance;
    final id = storeId;
    Widget trailing;
    if (id == null) {
      trailing = Text(l.tafsirLibInApp, style: Theme.of(context).textTheme.bodySmall);
    } else if (store.progress[id] case final done?) {
      trailing = SizedBox(
        width: 44,
        child: Tooltip(
          message: l.tafsirLibDownloading(context.num(done)),
          child: CircularProgressIndicator(value: done / 114, strokeWidth: 3),
        ),
      );
    } else {
      trailing = FutureBuilder<bool>(
        future: store.isSaved(id),
        builder: (context, snap) => snap.data == true
            ? IconButton(
                key: Key('tafsirLib.remove.$id'),
                tooltip: l.tafsirLibRemove,
                icon: const Icon(Icons.download_done),
                onPressed: () => store.remove(id),
              )
            : IconButton(
                key: Key('tafsirLib.download.$id'),
                tooltip: store.failed.contains(id) ? l.tafsirLibFailed : l.tafsirLibDownload,
                icon: Icon(store.failed.contains(id) ? Icons.error_outline : Icons.download),
                onPressed: () => store.download(id),
              ),
      );
    }
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onOpen,
    );
  }
}

/// Surah and ayah pickers.
class AyahPicker extends StatelessWidget {
  const AyahPicker({super.key, required this.ref, required this.onChanged});
  final AyahRef ref;
  final ValueChanged<AyahRef> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.services.content.quran;
    final l = context.l10n;
    final count = q.surah(ref.surah).ayahCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              key: const Key('pickSurah'),
              initialValue: ref.surah,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.tafsirLibSurah, isDense: true),
              items: [
                for (final s in q.surahs)
                  DropdownMenuItem(
                    value: s.n,
                    child: Text('${context.num(s.n)}. ${context.isArabic ? s.nameAr : s.nameEn}'),
                  ),
              ],
              onChanged: (v) => v == null ? null : onChanged(AyahRef(v, 1)),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              key: ValueKey('pickAyah-${ref.surah}'),
              initialValue: ref.ayah,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.tafsirLibAyah, isDense: true),
              items: [for (var a = 1; a <= count; a++) DropdownMenuItem(value: a, child: Text(context.num(a)))],
              onChanged: (v) => v == null ? null : onChanged(AyahRef(ref.surah, v)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One book (or «الجدول») ayah by ayah.
class TafsirReadScreen extends StatefulWidget {
  const TafsirReadScreen({super.key, required this.book, required this.tab, this.initial = const AyahRef(1, 1)});
  final TafsirBookId book;
  final StudyTab tab;
  final AyahRef initial;

  @override
  State<TafsirReadScreen> createState() => _TafsirReadScreenState();
}

class _TafsirReadScreenState extends State<TafsirReadScreen> {
  late AyahRef _ref = widget.initial;
  late final _choice = ValueNotifier<(TafsirBookId, StudyTab)>((widget.book, widget.tab));

  @override
  void dispose() {
    _choice.dispose();
    super.dispose();
  }

  void _step(int d) {
    final next = stepAyah(context.services.content.quran, _ref, d);
    if (next != null) setState(() => _ref = next);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = context.services.content.quran;
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: _choice,
          builder: (context, c, _) =>
              Text(c.$2 == StudyTab.tafsir ? c.$1.nameAr : l.tafsirLibIrabName, overflow: TextOverflow.ellipsis),
        ),
      ),
      body: ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AyahPicker(ref: _ref, onChanged: (r) => setState(() => _ref = r)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
                child: AyahStudyCard(key: const Key('libStudy'), ref: _ref, choice: _choice),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      key: const Key('libPrev'),
                      onPressed: stepAyah(q, _ref, -1) == null ? null : () => _step(-1),
                      icon: const RIcon(RIcons.chevron),
                      label: Text(l.tafsirPrev),
                    ),
                    TextButton.icon(
                      key: const Key('libNext'),
                      onPressed: stepAyah(q, _ref, 1) == null ? null : () => _step(1),
                      icon: const RIcon(RIcons.chevronForward),
                      label: Text(l.tafsirNext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every tafsir of one ayah, one under the other.
class TafsirCompareScreen extends StatefulWidget {
  const TafsirCompareScreen({super.key});

  @override
  State<TafsirCompareScreen> createState() => _TafsirCompareScreenState();
}

class _TafsirCompareScreenState extends State<TafsirCompareScreen> {
  AyahRef _ref = const AyahRef(1, 1);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.tafsirLibCompare)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('compareList'),
          children: [
            AyahPicker(ref: _ref, onChanged: (r) => setState(() => _ref = r)),
            for (final b in TafsirBookId.values) _CompareCard(key: ValueKey('${b.id}-$_ref'), book: b, ref: _ref),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatefulWidget {
  const _CompareCard({super.key, required this.book, required this.ref});
  final TafsirBookId book;
  final AyahRef ref;

  @override
  State<_CompareCard> createState() => _CompareCardState();
}

class _CompareCardState extends State<_CompareCard> {
  static const preview = 600;
  late Future<StudyBody> _future = loadStudy(context.services, widget.ref, widget.book, StudyTab.tafsir);
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: Key('compare.${widget.book.id}'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: BorderDirectional(start: BorderSide(color: scheme.tertiary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.book.nameAr,
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              Text(_lengthLabel(context, widget.book.length), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          FutureBuilder<StudyBody>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return TextButton(
                  onPressed: () {
                    final next = loadStudy(context.services, widget.ref, widget.book, StudyTab.tafsir);
                    setState(() {
                      _future = next;
                    });
                  },
                  child: Text('${l.tafsirError} ${l.studyRetry}'),
                );
              }
              final body = snap.data;
              if (body is! StudyText) return const LinearProgressIndicator();
              final long = body.text.length > preview;
              final text = long && !_open ? '${body.text.substring(0, preview)} …' : body.text;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookTextView(text, quotes: body.quotes, size: 16),
                  Row(
                    children: [
                      if (long)
                        TextButton(
                          key: Key('compareMore.${widget.book.id}'),
                          onPressed: () => setState(() => _open = !_open),
                          child: Text(_open ? l.tafsirLibLess : l.tafsirLibMore),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TafsirReadScreen(book: widget.book, tab: StudyTab.tafsir, initial: widget.ref),
                          ),
                        ),
                        child: Text(l.tafsirLibReadBook),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Search inside one book (al-Muyassar in the app; the others once downloaded).
class TafsirSearchScreen extends StatefulWidget {
  const TafsirSearchScreen({super.key});

  @override
  State<TafsirSearchScreen> createState() => _TafsirSearchScreenState();
}

class _TafsirSearchScreenState extends State<TafsirSearchScreen> {
  final _query = TextEditingController();
  TafsirBookId _book = TafsirBookId.muyassar;
  Future<List<SearchHit>?>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<List<SearchHit>?> _search(AppServices s, TafsirBookId book, String q) async {
    final List<List<BookSection>> surahs;
    if (book == TafsirBookId.muyassar) {
      final t = await s.tafsir.load();
      surahs = [
        for (final entries in t.surahs)
          [for (var a = 0; a < entries.length; a++) BookSection(a + 1, a + 1, entries[a])],
      ];
    } else {
      if (!await TafsirBooks.instance.isSaved(book.id)) return null; // needs the download
      surahs = await TafsirBooks.instance.wholeBook(book);
    }
    return searchSections(surahs, q);
  }

  void _run() {
    if (_query.text.trim().length < minQueryLetters) return;
    final results = _search(context.services, _book, _query.text);
    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tafsirLibSearch)),
      body: ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
              child: TextField(
                key: const Key('tafsirSearchField'),
                controller: _query,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _run(),
                decoration: InputDecoration(
                  hintText: l.tafsirLibSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    key: const Key('tafsirSearchGo'),
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _run,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                children: [
                  for (final b in TafsirBookId.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        key: Key('searchBook.${b.id}'),
                        label: Text(context.isArabic ? b.shortAr : b.nameEn),
                        selected: b == _book,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() => _book = b);
                          _run();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _results == null
                  ? const SizedBox.shrink()
                  : FutureBuilder<List<SearchHit>?>(
                      future: _results,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) return Center(child: Text(l.tafsirError));
                        final hits = snap.data;
                        if (hits == null) {
                          return ListenableBuilder(
                            listenable: TafsirBooks.instance,
                            builder: (context, _) {
                              final done = TafsirBooks.instance.progress[_book.id];
                              return Padding(
                                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                                child: Column(
                                  key: const Key('searchNeedsDownload'),
                                  children: [
                                    Text(l.tafsirLibSearchNeedsDownload, textAlign: TextAlign.center),
                                    const SizedBox(height: DesignTokens.spaceSm),
                                    if (done != null)
                                      Text(l.tafsirLibDownloading(context.num(done)))
                                    else
                                      FilledButton.icon(
                                        key: const Key('searchDownload'),
                                        onPressed: () async {
                                          if (await TafsirBooks.instance.download(_book.id)) _run();
                                        },
                                        icon: const Icon(Icons.download),
                                        label: Text(l.tafsirLibDownload),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return ListView(
                          key: const Key('searchHits'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                              child: Text(
                                l.tafsirLibResults(context.num(hits.length)),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            for (final h in hits)
                              ListTile(
                                key: Key('hit-${h.surah}-${h.from}'),
                                title: Text(
                                  ayahLabel(context, AyahRef(h.surah, h.from)),
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: h.before),
                                      TextSpan(
                                        text: h.match,
                                        style: TextStyle(backgroundColor: theme.colorScheme.tertiaryContainer),
                                      ),
                                      TextSpan(text: h.after),
                                    ],
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => TafsirReadScreen(
                                      book: _book,
                                      tab: StudyTab.tafsir,
                                      initial: AyahRef(h.surah, h.from),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
