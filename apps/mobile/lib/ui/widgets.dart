import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'surah_reader_screen.dart';

/// Quran text for display. The render map is applied here, to the string
/// passed to [Text] only — the stored ayah string is never modified.
class QuranText extends StatelessWidget {
  const QuranText(this.text, {super.key, this.ayahNumber, this.size, this.maxLines, this.textAlign = TextAlign.start});
  final int? maxLines;
  final String text;
  final int? ayahNumber;
  final double? size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final display = s.content.renderMap.forDisplay(text);
    final n = ayahNumber;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) => Text(
        n == null ? display : '$display ${ayahMarker(n)}',
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: AppTheme.quran(context, size ?? s.settings.quranFontSize),
      ),
    );
  }
}

/// Whether a surah opens with the unnumbered basmala line (all but 1 and 9).
bool hasBasmalaLine(int surah) => surah != 1 && surah != 9;

/// The unnumbered basmala shown before a surah, as in the printed Mushaf.
/// Its text is the canonical 1:1 string (display map applied by [QuranText]);
/// it carries no ayah number and is not bookmarkable.
class BasmalaLine extends StatelessWidget {
  const BasmalaLine({super.key, required this.surah});
  final int surah;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key('basmala-$surah'),
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
    child: QuranText(context.services.content.quran.text(const AyahRef(1, 1)), textAlign: TextAlign.center),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.title});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
              child: Text(title!, style: Theme.of(context).textTheme.titleMedium),
            ),
          ...children,
        ],
      ),
    ),
  );
}

/// "Continue reading" tile, shown when a last position exists.
class ContinueReadingTile extends StatelessWidget {
  const ContinueReadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) {
        final r = s.settings.lastRead;
        final l = context.l10n;
        if (r == null) {
          return ListTile(
            leading: const Icon(Icons.auto_stories),
            title: Text(l.quranStartReading),
            subtitle: Text(surahLabel(context, s.content.quran.surah(1))),
            onTap: () => openSurah(context, 1),
          );
        }
        return ListTile(
          leading: const Icon(Icons.auto_stories),
          title: Text(l.quranContinueReading),
          subtitle: Text(ayahLabel(context, r)),
          onTap: () => openSurah(context, r.surah, ayah: r.ayah),
        );
      },
    );
  }
}

String surahName(BuildContext context, Surah s) => context.isArabic ? s.nameAr : s.translit;

String surahLabel(BuildContext context, Surah s) =>
    context.isArabic ? 'سورة ${s.nameAr}' : '${s.translit} (${s.nameEn})';

String ayahLabel(BuildContext context, AyahRef r) {
  final s = context.services.content.quran.surah(r.surah);
  return context.l10n.quranSurahAyah(surahName(context, s), context.num(r.ayah));
}

Future<void> openSurah(BuildContext context, int surah, {int? ayah}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => SurahReaderScreen(surah: surah, initialAyah: ayah),
  ),
);

/// Opens the Mushaf at the page of [r], with that ayah highlighted.
Future<void> openMushafAt(BuildContext context, AyahRef r) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => PageReaderScreen(initialPage: context.services.content.quran.pageOf(r), highlight: r),
  ),
);
