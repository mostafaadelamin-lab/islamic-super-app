import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../theme/design_tokens.dart';
import 'ayah_sheet.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'widgets.dart';

/// Reads one surah, ayah by ayah, optionally starting at [initialAyah]
/// (which is highlighted and scrolled to the top).
class SurahReaderScreen extends StatefulWidget {
  const SurahReaderScreen({super.key, required this.surah, this.initialAyah});
  final int surah;
  final int? initialAyah;

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final _centerKey = UniqueKey();
  late int _start;
  late AyahRef _current;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final s = context.services.content.quran.surah(widget.surah);
    final a = widget.initialAyah;
    _start = a != null && a >= 1 && a <= s.ayahCount ? a : 1;
    _current = AyahRef(widget.surah, _start);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.services.settings.setLastRead(_current);
    });
  }

  void _select(AyahRef r) {
    setState(() => _current = r);
    context.services.settings.setLastRead(r);
  }

  /// Selects the tapped ayah and opens its sheet (tafsir and actions).
  Future<void> _onAyahTap(AyahRef r) async {
    _select(r);
    await showAyahSheet(context, r, readAsList: false);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = services.content.quran.surah(widget.surah);
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([services.settings, services.bookmarks]),
      builder: (context, _) {
        final showEn = services.settings.showTranslation;
        Widget ayahTile(int i) => _AyahTile(
          ref: AyahRef(s.n, i + 1),
          text: s.ayahs[i],
          translation: showEn ? s.en[i] : null,
          highlighted: widget.initialAyah != null && i + 1 == _current.ayah,
          onTap: () => _onAyahTap(AyahRef(s.n, i + 1)),
        );

        Widget tile(int i) {
          final t = ayahTile(i);
          if (i != 0 || !hasBasmalaLine(s.n)) return t;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                child: BasmalaLine(surah: s.n),
              ),
              t,
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(surahLabel(context, s)),
            actions: [
              IconButton(
                key: const Key('toggleTranslation'),
                tooltip: l.quranShowTranslation,
                isSelected: showEn,
                icon: const Icon(Icons.translate_outlined),
                selectedIcon: const Icon(Icons.translate),
                onPressed: () => services.settings.setShowTranslation(!showEn),
              ),
              IconButton(
                key: const Key('openInMushaf'),
                tooltip: l.quranOpenMushaf,
                icon: const Icon(Icons.chrome_reader_mode),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PageReaderScreen(initialPage: services.content.quran.pageOf(_current)),
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            key: const Key('surahReader'),
            center: _centerKey,
            slivers: [
              SliverList(delegate: SliverChildBuilderDelegate((c, i) => tile(_start - 2 - i), childCount: _start - 1)),
              SliverList(
                key: _centerKey,
                delegate: SliverChildBuilderDelegate(
                  (c, i) => tile(_start - 1 + i),
                  childCount: s.ayahCount - _start + 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ref,
    required this.text,
    required this.translation,
    required this.highlighted,
    required this.onTap,
  });

  final AyahRef ref;
  final String text;
  final String? translation;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final l = context.l10n;
    final marked = services.bookmarks.isBookmarked(ref);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: Key('ayah-${ref.surah}-${ref.ayah}'),
      color: highlighted ? scheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.quranAyahN(context.num(ref.ayah)),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    key: Key('bookmark-${ref.surah}-${ref.ayah}'),
                    tooltip: marked ? l.quranRemoveBookmark : l.quranBookmark,
                    isSelected: marked,
                    icon: const Icon(Icons.bookmark_border),
                    selectedIcon: const Icon(Icons.bookmark),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final added = await services.bookmarks.toggle(ref);
                      messenger
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(added ? l.quranBookmarked : l.quranBookmarkRemoved),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                    },
                  ),
                ],
              ),
              QuranText(text, ayahNumber: ref.ayah),
              if (translation != null)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                  child: Text(
                    translation!,
                    key: Key('en-${ref.surah}-${ref.ayah}'),
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
