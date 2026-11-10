import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../data/settings.dart';
import '../domain/page_khatma.dart';
import '../domain/quran.dart';
import '../theme/design_tokens.dart';
import 'ayah_sheet.dart';
import 'bookmarks_screen.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart';
import 'quran_index_entry.dart';
import 'reader_widgets.dart';
import 'search_screen.dart';

/// Madinah Mushaf (1405H) reader: tabs المصحف / الآيات / التفسير; 604 pages of
/// 15 lines turned like a book (RTL: swipe right for the next page); a
/// floating recitation card; the page slider; and the bottom bar (index,
/// bookmarks, khatma, search). Tapping an ayah opens its sheet (listen, tafsir,
/// bookmark, copy). With "Listen with tafsir" the Mushaf tab splits in two:
/// the ayah being recited and its tafsir.
class PageReaderScreen extends StatefulWidget {
  const PageReaderScreen({super.key, this.initialPage = 1, this.highlight});
  final int initialPage;

  /// Ayah to highlight when the page opens (e.g. from search or a bookmark).
  final AyahRef? highlight;

  @override
  State<PageReaderScreen> createState() => PageReaderScreenState();
}

class PageReaderScreenState extends State<PageReaderScreen> {
  late PageController _controller;
  late int _page;
  AyahRef? _selected;
  int? _lastAudioPage;
  double? _sliderValue;
  RecitationController? _recitation;
  ReaderTab _tab = ReaderTab.mushaf;
  Timer? _khatmaTimer;
  bool _controls = true;

  int get page => _page;
  AyahRef? get selected => _selected;
  ReaderTab get tab => _tab;
  bool get controlsVisible => _controls;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, 604);
    _selected = widget.highlight;
    _controller = PageController(initialPage: _page - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A message left over from the previous screen (e.g. "Bookmarked") floats over
      // this screen's bottom controls on small phones; clear it when the reader opens.
      ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
      _recitation = context.services.recitation..addListener(_onRecitation);
      _lastAudioPage = _recitation!.currentPage;
      _scheduleKhatma();
    });
  }

  @override
  void dispose() {
    _khatmaTimer?.cancel();
    _recitation?.removeListener(_onRecitation);
    _controller.dispose();
    super.dispose();
  }

  int get _count => context.services.content.quran.pageCount;

  /// Khatma: the page counts as read once it stayed open for [khatmaDwell].
  void _scheduleKhatma() {
    _khatmaTimer?.cancel();
    final settings = context.services.settings;
    if (settings.khatma == null) return;
    final p = _page;
    _khatmaTimer = Timer(khatmaDwell, () => unawaited(settings.markKhatmaPage(p)));
  }

  /// Turns to the page of the ayah being recited when it moves to a new page.
  void _onRecitation() {
    final p = _recitation?.currentPage;
    if (p == null || p == _lastAudioPage) {
      _lastAudioPage = p;
      return;
    }
    _lastAudioPage = p;
    if (p == _page) return;
    if (_controller.hasClients) {
      unawaited(_controller.animateToPage(p - 1, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut));
    } else {
      _setPage(p); // lists / split view: follow without the page view
    }
  }

  void _setPage(int p) {
    setState(() {
      _page = p;
      _sliderValue = null;
    });
    final q = context.services.content.quran;
    unawaited(context.services.settings.setLastRead(q.page(_page).start));
    _scheduleKhatma();
  }

  void _onPageChanged(int index) => _setPage(index + 1);

  /// Shows page [p] immediately (also used by tests).
  void jumpTo(int p) => _jump(p);

  void _jump(int p) {
    if (p < 1 || p > _count) return;
    if (_controller.hasClients) {
      _controller.jumpToPage(p - 1);
    } else {
      _setPage(p); // lists or split view: the page view starts on it when shown again
    }
  }

  /// The page view's controller; a fresh one on the current page when the
  /// page view comes back after the lists or the split view.
  PageController _pageController() {
    if (!_controller.hasClients && _controller.initialPage != _page - 1) {
      final old = _controller;
      _controller = PageController(initialPage: _page - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _controller;
  }

  void _setTab(ReaderTab t) {
    if (t != _tab) setState(() => _tab = t);
  }

  Future<void> _onAyahTap(AyahRef r) async {
    setState(() => _selected = r);
    unawaited(context.services.settings.setLastRead(r));
    await showAyahSheet(
      context,
      r,
      onAyahChanged: (next) {
        if (!mounted) return;
        setState(() => _selected = next);
        final p = context.services.content.quran.pageOf(next);
        if (p != _page) _jump(p);
      },
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceXs, DesignTokens.spaceXs, DesignTokens.spaceXs, 0),
              child: Row(
                children: [
                  BackButton(key: const Key('readerBack'), color: scheme.primary),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ReaderTabs(tab: _tab, onChanged: _setTab),
                      ),
                    ),
                  ),
                  if (_tab == ReaderTab.mushaf)
                    IconButton(
                      key: const Key('readerHelp'),
                      tooltip: l.readerHelp,
                      color: scheme.primary,
                      icon: const Icon(Icons.help_outline),
                      onPressed: () => showReaderHelp(context, pageCount: _count, onGo: _jump),
                    )
                  else
                    _FontButton(key: const Key('readerFont')),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([s.recitation, s.settings]),
                builder: (context, _) {
                  final split = _tab == ReaderTab.mushaf && s.settings.tafsirWithRecitation && s.recitation.isActive;
                  if (split) return const SplitRecitationView();
                  final controller = _tab == ReaderTab.mushaf ? _pageController() : _controller;
                  return switch (_tab) {
                    ReaderTab.mushaf => PageView.builder(
                      key: const Key('mushafPageView'),
                      controller: controller,
                      itemCount: _count,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => BookPage(
                        index: i,
                        controller: controller,
                        child: TabletPage(
                          child: MushafPageView(
                            page: i + 1,
                            selected: _selected,
                            playing: s.recitation.currentRef,
                            onAyahTap: _onAyahTap,
                            onBackgroundTap: () => setState(() {
                              _controls = !_controls; // tap the margin for a full-screen page
                              _selected = null;
                            }),
                          ),
                        ),
                      ),
                    ),
                    ReaderTab.ayat => ReadableWidth(
                      child: PageAyahList(
                        key: ValueKey('ayat-$_page'),
                        page: _page,
                        withTafsir: false,
                        selected: _selected,
                        onAyahTap: _onAyahTap,
                      ),
                    ),
                    ReaderTab.tafsir => ReadableWidth(
                      child: PageAyahList(
                        key: ValueKey('tafsir-$_page'),
                        page: _page,
                        withTafsir: true,
                        selected: _selected,
                        onAyahTap: _onAyahTap,
                      ),
                    ),
                  };
                },
              ),
            ),
            if (_controls || _tab != ReaderTab.mushaf) ...[
              ReaderPlayerCard(page: _page),
              _sliderRow(context),
              _bottomBar(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final value = _sliderValue ?? _page.toDouble();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXs),
      child: Row(
        children: [
          IconButton(
            key: const Key('prevPage'),
            tooltip: l.quranPrevPage,
            color: scheme.primary,
            icon: Icon(rtl ? Icons.skip_next : Icons.skip_previous, size: 20),
            onPressed: _page > 1 ? () => _jump(_page - 1) : null,
          ),
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    ),
                    child: Text(
                      context.num(value.round()),
                      key: const Key('sliderValue'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: scheme.onPrimary,
                        inactiveTrackColor: scheme.onPrimary.withValues(alpha: 0.35),
                        thumbColor: scheme.onPrimary,
                        overlayColor: scheme.onPrimary.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        key: const Key('pageSlider'),
                        min: 1,
                        max: _count.toDouble(),
                        divisions: _count - 1,
                        value: value,
                        label: context.num(value.round()),
                        semanticFormatterCallback: (v) => l.mushafSlider(context.num(v.round())),
                        onChanged: (v) => setState(() => _sliderValue = v),
                        onChangeEnd: (v) => _jump(v.round()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('nextPage'),
            tooltip: l.quranNextPage,
            color: scheme.primary,
            icon: Icon(rtl ? Icons.skip_previous : Icons.skip_next, size: 20),
            onPressed: _page < _count ? () => _jump(_page + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget item(String key, IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        key: Key(key),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
    void push(Widget w) => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w)));
    return Material(
      key: const Key('mushafControls'),
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              item('barIndex', Icons.format_list_bulleted, l.readerIndex, () async {
                final p = await showQuranIndex(context, currentPage: _page);
                if (p != null && mounted) _jump(p);
              }),
              item(
                'barBookmarks',
                Icons.collections_bookmark_outlined,
                l.readerBookmarks,
                () => push(const BookmarksScreen()),
              ),
              item(
                'barKhatma',
                Icons.auto_stories_outlined,
                l.readerKhatma,
                () => unawaited(showKhatmaSheet(context, onGo: _jump)),
              ),
              item('barSearch', Icons.search, l.readerSearch, () => push(const SearchScreen())),
            ],
          ),
        ),
      ),
    );
  }
}

/// "حجم الخط": enlarges the text of the verse and tafsir lists, then wraps to the smallest size.
class _FontButton extends StatelessWidget {
  const _FontButton({super.key});

  static const step = 4.0;

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n.readerFontSize(context.num(settings.quranFontSize.round())),
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final next = settings.quranFontSize + step;
            unawaited(
              settings.setQuranFontSize(next > SettingsController.maxFontSize ? SettingsController.minFontSize : next),
            );
          },
          child: SizedBox(
            width: 48,
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ع',
                  style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, height: 1),
                ),
                Text(context.l10n.readerFont, style: TextStyle(color: scheme.onPrimary, fontSize: 9, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
