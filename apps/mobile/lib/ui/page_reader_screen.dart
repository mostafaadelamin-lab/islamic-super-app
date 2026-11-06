import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/text.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

/// Madinah Mushaf (1405H) page reader, pages 1..604, using pages.v1.json.
class PageReaderScreen extends StatefulWidget {
  const PageReaderScreen({super.key, this.initialPage = 1});
  final int initialPage;

  @override
  State<PageReaderScreen> createState() => PageReaderScreenState();
}

class PageReaderScreenState extends State<PageReaderScreen> {
  late final PageController _controller;
  late int _page;
  final _input = TextEditingController();
  String? _error;

  int get page => _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, 604);
    _controller = PageController(initialPage: _page - 1);
    // A message left over from the previous screen (e.g. "Bookmarked") floats over
    // this screen's bottom controls on small phones; clear it when the reader opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  int get _count => context.services.content.quran.pageCount;

  void _onPageChanged(int index) {
    setState(() => _page = index + 1);
    final q = context.services.content.quran;
    context.services.settings.setLastRead(q.page(_page).start);
  }

  void _jump(int p) {
    if (p < 1 || p > _count) return;
    _controller.jumpToPage(p - 1);
  }

  void _go() {
    final p = parsePageNumber(_input.text, max: _count);
    if (p == null) {
      setState(() => _error = context.l10n.quranPageInvalid);
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    _jump(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.quranPages)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('mushafPageView'),
              controller: _controller,
              itemCount: _count,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _MushafPage(page: i + 1),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: DesignTokens.spaceXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    key: const Key('prevPage'),
                    tooltip: l.quranPrevPage,
                    icon: const Icon(Icons.navigate_before),
                    onPressed: _page > 1 ? () => _jump(_page - 1) : null,
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('goToPageField'),
                      controller: _input,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _go(),
                      decoration: InputDecoration(
                        labelText: l.quranGoToPage,
                        hintText: l.quranPageNumberHint,
                        errorText: _error,
                        errorMaxLines: 3,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceSm),
                  FilledButton(key: const Key('goToPageButton'), onPressed: _go, child: Text(l.quranGo)),
                  IconButton(
                    key: const Key('nextPage'),
                    tooltip: l.quranNextPage,
                    icon: const Icon(Icons.navigate_next),
                    onPressed: _page < _count ? () => _jump(_page + 1) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final q = s.content.quran;
    final l = context.l10n;
    final refs = q.ayahsOnPage(page);
    final names = q.surahsOnPage(page).map((n) => surahName(context, q.surah(n))).join(' · ');
    final paper = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.dark['paper']!
        : DesignTokens.light['paper']!;
    return Container(
      key: Key('mushafPage-$page'),
      color: paper,
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Semantics(
            header: true,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: DesignTokens.spaceMd,
              children: [
                Text(l.quranPage(context.num(page)), key: const Key('pageHeader')),
                Text(l.quranJuz(context.num(q.juzOfPage(page)))),
                Text(names),
              ],
            ),
          ),
          const Divider(),
          for (final r in refs) ...[
            if (r.ayah == 1)
              Padding(
                key: Key('surahBanner-${r.surah}'),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.tertiary),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Text(
                    'سورة ${q.surah(r.surah).nameAr}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            if (r.ayah == 1 && hasBasmalaLine(r.surah)) BasmalaLine(surah: r.surah),
            QuranText(
              q.text(r),
              key: Key('pageAyah-${r.surah}-${r.ayah}'),
              ayahNumber: r.ayah,
              textAlign: TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }
}
