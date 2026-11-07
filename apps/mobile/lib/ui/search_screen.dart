import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/search.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SearchResult? _result;
  bool _tooShort = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    final r = context.services.content.search.search(_controller.text);
    setState(() {
      _searched = true;
      _tooShort = r == null;
      _result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _result;
    final q = context.services.content.quran;
    Widget body;
    if (!_searched) {
      body = Center(child: Text(l.quranSearchPrompt));
    } else if (_tooShort) {
      body = Center(child: Text(l.quranSearchTooShort, key: const Key('searchTooShort')));
    } else if (r!.total == 0) {
      body = Center(child: Text(l.quranNoResults, key: const Key('searchNoResults')));
    } else {
      body = ListView.separated(
        key: const Key('searchResults'),
        itemCount: r.hits.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.quranResultsCount(context.num(r.total)), key: const Key('searchCount')),
            );
          }
          final h = r.hits[i - 1];
          return ListTile(
            key: Key('hit-${h.ref.surah}-${h.ref.ayah}'),
            title: QuranText(h.text, ayahNumber: h.ref.ayah, size: 22),
            subtitle: Text(l.quranSurahAyah(surahName(context, q.surah(h.ref.surah)), context.num(h.ref.ayah))),
            onTap: () => openSurah(context, h.ref.surah, ayah: h.ref.ayah),
            trailing: IconButton(
              key: Key('hitMushaf-${h.ref.surah}-${h.ref.ayah}'),
              tooltip:
                  '${l.homeOpenMushaf}: ${l.quranSurahAyah(surahName(context, q.surah(h.ref.surah)), context.num(h.ref.ayah))}',
              icon: const Icon(Icons.chrome_reader_mode_outlined),
              onPressed: () => openMushafAt(context, h.ref),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.quranSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('searchField'),
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(),
                    decoration: InputDecoration(labelText: l.quranSearch, hintText: l.quranSearchHint),
                  ),
                ),
                IconButton(
                  key: const Key('searchButton'),
                  tooltip: l.quranSearchAction,
                  icon: const Icon(Icons.search),
                  onPressed: _run,
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
