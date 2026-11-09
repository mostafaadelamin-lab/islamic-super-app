import 'package:flutter/material.dart';

import '../app_services.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'quran_index.dart';
import 'search_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quranIndex),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.quranSearch,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            tooltip: l.quranOpenMushaf,
            icon: const Icon(Icons.chrome_reader_mode),
            onPressed: () {
              final s = context.services;
              final r = s.settings.lastRead;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PageReaderScreen(initialPage: r == null ? 1 : s.content.quran.pageOf(r)),
                ),
              );
            },
          ),
        ],
      ),
      // The index (Surahs / Quarters, grouped by juz); tapping a row opens the Mushaf page.
      body: const QuranIndexView(showTitle: false),
    );
  }
}
