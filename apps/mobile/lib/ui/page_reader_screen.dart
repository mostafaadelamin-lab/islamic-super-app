import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/audio_queue.dart';
import '../domain/bookmark.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/design_tokens.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart';
import 'widgets.dart';

/// Madinah Mushaf (1405H) reader: 604 pages of 15 lines, turned like a book
/// (RTL: swipe right for the next page), page slider and go-to-page, ayah
/// actions, and recitation that turns the pages as it goes.
class PageReaderScreen extends StatefulWidget {
  const PageReaderScreen({super.key, this.initialPage = 1, this.highlight});
  final int initialPage;

  /// Ayah to highlight when the page opens (e.g. from search or a bookmark).
  final AyahRef? highlight;

  @override
  State<PageReaderScreen> createState() => PageReaderScreenState();
}

class PageReaderScreenState extends State<PageReaderScreen> {
  late final PageController _controller;
  late int _page;
  final _input = TextEditingController();
  String? _error;
  AyahRef? _selected;
  bool _controls = true;
  int? _lastAudioPage;
  double? _sliderValue;
  RecitationController? _recitation;

  int get page => _page;
  AyahRef? get selected => _selected;
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
    });
  }

  @override
  void dispose() {
    _recitation?.removeListener(_onRecitation);
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  int get _count => context.services.content.quran.pageCount;

  /// Turns to the page of the ayah being recited when it moves to a new page.
  void _onRecitation() {
    final p = _recitation?.currentPage;
    if (p == null || p == _lastAudioPage) {
      _lastAudioPage = p;
      return;
    }
    _lastAudioPage = p;
    if (p != _page && _controller.hasClients) {
      unawaited(_controller.animateToPage(p - 1, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut));
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _page = index + 1;
      _sliderValue = null;
    });
    final q = context.services.content.quran;
    context.services.settings.setLastRead(q.page(_page).start);
  }

  /// Shows page [p] immediately (also used by tests).
  void jumpTo(int p) => _jump(p);

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

  Future<void> _onAyahTap(AyahRef r) async {
    setState(() => _selected = r);
    unawaited(context.services.settings.setLastRead(r));
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => _AyahSheet(ref: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quranPages),
        toolbarHeight: 52,
        actions: [
          IconButton(
            key: const Key('playPage'),
            tooltip: l.mushafPlayPage,
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => s.recitation.playFrom(s.content.quran.page(_page).start),
          ),
          IconButton(
            key: const Key('recitationSettings'),
            tooltip: l.audioTitle,
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: () => showRecitationSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: s.recitation,
              builder: (context, _) => PageView.builder(
                key: const Key('mushafPageView'),
                controller: _controller,
                itemCount: _count,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => BookPage(
                  index: i,
                  controller: _controller,
                  child: MushafPageView(
                    page: i + 1,
                    selected: _selected,
                    playing: s.recitation.currentRef,
                    onAyahTap: _onAyahTap,
                    onBackgroundTap: () => setState(() {
                      _controls = !_controls;
                      _selected = null;
                    }),
                  ),
                ),
              ),
            ),
          ),
          const MiniPlayer(),
          if (_controls) _controlsBar(context),
        ],
      ),
    );
  }

  Widget _controlsBar(BuildContext context) {
    final l = context.l10n;
    return Material(
      key: const Key('mushafControls'),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                key: const Key('pageSlider'),
                min: 1,
                max: _count.toDouble(),
                divisions: _count - 1,
                value: _sliderValue ?? _page.toDouble(),
                label: context.num((_sliderValue ?? _page).round()),
                semanticFormatterCallback: (v) => l.mushafSlider(context.num(v.round())),
                onChanged: (v) => setState(() => _sliderValue = v),
                onChangeEnd: (v) => _jump(v.round()),
              ),
              Row(
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
              const SizedBox(height: DesignTokens.spaceXs),
            ],
          ),
        ),
      ),
    );
  }
}

/// Actions for a tapped ayah: listen from here, bookmark, copy, read as list.
class _AyahSheet extends StatelessWidget {
  const _AyahSheet({required this.ref});
  final AyahRef ref;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: s.bookmarks,
      builder: (context, _) {
        final marked = s.bookmarks.isBookmarked(ref);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              key: const Key('ayahSheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                  child: Text(ayahLabel(context, ref), style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  key: const Key('ayahPlay'),
                  leading: const Icon(Icons.play_arrow),
                  title: Text(l.mushafPlayFromHere),
                  onTap: () {
                    Navigator.of(context).pop();
                    s.recitation.playFrom(ref);
                  },
                ),
                ListTile(
                  key: const Key('ayahPlaySurah'),
                  leading: const Icon(Icons.queue_music),
                  title: Text(l.mushafPlaySurah),
                  onTap: () {
                    Navigator.of(context).pop();
                    s.recitation.playFrom(AyahRef(ref.surah, 1), scope: PlayScope.surah);
                  },
                ),
                ListTile(
                  key: const Key('ayahBookmark'),
                  leading: Icon(marked ? Icons.bookmark : Icons.bookmark_border),
                  title: Text(marked ? l.quranRemoveBookmark : l.quranBookmark),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    if (marked) {
                      await s.bookmarks.remove(Bookmark.idFor(ref.surah, ref.ayah));
                    } else {
                      await s.bookmarks.add(ref);
                    }
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(marked ? l.quranBookmarkRemoved : l.quranBookmarked)),
                    );
                  },
                ),
                ListTile(
                  key: const Key('ayahCopy'),
                  leading: const Icon(Icons.copy),
                  title: Text(l.mushafCopy),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final q = s.content.quran;
                    // The canonical stored text (no display glyph map) and its reference.
                    await Clipboard.setData(
                      ClipboardData(text: '${q.text(ref)} ﴿${q.surah(ref.surah).nameAr}: ${toArabicIndic(ref.ayah)}﴾'),
                    );
                    nav.pop();
                    messenger.showSnackBar(SnackBar(content: Text(l.mushafCopied)));
                  },
                ),
                ListTile(
                  key: const Key('ayahReadList'),
                  leading: const Icon(Icons.view_agenda_outlined),
                  title: Text(l.mushafReadAsList),
                  onTap: () {
                    Navigator.of(context).pop();
                    openSurah(context, ref.surah, ayah: ref.ayah);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
