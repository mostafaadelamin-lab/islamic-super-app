import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/tafsir_books.dart';
import '../domain/quran.dart';
import '../domain/tafsir_books.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'review_notice.dart';

/// The book and tab chosen in the Mushaf (owner 2026-11-20): al-Muyassar and «التفسير» each time the app
/// starts, kept while it runs so that the next ayah keeps the reader's choice.
final studyChoice = ValueNotifier<(TafsirBookId, StudyTab)>((TafsirBookId.muyassar, StudyTab.tafsir));

/// What the card shows for one ayah.
sealed class StudyBody {
  const StudyBody();
}

class StudyText extends StudyBody {
  const StudyText(this.text, {this.notes = '', this.from = 0, this.to = 0, this.quotes = true});
  final String text;
  final String notes;
  final int from;
  final int to;

  /// Colour the Quran quotes (﴿…﴾); off for al-Muyassar, which is shown as it always was.
  final bool quotes;
}

class StudyWords extends StudyBody {
  const StudyWords(this.words);
  final List<({String word, String meaning})> words;
}

class StudyEmpty extends StudyBody {
  const StudyEmpty();
}

Future<StudyBody> loadStudy(AppServices s, AyahRef ref, TafsirBookId book, StudyTab tab) async {
  switch (tab) {
    case StudyTab.tafsir:
      if (book == TafsirBookId.muyassar) {
        final t = (await s.tafsir.load()).text(ref.surah, ref.ayah);
        if (t == null) throw RangeError('no tafsir for $ref');
        return StudyText(t, quotes: false);
      }
      final sec = sectionFor(await TafsirBooks.instance.surah(book, ref.surah), ref.ayah, (x) => (x.from, x.to));
      return StudyText(sec.text, notes: sec.notes, from: sec.from, to: sec.to);
    case StudyTab.gharib:
      final words = (await s.wordMeanings.load()).words(ref.surah, ref.ayah);
      return words.isEmpty ? const StudyEmpty() : StudyWords(words);
    case StudyTab.irab || StudyTab.sarf || StudyTab.balagha || StudyTab.fawaid:
      final sec = sectionFor(await TafsirBooks.instance.irabSurah(ref.surah), ref.ayah, (x) => (x.from, x.to));
      final part = sec.part(tab);
      return part.isEmpty ? const StudyEmpty() : StudyText(part, from: sec.from, to: sec.to);
  }
}

String studyTabLabel(BuildContext context, StudyTab t) {
  final l = context.l10n;
  return switch (t) {
    StudyTab.tafsir => l.studyTafsir,
    StudyTab.gharib => l.studyGharib,
    StudyTab.irab => l.studyIrab,
    StudyTab.sarf => l.studySarf,
    StudyTab.balagha => l.studyBalagha,
    StudyTab.fawaid => l.studyFawaid,
  };
}

/// A book's text with its Quran quotes in the Quran colour.
class BookTextView extends StatelessWidget {
  const BookTextView(this.text, {super.key, this.textKey, this.quotes = true, this.size = 17, this.muted = false});
  final String text;

  /// Key of the Text itself (tests read its data).
  final Key? textKey;
  final bool quotes;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = duaStyle(context, size: size).copyWith(color: muted ? scheme.onSurfaceVariant : null);
    if (!quotes) return Text(text, key: textKey, textDirection: TextDirection.rtl, style: base);
    final spans = <TextSpan>[];
    var at = 0;
    for (final m in quoteRe.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      spans.add(
        TextSpan(
          text: m[0],
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        ),
      );
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      key: textKey,
      textDirection: TextDirection.rtl,
      style: base,
    );
  }
}

/// The tafsir of one ayah (al-Muyassar by default, or another book the reader picks) and its studies
/// (gharib, i'rab, sarf, balagha, fawa'id), each shown verbatim (owner 2026-11-20).
class AyahStudyCard extends StatefulWidget {
  const AyahStudyCard({super.key, required this.ref, this.choice});
  final AyahRef ref;

  /// The choice to follow (the library has its own); the Mushaf's [studyChoice] when null.
  final ValueNotifier<(TafsirBookId, StudyTab)>? choice;

  @override
  State<AyahStudyCard> createState() => _AyahStudyCardState();
}

class _AyahStudyCardState extends State<AyahStudyCard> {
  Future<StudyBody>? _future;
  String _key = '';

  ValueNotifier<(TafsirBookId, StudyTab)> get _choice => widget.choice ?? studyChoice;

  @override
  void initState() {
    super.initState();
    _choice.addListener(_changed);
  }

  @override
  void didUpdateWidget(AyahStudyCard old) {
    super.didUpdateWidget(old);
    if (old.choice != widget.choice) {
      (old.choice ?? studyChoice).removeListener(_changed);
      _choice.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _choice.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<StudyBody> _load(BuildContext context, {bool retry = false}) {
    final (book, tab) = _choice.value;
    final key = '${tab.name}/${book.id}/${widget.ref.surah}:${widget.ref.ayah}';
    if (retry || key != _key || _future == null) {
      _key = key;
      _future = loadStudy(context.services, widget.ref, book, tab);
    }
    return _future!;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (book, tab) = _choice.value;
    final future = _load(context);
    final title = switch (tab) {
      StudyTab.tafsir when book == TafsirBookId.muyassar => l.tafsirTitle,
      StudyTab.tafsir => context.isArabic ? book.nameAr : '${book.nameEn} (${book.nameAr})',
      _ => studyTabLabel(context, tab),
    };
    final source = switch (tab) {
      StudyTab.tafsir when book == TafsirBookId.muyassar => l.tafsirSource,
      StudyTab.tafsir => book.authorAr,
      StudyTab.gharib => l.studyGharibBook,
      _ => l.studyIrabBook,
    };
    Widget chip(Key key, String label, bool on, VoidCallback tap) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: on,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => tap(),
      ),
    );
    return Container(
      key: const Key('tafsirCard'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            key: const Key('studyTabs'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in StudyTab.values)
                  chip(Key('studyTab.${t.name}'), studyTabLabel(context, t), t == tab, () => _choice.value = (book, t)),
              ],
            ),
          ),
          if (tab == StudyTab.tafsir)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
              child: SingleChildScrollView(
                key: const Key('tafsirBooks'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final b in TafsirBookId.values)
                      chip(
                        Key('tafsirBook.${b.id}'),
                        context.isArabic ? b.shortAr : b.nameEn,
                        b == book,
                        () => _choice.value = (b, tab),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.spaceSm),
          Row(
            children: [
              RIcon(RIcons.quran, size: 20, color: scheme.primary),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Text(
                  title,
                  key: const Key('tafsirTitle'),
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(
            source,
            key: const Key('tafsirSource'),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!context.isArabic)
            Text(
              l.tafsirArabicOnly,
              key: const Key('tafsirArabicOnly'),
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: DesignTokens.spaceSm),
          Flexible(
            child: FutureBuilder<StudyBody>(
              key: ValueKey(_key),
              future: future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.tafsirError,
                          key: const Key('tafsirError'),
                          style: TextStyle(color: scheme.error),
                        ),
                        TextButton(
                          key: const Key('tafsirRetry'),
                          onPressed: () {
                            _load(context, retry: true);
                            setState(() {});
                          },
                          child: Text(l.studyRetry),
                        ),
                      ],
                    ),
                  );
                }
                final body = snap.data;
                if (body == null) {
                  return Row(
                    key: const Key('tafsirLoading'),
                    children: [
                      const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(child: Text(l.tafsirLoading)),
                    ],
                  );
                }
                return SingleChildScrollView(key: const Key('tafsirScroll'), child: _body(context, body, tab));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, StudyBody body, StudyTab tab) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    switch (body) {
      case StudyEmpty():
        return Text(
          tab == StudyTab.gharib ? l.studyNoGharib : l.studyNoPart(studyTabLabel(context, tab)),
          key: const Key('studyEmpty'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        );
      case StudyWords(:final words):
        return Column(
          key: const Key('studyWords'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in words)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${w.word}: ',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: w.meaning),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  style: duaStyle(context, size: 17),
                ),
              ),
          ],
        );
      case StudyText():
        final surah = context.services.content.quran.surah(widget.ref.surah);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (body.from != body.to)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
                child: Text(
                  l.studyRange(
                    context.num(body.from),
                    context.num(body.to),
                    context.isArabic ? surah.nameAr : surah.nameEn,
                  ),
                  key: const Key('tafsirRange'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            BookTextView(body.text, textKey: const Key('tafsirText'), quotes: body.quotes),
            if (body.notes.isNotEmpty)
              ExpansionTile(
                key: const Key('tafsirNotes'),
                tilePadding: EdgeInsets.zero,
                title: Text(l.studyNotes, style: Theme.of(context).textTheme.bodySmall),
                children: [BookTextView(body.notes, quotes: false, size: 15, muted: true)],
              ),
          ],
        );
    }
  }
}
