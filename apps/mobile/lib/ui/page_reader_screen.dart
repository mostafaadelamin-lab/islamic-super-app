import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../data/settings.dart';
import '../domain/audio_queue.dart';
import '../domain/page_khatma.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'play_origin.dart';
import 'ayah_sheet.dart';
import 'ayah_study.dart';
import 'bookmarks_screen.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart';
import 'quran_index_entry.dart';
import 'reader_widgets.dart';
import 'search_screen.dart';
import 'surah_flow.dart';
import 'surah_info_sheet.dart';
import 'word_meanings_sheet.dart';
import 'r_icon.dart';

/// Madinah Mushaf (1405H) reader: tabs المصحف / الآيات / التفسير; 604 pages of
/// 15 lines turned like a book (RTL: swipe right for the next page); a
/// floating recitation card; the page slider; and the bottom bar (index,
/// bookmarks, khatma, search). Tapping an ayah opens its sheet (listen, tafsir,
/// bookmark, copy). With "Listen with tafsir" the Mushaf tab splits in two:
/// the ayah being recited and its tafsir.
class PageReaderScreen extends StatefulWidget {
  /// The Mushaf opens with its tools; full screen only from its button (owner 2026-11-15: tap to enlarge,
  /// tap to shrink was confusing). Tests that start in full screen set this to true.
  static bool startFullScreen = false;

  const PageReaderScreen({super.key, this.initialPage = 1, this.highlight, this.initialTab = ReaderTab.mushaf});
  final int initialPage;

  /// The tab to open on: «الجزء كاملاً» from the index's «الأجزاء» (owner 2026-11-20).
  final ReaderTab initialTab;

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
  // Full-screen reading: the controls stay hidden until the page is tapped.
  bool _controls = !PageReaderScreen.startFullScreen;

  /// «التفسير بجانب الصفحة» (owner 2026-11-18): the page and its tafsir in two halves while reading,
  /// without listening (the same halves as «استماع مع التفسير»).
  bool _tafsirBeside = false;

  /// Phone halves: the player stays folded to one row unless opened here (owner 2026-11-18: less crowded).
  bool _splitPlayerOpen = false;

  /// Full screen beside the tafsir: the ayah tapped on the page, shown in the tafsir half.
  AyahRef? _focus;
  bool? _immersiveUi;
  // Full screen: a short "how to turn pages / show the controls" note, the first few times.
  bool _hint = false;
  Timer? _hintTimer;
  static const _hintShows = 3;
  static const _exitButtonRoom = 48.0;
  // Full screen: a free strip above the page holds «إظهار الأدوات», so it never covers the first line
  // (owner 2026-11-16).
  static const _exitStrip = 40.0;
  // Pinch zoom (owner 2026-11-16): two fingers zoom the page live; the size is saved when they lift.
  final Map<int, Offset> _touches = {};
  double? _pinchStartDistance;
  double _pinchStartZoom = 1;
  double? _liveZoom;
  static const _zoomSnap = 1.08;
  static const _actionsRoom = 120.0;

  int get page => _page;
  AyahRef? get selected => _selected;
  ReaderTab get tab => _tab;
  bool get controlsVisible => _controls;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, 604);
    _selected = widget.highlight;
    _tab = widget.initialTab;
    _controller = PageController(initialPage: _page - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A message left over from the previous screen (e.g. "Bookmarked") floats over
      // this screen's bottom controls on small phones; clear it when the reader opens.
      ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
      PlayOrigin.readerOpened(context);
      _recitation = context.services.recitation..addListener(_onRecitation);
      _lastAudioPage = _recitation!.currentPage;
      // The recitation was paused by another sound (adhkar…): open at the ayah it stopped at.
      final held = _recitation!.wasInterrupted ? _recitation!.currentPage : null;
      if (held != null && held != _page) _jump(held);
      _scheduleKhatma();
      _maybeShowHint();
      _maybeShowGuide();
    });
  }

  /// The first time the Mushaf opens: a short guide to its touches.
  void _maybeShowGuide() {
    final settings = context.services.settings;
    if (settings.readerGuideDone) return;
    unawaited(showReaderGuide(context).then((_) => settings.setReaderGuideDone()));
  }

  /// Full screen from its button: only the page, with a visible way back.
  void enterFullScreen() {
    setState(() {
      _controls = false;
      _selected = null;
    });
    _maybeShowHint();
  }

  void _maybeShowHint() {
    final settings = context.services.settings;
    if (!fullScreen || settings.readerHintShown >= _hintShows) return;
    unawaited(settings.setReaderHintShown(settings.readerHintShown + 1));
    setState(() => _hint = true);
    _hintTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  /// Hides the status and navigation bars while the page is full screen.
  void _syncSystemUi(bool full) {
    if (_immersiveUi == full) return;
    _immersiveUi = full;
    unawaited(SystemChrome.setEnabledSystemUIMode(full ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge));
  }

  @override
  void dispose() {
    if (_immersiveUi == true) unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _khatmaTimer?.cancel();
    _hintTimer?.cancel();
    _recitation?.removeListener(_onRecitation);
    _controller.dispose();
    super.dispose();
  }

  int get _count => context.services.content.quran.pageCount;

  /// Khatma: the page counts as read once it stayed open for [khatmaDwell].
  void _scheduleKhatma() {
    _khatmaTimer?.cancel();
    final settings = context.services.settings;
    final planner = context.services.khatma;
    final plan = planner.current;
    final p = _page;
    // The khatma planner's daily wird counts as done once its last page stayed open.
    final wirdEnd = plan == null || plan.finished ? null : plan.wirdPages(plan.done).to;
    if (settings.khatma == null && wirdEnd != p) return;
    _khatmaTimer = Timer(khatmaDwell, () {
      if (settings.khatma != null) unawaited(settings.markKhatmaPage(p));
      final now = planner.current;
      if (now != null && !now.finished && now.wirdPages(now.done).to == p) unawaited(planner.completeWird());
    });
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
      _flowSurah = null;
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
    if (t != _tab) {
      setState(() {
        _tab = t;
        _flowSurah = null;
        _flowJuz = null;
        _focus = null;
      });
    }
  }

  /// «السورة كاملة» or «الجزء كاملاً»: the flowing text, which gets the tafsir halves too (owner 2026-11-20).
  bool get _flowTab => _tab == ReaderTab.surah || _tab == ReaderTab.juz;

  /// The juz of «الجزء كاملاً»: the one picked in the view, else the selected ayah's, else the page's.
  int? _flowJuz;
  int get _juzShown {
    final q = context.services.content.quran;
    return _flowJuz ?? (_selected != null ? q.juzOf(_selected!) : q.juzOfPage(_page));
  }

  /// The surah of "السورة كاملة": the one picked with its buttons, else the selected ayah's, else the page's first.
  int? _flowSurah;
  int get _surahShown =>
      _flowSurah ?? _selected?.surah ?? context.services.content.quran.ayahsOnPage(_page).first.surah;

  Future<void> _onAyahTap(AyahRef r) async {
    // The whole surah / juz beside its tafsir: a tap shows that ayah's tafsir in the other half.
    if (_flowTab && _pageTafsir(context)) {
      setState(() => _focus = r);
      unawaited(context.services.settings.setLastRead(r));
      return;
    }
    setState(() => _selected = r);
    unawaited(context.services.settings.setLastRead(r));
    // On the Mushaf page the actions open in the bottom strip with the other bars (owner 2026-11-15).
    if (_tab == ReaderTab.mushaf) return;
    await showAyahSheet(
      context,
      r,
      overPage: _tab == ReaderTab.mushaf,
      onAyahChanged: (next) {
        if (!mounted) return;
        setState(() => _selected = next);
        final p = context.services.content.quran.pageOf(next);
        if (p != _page) _jump(p);
      },
    );
    if (mounted) setState(() => _selected = null);
  }

  /// True while only the Mushaf page is shown (no tabs, player or bars).
  bool get fullScreen {
    // «ملء الشاشة» works with the tafsir too, listening or only reading (owner 2026-11-18): the page and
    // the tafsir halves stay; the strip above them has the exit, tafsir and play / pause buttons.
    return _tab == ReaderTab.mushaf && !_controls && _selected == null;
  }

  /// The page's tafsir is shown beside the page: «التفسير بجانب الصفحة», or listening with tafsir.
  bool _pageTafsir(BuildContext context) {
    final s = context.services;
    return (_tab == ReaderTab.mushaf || _flowTab) &&
        (_tafsirBeside || (s.settings.tafsirWithRecitation && s.recitation.isActive));
  }

  /// Tafsir beside the page on / off (off also ends «استماع مع التفسير»).
  void _toggleTafsirBeside(BuildContext context) {
    final settings = context.services.settings;
    if (_pageTafsir(context)) {
      setState(() {
        _tafsirBeside = false;
        _focus = null;
      });
      if (settings.tafsirWithRecitation) unawaited(settings.setTafsirWithRecitation(false));
    } else {
      setState(() => _tafsirBeside = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return MushafColors(
      child: ListenableBuilder(
        listenable: Listenable.merge([s.recitation, s.settings]),
        builder: (context, _) => _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    // Short phones keep the whole Mushaf page on screen: zoom and surah info move into a menu.
    final size = MediaQuery.sizeOf(context);
    final compact = _tab == ReaderTab.mushaf && size.height < 700 && size.width < 420;
    final full = fullScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSystemUi(full);
    });
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceXs, DesignTokens.spaceXs, DesignTokens.spaceXs, 0),
      child: Row(
        children: [
          BackButton(key: const Key('readerBack'), color: scheme.primary),
          Expanded(
            child: ReaderTabs(tab: _tab, onChanged: _setTab),
          ),
          if (compact)
            PopupMenuButton<int>(
              key: const Key('readerMore'),
              tooltip: l.readerHelp,
              icon: RIcon(RIcons.help, color: scheme.primary),
              onSelected: (v) {
                final st = s.settings;
                switch (v) {
                  case 0:
                    unawaited(st.setMushafZoom(st.mushafZoom + 0.25));
                  case 1:
                    unawaited(st.setMushafZoom(st.mushafZoom - 0.25));
                  case 2:
                    showSurahInfo(context, (_selected ?? s.content.quran.ayahsOnPage(_page).first).surah);
                  case 4:
                    _toggleTafsirBeside(context);
                  case 5:
                    unawaited(st.setMushafPrinted(!st.mushafPrinted));
                  default:
                    showReaderHelp(context, pageCount: _count, onGo: _jump);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text('A+  ${l.readerFontBigger}')),
                PopupMenuItem(value: 1, child: Text('A−  ${l.readerFontSmaller}')),
                PopupMenuItem(value: 2, child: Text(l.surahInfoTitle)),
                PopupMenuItem(value: 4, key: const Key('menuTafsirBeside'), child: Text(l.readerTafsirBeside)),
                PopupMenuItem(
                  value: 5,
                  key: const Key('menuPrinted'),
                  child: Text('${s.settings.mushafPrinted ? '✓ ' : ''}${l.readerPrintedLook}'),
                ),
                PopupMenuItem(value: 3, child: Text(l.readerHelp)),
              ],
            )
          else if (_tab == ReaderTab.mushaf || _flowTab) ...[
            // «التفسير بجانب الصفحة»: the page's tafsir beside the page, without listening.
            IconButton(
              key: const Key('readerTafsirBeside'),
              tooltip: l.readerTafsirBeside,
              isSelected: _pageTafsir(context),
              color: scheme.primary,
              selectedIcon: RIcon(RIcons.openBook, color: scheme.onPrimary),
              style: _pageTafsir(context) ? IconButton.styleFrom(backgroundColor: scheme.primary) : null,
              icon: const RIcon(RIcons.openBook),
              onPressed: () => _toggleTafsirBeside(context),
            ),
            if (_tab == ReaderTab.mushaf)
              // Owner 2026-11-26: switch to the printed look (optional, downloaded) and back while reading.
              ListenableBuilder(
                listenable: s.settings,
                builder: (context, _) {
                  final on = s.settings.mushafPrinted;
                  return IconButton(
                    key: const Key('readerPrinted'),
                    tooltip: l.readerPrintedLook,
                    isSelected: on,
                    color: scheme.primary,
                    selectedIcon: RIcon(RIcons.pages, color: scheme.onPrimary),
                    style: on ? IconButton.styleFrom(backgroundColor: scheme.primary) : null,
                    icon: const RIcon(RIcons.pages),
                    onPressed: () => unawaited(s.settings.setMushafPrinted(!on)),
                  );
                },
              ),
            if (_tab == ReaderTab.mushaf)
              IconButton(
                key: const Key('readerHelp'),
                tooltip: l.readerHelp,
                color: scheme.primary,
                icon: const RIcon(RIcons.help),
                onPressed: () => showReaderHelp(context, pageCount: _count, onGo: _jump),
              ),
          ] else
            const SizedBox(width: 48),
        ],
      ),
    );
    final zoomRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
      child: Row(
        children: [
          _ZoomButtons(mushaf: _tab == ReaderTab.mushaf),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const Key('readerSurahInfo'),
                icon: const RIcon(RIcons.info, size: 20),
                label: Text(l.surahInfoTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () => showSurahInfo(context, (_selected ?? s.content.quran.ayahsOnPage(_page).first).surah),
              ),
            ),
          ),
        ],
      ),
    );
    final body = Stack(
      children: [
        Positioned.fill(top: full ? _exitStrip : 0, child: _pinchZoom(context, _pages(context))),
        if (full) ..._turnArrows(context),
        if (full && _hint) _hintBanner(context),
        if (full)
          PositionedDirectional(
            top: 3,
            end: DesignTokens.spaceSm,
            start: DesignTokens.spaceSm,
            child: _fullTools(context),
          ),
        if (_tab == ReaderTab.mushaf && (_liveZoom ?? context.services.settings.mushafZoom) > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: DesignTokens.spaceMd,
            child: Center(child: _zoomResetChip(context)),
          ),
      ],
    );
    // A phone held sideways (owner 2026-11-17): the page keeps the whole height and fills its width
    // (scrolling down); the tabs, ayah actions, player and bar share a slim side column.
    if (!full && isLandscapePhone(size)) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Expanded(key: const Key('readerBody'), child: body),
              Material(
                key: const Key('readerSide'),
                color: scheme.surface,
                elevation: 8,
                child: SizedBox(
                  width: math.min(360, size.width * 0.4),
                  child: Column(
                    children: [
                      header,
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [zoomRow, _controlsStrip(context, wide: false)],
                          ),
                        ),
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
    return Scaffold(
      backgroundColor: full ? AppTheme.of(context, 'surface2') : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!full) header,
            // The page + tafsir halves on a phone leave out A− / A+ and «عن السورة» (less crowded).
            if (!compact && !full && !(_pageTafsir(context) && !ayahSidePanel(size))) zoomRow,
            if (full) const SizedBox.shrink(key: Key('readerFullScreen')),
            Expanded(key: const Key('readerBody'), child: body),
            if (!full)
              ListenableBuilder(
                listenable: context.services.settings,
                builder: (context, _) => _controlsStrip(context, wide: ayahSidePanel(size)),
              ),
          ],
        ),
      ),
    );
  }

  /// One strip across the bottom (owner 2026-11-15): the selected ayah's actions, the page slider,
  /// the player and index / bookmarks / khatma / search. Wide screens put the player and the bar
  /// side by side so the page keeps the height.
  Widget _controlsStrip(BuildContext context, {required bool wide}) {
    final scheme = Theme.of(context).colorScheme;
    // Phone with the page + tafsir halves (owner 2026-11-18: «زحمة»): the player folds to one row.
    final phoneSplit = !wide && _pageTafsir(context) && _selected == null;
    final playerMin = phoneSplit ? !_splitPlayerOpen : context.services.settings.readerPlayerMin;
    final sel = _selected;
    final actions = sel != null && _tab == ReaderTab.mushaf
        ? AyahSheet(
            key: const Key('stripAyahActions'),
            initial: sel,
            heightFactor: 0.4,
            // Wide screens: «تفسير الآية» opens beside the page, which keeps its size (owner 2026-11-18).
            onTafsir: wide ? () => _toggleTafsirBeside(context) : null,
            tafsirOpen: wide && _pageTafsir(context),
            onClose: () => setState(() => _selected = null),
            onAyahChanged: (next) {
              setState(() => _selected = next);
              final p = context.services.content.quran.pageOf(next);
              if (p != _page) _jump(p);
            },
          )
        : null;
    return Material(
      key: const Key('readerStrip'),
      color: scheme.surface,
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide && _tab == ReaderTab.mushaf) ...[
            // Wide screens keep the room for the ayah row, so the page never shrinks when it shows.
            ConstrainedBox(
              key: const Key('stripAyahRoom'),
              constraints: const BoxConstraints(minHeight: _actionsRoom),
              child:
                  actions ??
                  SizedBox(
                    height: _actionsRoom,
                    child: Center(
                      child: Text(
                        context.l10n.readerPickAyah,
                        key: const Key('stripPickAyah'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ] else if (actions != null) ...[
            actions,
            Divider(height: 1, color: scheme.outlineVariant),
          ],
          // A handle slides the player and the page slider down to one thin row (owner 2026-11-17).
          ReaderPlayerHandle(
            page: _page,
            min: phoneSplit ? playerMin : null,
            onChanged: phoneSplit ? (v) => setState(() => _splitPlayerOpen = !v) : null,
          ),
          if (wide) ...[
            if (!playerMin) _sliderRow(context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: playerMin ? const SizedBox.shrink() : ReaderPlayerCard(page: _page, flat: true)),
                SizedBox(width: ayahPanelWidth, child: _bottomBar(context)),
              ],
            ),
          ] else ...[
            if (!playerMin) ReaderPlayerCard(page: _page, flat: true),
            if (!playerMin) _sliderRow(context),
            _bottomBar(context),
          ],
        ],
      ),
    );
  }

  /// Turns one page with the book animation (+1 = next).
  void _turn(int delta) {
    final p = _page + delta;
    if (p < 1 || p > _count) return;
    if (_controller.hasClients) {
      unawaited(_controller.animateToPage(p - 1, duration: const Duration(milliseconds: 380), curve: Curves.easeInOut));
    } else {
      _setPage(p);
    }
  }

  /// Full screen: two arrows to turn pages (the next page is on the left in Arabic, like a printed Mushaf).
  /// Phones: small, at the bottom corners beside the page number, never on the text.
  List<Widget> _turnArrows(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final phone = MediaQuery.sizeOf(context).width < 600;
    Widget arrow({required bool next, required bool left}) {
      final enabled = next ? _page < _count : _page > 1;
      final button = Opacity(
        opacity: enabled ? 0.8 : 0,
        child: Material(
          color: scheme.surface.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(phone ? 10 : 14),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
          ),
          child: InkWell(
            key: Key(next ? 'turnNext' : 'turnPrev'),
            borderRadius: BorderRadius.circular(phone ? 10 : 14),
            onTap: enabled ? () => _turn(next ? 1 : -1) : null,
            child: Tooltip(
              message: next ? l.quranNextPage : l.quranPrevPage,
              child: SizedBox(
                width: phone ? 40 : 44,
                height: phone ? 32 : 64,
                child: Icon(
                  left ? Icons.chevron_left : Icons.chevron_right,
                  textDirection: TextDirection.ltr,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
      return phone
          ? Positioned(bottom: 2, left: left ? 4 : null, right: left ? null : 4, child: button)
          : Positioned(
              top: 0,
              bottom: 0,
              left: left ? 4 : null,
              right: left ? null : 4,
              child: Center(child: button),
            );
    }

    return [arrow(next: true, left: rtl), arrow(next: false, left: !rtl)];
  }

  /// Full screen's strip above the page (owner 2026-11-18): show the tools, the tafsir beside the page
  /// on / off and, while listening, play / pause.
  Widget _fullTools(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final on = _pageTafsir(context);
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      key: const Key('readerFullTools'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (context.services.recitation.isActive)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: math.min(260, width * 0.4)),
              child: Material(
                color: scheme.surface.withValues(alpha: 0.94),
                shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
                elevation: 2,
                child: SizedBox(
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
                    child: ReaderPlayerMini(page: _page),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: DesignTokens.spaceXs),
        _pill(
          context,
          key: const Key('fullTafsirBeside'),
          icon: RIcons.openBook,
          label: on ? l.readerHideTafsir : l.readerTafsirBesideShort,
          selected: on,
          onTap: () => _toggleTafsirBeside(context),
        ),
        const SizedBox(width: DesignTokens.spaceXs),
        _exitFullButton(context),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required Key key,
    required RIconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.primary;
    return Material(
      color: selected ? scheme.primary : scheme.surface.withValues(alpha: 0.94),
      shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
      elevation: 2,
      child: InkWell(
        key: key,
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIcon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exitFullButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
      elevation: 2,
      child: InkWell(
        key: const Key('readerExitFull'),
        customBorder: const StadiumBorder(),
        onTap: () => setState(() => _controls = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIcon(RIcons.shrink, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                context.l10n.readerExitFull,
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two fingers on the Mushaf page zoom it (1×–3×); one finger keeps turning pages / panning.
  /// A raw [Listener], so the page view keeps its own drag; it is locked while two fingers are down.
  Widget _pinchZoom(BuildContext context, Widget child) {
    if (_tab != ReaderTab.mushaf) return child;
    final settings = context.services.settings;
    double spread() {
      final p = _touches.values.take(2).toList();
      return (p[0] - p[1]).distance;
    }

    void end(PointerEvent e) {
      _touches.remove(e.pointer);
      if (_touches.length >= 2 || _pinchStartDistance == null) return;
      final z = _liveZoom ?? settings.mushafZoom;
      _pinchStartDistance = null;
      unawaited(settings.setMushafZoom(z < _zoomSnap ? 1.0 : (z * 20).roundToDouble() / 20));
      setState(() => _liveZoom = null);
    }

    return Listener(
      key: const Key('mushafPinch'),
      onPointerDown: (e) {
        _touches[e.pointer] = e.position;
        if (_touches.length == 2) {
          setState(() {
            _pinchStartDistance = spread();
            _pinchStartZoom = settings.mushafZoom;
            _liveZoom = _pinchStartZoom;
          });
        }
      },
      onPointerMove: (e) {
        if (!_touches.containsKey(e.pointer)) return;
        _touches[e.pointer] = e.position;
        final d0 = _pinchStartDistance;
        if (d0 == null || _touches.length < 2 || d0 <= 0) return;
        final z = (_pinchStartZoom * spread() / d0).clamp(
          SettingsController.mushafZoomMin,
          SettingsController.mushafZoomMax,
        );
        if ((z - (_liveZoom ?? 0)).abs() > 0.01) setState(() => _liveZoom = z);
      },
      onPointerUp: end,
      onPointerCancel: end,
      child: child,
    );
  }

  Widget _zoomResetChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final z = _liveZoom ?? context.services.settings.mushafZoom;
    final pct = (z * 100).round();
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
      elevation: 2,
      child: InkWell(
        key: const Key('mushafZoomReset'),
        customBorder: const StadiumBorder(),
        onTap: () => unawaited(context.services.settings.setMushafZoom(1)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIcon(RIcons.shrink, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                context.l10n.readerZoomReset(context.l10n.localeName == 'ar' ? toArabicIndic(pct) : '$pct'),
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintBanner(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: DesignTokens.spaceSm + _exitButtonRoom,
      left: DesignTokens.spaceMd,
      right: DesignTokens.spaceMd,
      child: Material(
        key: const Key('readerHint'),
        color: scheme.inverseSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceMd,
            DesignTokens.spaceXs,
            DesignTokens.spaceXs,
            DesignTokens.spaceXs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(l.readerFullHint, style: TextStyle(color: scheme.onInverseSurface, height: 1.5)),
              ),
              TextButton(
                onPressed: () => setState(() => _hint = false),
                child: Text(l.readerHintClose, style: TextStyle(color: scheme.inversePrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pages(BuildContext context) {
    final s = context.services;
    final full = fullScreen;
    return ListenableBuilder(
      listenable: Listenable.merge([s.recitation, s.settings]),
      builder: (context, _) {
        // Wide screens keep the halves while an ayah's actions are open (its «تفسير الآية» shows there).
        if (_flowTab && _pageTafsir(context)) return _flowDuo(context);
        final split = _pageTafsir(context) && (_selected == null || ayahSidePanel(MediaQuery.sizeOf(context)));
        if (split) return _duo(context);
        final controller = _tab == ReaderTab.mushaf ? _pageController() : _controller;
        Widget mushafPage(int i) => TabletPage(
          child: ZoomedPage(
            zoom: _liveZoom ?? s.settings.mushafZoom,
            child: MushafPageView(
              page: i + 1,
              selected: _selected,
              playing: s.recitation.currentRef,
              onAyahTap: _onAyahTap,
              immersive: full,
              // A tap beside the text only closes the ayah's actions (no show/hide toggling).
              onBackgroundTap: () => setState(() => _selected = null),
            ),
          ),
        );
        return switch (_tab) {
          ReaderTab.mushaf => PageView.builder(
            key: const Key('mushafPageView'),
            controller: controller,
            // Two fingers down = pinch zoom, not a page turn.
            physics: _touches.length >= 2 ? const NeverScrollableScrollPhysics() : null,
            itemCount: _count,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) => BookPage(
              index: i,
              controller: controller,
              under: i + 1 < _count ? mushafPage(i + 1) : null,
              child: mushafPage(i),
            ),
          ),
          ReaderTab.surah => ReadableWidth(child: _surahFlow(context)),
          ReaderTab.juz => ReadableWidth(child: _juzFlow(context)),
          ReaderTab.ayat => ReadableWidth(
            child: PageAyahList(
              key: ValueKey('ayat-$_page'),
              page: _page,
              withTafsir: false,
              selected: _selected,
              onAyahTap: _onAyahTap,
              onPage: _setPage,
            ),
          ),
          ReaderTab.tafsir => ReadableWidth(
            child: PageAyahList(
              key: ValueKey('tafsir-$_page'),
              page: _page,
              withTafsir: true,
              selected: _selected,
              onAyahTap: _onAyahTap,
              onPage: _setPage,
            ),
          ),
        };
      },
    );
  }

  Widget _surahFlow(BuildContext context, {AyahRef? selected}) {
    final s = context.services;
    return SurahFlow(
      key: ValueKey('surahFlowView-$_surahShown'),
      surah: _surahShown,
      page: _page,
      selected: selected ?? _selected,
      playing: s.recitation.currentRef,
      onAyahTap: _onAyahTap,
      onSurah: (n) {
        _setPage(s.content.quran.pageOf(AyahRef(n, 1)));
        setState(() {
          _flowSurah = n;
          _focus = null;
        });
      },
    );
  }

  Widget _juzFlow(BuildContext context, {AyahRef? selected}) {
    final s = context.services;
    final j = _juzShown;
    return JuzFlow(
      key: ValueKey('juzFlowView-$j'),
      juz: j,
      page: _page,
      selected: selected ?? _selected,
      playing: s.recitation.currentRef,
      onAyahTap: _onAyahTap,
      onJuz: (n) {
        _setPage(s.content.quran.juz[n - 1].page);
        setState(() {
          _flowJuz = n;
          _selected = null;
          _focus = null;
        });
      },
    );
  }

  /// «السورة كاملة» / «الجزء كاملاً» with the tafsir (owner 2026-11-20: on a laptop the whole surah did not
  /// split into tafsir + surah like the page does): the flowing text on one half and the tafsir of every ayah
  /// in it on the other; side by side on wide screens, one above the other on phones. A tap on an ayah brings
  /// its tafsir into view; while listening both halves follow the recitation.
  Widget _flowDuo(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final q = s.content.quran;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final wide = ayahSidePanel(size) && !isLandscapePhone(size);
    final juz = _tab == ReaderTab.juz;
    final listening = s.settings.tafsirWithRecitation && s.recitation.isActive;
    final focus = _focus ?? _selected;
    final refs = juz
        ? q.juzRefs(_juzShown)
        : [for (var a = 1; a <= q.surah(_surahShown).ayahCount; a++) AyahRef(_surahShown, a)];
    final flow = juz ? _juzFlow(context, selected: focus) : _surahFlow(context, selected: focus);
    final tafsir = Container(
      key: const Key('flowTafsir'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(DesignTokens.spaceMd, 2, DesignTokens.spaceXs, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    listening
                        ? l.readerListenWithTafsir
                        : juz
                        ? l.readerTafsirBesideJuz
                        : l.readerTafsirBesideSurah,
                    key: const Key('duoTitle'),
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  key: const Key('duoHideTafsir'),
                  onPressed: () => _toggleTafsirBeside(context),
                  child: Text(l.readerHideTafsir),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: PageAyahList(
              key: ValueKey('flowTafsir-${juz ? 'j$_juzShown' : 's$_surahShown'}'),
              page: _page,
              refs: refs,
              initial: s.recitation.currentRef ?? q.ayahsOnPage(_page).where(refs.contains).firstOrNull,
              withTafsir: true,
              selected: focus,
              fontSize: math.min(s.settings.quranFontSize, 22),
              onAyahTap: (r) =>
                  listening ? unawaited(s.recitation.playFrom(r, scope: PlayScope.surah)) : setState(() => _focus = r),
            ),
          ),
        ],
      ),
    );
    if (wide) {
      return Padding(
        key: const Key('flowSplitView'),
        padding: const EdgeInsets.all(DesignTokens.spaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 45, child: tafsir),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(flex: 55, child: flow),
          ],
        ),
      );
    }
    return Padding(
      key: const Key('flowSplitView'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceSm, 0, DesignTokens.spaceSm, DesignTokens.spaceXs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: flow),
          const SizedBox(height: DesignTokens.spaceXs),
          Expanded(child: tafsir),
        ],
      ),
    );
  }

  /// "Listen with tafsir" (owner 2026-11-15): the whole Mushaf page and the page's tafsir in two
  /// halves, both following the recitation: side by side on wide screens, page on top on phones
  /// (the page fills the width there and scrolls to the recited ayah).
  Widget _duo(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // A phone held sideways stacks the halves too: the page fills the width and scrolls to the recited ayah.
    final wide = ayahSidePanel(size) && !isLandscapePhone(size);
    final playing = s.recitation.currentRef;
    final pageOfPlaying = playing == null ? _page : s.content.quran.pageOf(playing);
    if (pageOfPlaying != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setPage(pageOfPlaying);
      });
    }
    final full = fullScreen;
    final listening = s.settings.tafsirWithRecitation && s.recitation.isActive;
    final page = MushafPageView(
      page: _page,
      playing: playing,
      selected: _selected ?? _focus,
      // Full screen: a tap shows that ayah's tafsir in the other half and stays full screen.
      onAyahTap: full ? (r) => setState(() => _focus = r) : _onAyahTap,
    );
    final tafsir = Container(
      key: const Key('duoTafsir'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(DesignTokens.spaceMd, 2, DesignTokens.spaceXs, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    listening ? l.readerListenWithTafsir : l.readerTafsirBeside,
                    key: const Key('duoTitle'),
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  key: const Key('duoHideTafsir'),
                  onPressed: () => _toggleTafsirBeside(context),
                  child: Text(l.readerHideTafsir),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            // Reading (not listening) with an ayah picked: that ayah's tafsir with the books and the studies
            // (owner 2026-11-20); otherwise the page's tafsir (al-Muyassar), following the recitation.
            child: !listening && (_focus ?? _selected) != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
                    child: AyahStudyCard(key: const Key('duoStudy'), ref: (_focus ?? _selected)!),
                  )
                : PageAyahList(
                    key: ValueKey('duo-$_page'),
                    page: _page,
                    withTafsir: true,
                    selected: _focus ?? _selected,
                    fontSize: math.min(s.settings.quranFontSize, 22),
                    onAyahTap: (r) => listening
                        ? unawaited(s.recitation.playFrom(r, scope: PlayScope.surah))
                        : setState(() => _focus = r),
                  ),
          ),
        ],
      ),
    );
    if (wide) {
      return Padding(
        key: const Key('splitView'),
        padding: const EdgeInsets.all(DesignTokens.spaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 45, child: tafsir),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              flex: 55,
              // Full screen: the whole page in the screen's height, beside the tafsir.
              child: _DuoPage(page: _page, playing: playing, maxScroll: full ? 1.0 : _DuoPage.wideScroll, child: page),
            ),
          ],
        ),
      );
    }
    return Padding(
      key: const Key('splitView'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceSm, 0, DesignTokens.spaceSm, DesignTokens.spaceXs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _DuoPage(page: _page, playing: playing, child: page),
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          Expanded(child: tafsir),
        ],
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
            icon: RIcon(rtl ? RIcons.next : RIcons.prev, size: 20),
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
            icon: RIcon(rtl ? RIcons.prev : RIcons.next, size: 20),
            onPressed: _page < _count ? () => _jump(_page + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget item(String key, RIconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        key: Key(key),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIcon(icon, color: scheme.primary),
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
              item('barIndex', RIcons.list, l.readerIndex, () async {
                final p = await showQuranIndex(context, currentPage: _page);
                if (p != null && mounted) _jump(p);
              }),
              item('barBookmarks', RIcons.bookmarks, l.readerBookmarks, () => push(const BookmarksScreen())),
              item('barKhatma', RIcons.quran, l.readerKhatma, () {
                setState(() => _selected = null); // one panel at a time
                unawaited(showKhatmaSheet(context, onGo: _jump));
              }),
              // «معاني الكلمات» of this page (owner 2026-11-17).
              item('barMeanings', RIcons.meanings, l.meaningsTitle, () {
                setState(() => _selected = null); // one panel at a time
                unawaited(
                  showWordMeaningsSheet(
                    context,
                    refs: context.services.content.quran.ayahsOnPage(_page),
                    page: _page,
                    onSelect: (r) => unawaited(_onAyahTap(r)),
                  ),
                );
              }),
              item('barSearch', RIcons.search, l.readerSearch, () => push(const SearchScreen())),
              if (_tab == ReaderTab.mushaf) item('readerFull', RIcons.expand, l.readerFullScreen, enterFullScreen),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bigger / smaller Quran text (owner, 2026-11-11). On the Mushaf page it zooms the page
/// (pan to read the enlarged page); on the verse and tafsir lists it changes the font size.
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.mushaf});
  final bool mushaf;

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    // A tablet held sideways: A− / A+ size the whole page (it scrolls down), like − / + on the website.
    final tabletPage = mushaf && Adaptive.tabletSideways(context);
    final canDown = tabletPage
        ? settings.tabletPageScale > SettingsController.tabletPageScaleMin
        : mushaf
        ? settings.mushafZoom > SettingsController.mushafZoomMin
        : settings.quranFontSize > SettingsController.minFontSize;
    final canUp = tabletPage
        ? settings.tabletPageScale < SettingsController.tabletPageScaleMax
        : mushaf
        ? settings.mushafZoom < SettingsController.mushafZoomMax
        : settings.quranFontSize < SettingsController.maxFontSize;
    void change(int dir) {
      if (tabletPage) {
        unawaited(settings.setTabletPageScale(settings.tabletPageScale + 0.25 * dir));
      } else if (mushaf) {
        unawaited(settings.setMushafZoom(settings.mushafZoom + 0.25 * dir));
      } else {
        final next = (settings.quranFontSize + 2 * dir).clamp(
          SettingsController.minFontSize,
          SettingsController.maxFontSize,
        );
        unawaited(settings.setQuranFontSize(next.toDouble()));
      }
    }

    Widget btn(String key, String label, bool enabled, int dir, String tip) => Tooltip(
      message: tip,
      child: InkWell(
        key: Key(key),
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? () => change(dir) : null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: dir > 0 ? 18 : 14,
            ),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn('readerFontDown', 'A−', canDown, -1, l.readerFontSmaller),
        const SizedBox(width: 4),
        btn('readerFontUp', 'A+', canUp, 1, l.readerFontBigger),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Shows [child] (a Mushaf page laid out for the screen) [zoom] times larger; the reader pans
/// across it. Starts at the top right (Arabic reading start).
class ZoomedPage extends StatefulWidget {
  const ZoomedPage({super.key, required this.zoom, required this.child});
  final double zoom;
  final Widget child;

  @override
  State<ZoomedPage> createState() => _ZoomedPageState();
}

class _ZoomedPageState extends State<ZoomedPage> {
  final _h = ScrollController();
  final _v = ScrollController();

  @override
  void dispose() {
    _h.dispose();
    _v.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.zoom <= 1.0) return widget.child;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth * widget.zoom;
        final h = c.maxHeight * widget.zoom;
        // Horizontal scroll follows the text direction, so it starts at the right edge in Arabic.
        return Scrollbar(
          controller: _v,
          child: SingleChildScrollView(
            key: const Key('mushafZoomV'),
            controller: _v,
            child: SingleChildScrollView(
              key: const Key('mushafZoomH'),
              controller: _h,
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: w, height: h, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

/// The Mushaf page in the top half on a phone: as wide as the screen (readable size) and scrolled
/// so the recited ayah stays in view.
class _DuoPage extends StatefulWidget {
  const _DuoPage({required this.page, required this.playing, required this.child, this.maxScroll});
  final int page;
  final AyahRef? playing;
  final Widget child;

  /// Wide screens (owner 2026-11-15): the page is big but at most this many screen heights tall,
  /// so it reads large beside the tafsir and scrolls with the recitation.
  final double? maxScroll;

  /// Owner 2026-11-18: 1.4 left the page too small beside the tafsir.
  static const wideScroll = 2.2;

  /// Height of a page laid out at the screen's width (15 lines plus the header and footer).
  static const heightPerWidth = 1.5;

  @override
  State<_DuoPage> createState() => _DuoPageState();
}

class _DuoPageState extends State<_DuoPage> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_DuoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing || widget.page != oldWidget.page) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  void _follow() {
    final r = widget.playing;
    if (!mounted || r == null || !_scroll.hasClients) return;
    final ctx = context;
    final refs = ctx.services.content.quran.ayahsOnPage(widget.page);
    final i = refs.indexOf(r);
    if (i < 0) return;
    final max = _scroll.position.maxScrollExtent;
    final target = (max * i / math.max(1, refs.length - 1)).clamp(0.0, max);
    unawaited(_scroll.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _height(BoxConstraints c) {
    final byWidth = c.maxWidth * _DuoPage.heightPerWidth;
    final cap = widget.maxScroll;
    final h = cap == null ? byWidth : math.min(byWidth, c.maxHeight * cap);
    return math.max(c.maxHeight, h);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      key: const Key('duoPage'),
      controller: _scroll,
      child: SizedBox(height: _height(c), child: widget.child),
    ),
  );
}
