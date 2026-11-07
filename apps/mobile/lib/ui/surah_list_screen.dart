import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'search_screen.dart';
import 'widgets.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _filter = '';

  List<Surah> _filtered(BuildContext context) {
    final s = context.services;
    final all = s.content.quran.surahs;
    final q = _filter.trim();
    if (q.isEmpty) return all;
    final num = int.tryParse(toAsciiDigits(q));
    final norm = s.content.normalizer.normalize(q);
    final lower = q.toLowerCase();
    return [
      for (final su in all)
        if ((num != null && su.n == num) ||
            (norm.isNotEmpty && s.content.normalizer.normalize(su.nameAr).contains(norm)) ||
            su.translit.toLowerCase().contains(lower) ||
            su.nameEn.toLowerCase().contains(lower))
          su,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = _filtered(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quranSurahs),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('surahFilter'),
              decoration: InputDecoration(
                labelText: l.quranFilter,
                hintText: l.quranFilterHint,
                prefixIcon: const Icon(Icons.filter_list),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(l.quranNoResults))
                : ListView.builder(
                    key: const Key('surahList'),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _SurahTile(list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile(this.s);
  final Surah s;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kind = s.isMeccan ? l.quranMeccan : l.quranMedinan;
    return ListTile(
      key: Key('surah-${s.n}'),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Text(context.num(s.n)),
      ),
      title: Text(s.nameAr, textDirection: TextDirection.rtl),
      subtitle: Text('${s.translit} — ${s.nameEn} · ${l.quranAyahCount(context.num(s.ayahCount))} · $kind'),
      onTap: () => openSurah(context, s.n),
      trailing: IconButton(
        key: Key('surahMushaf-${s.n}'),
        tooltip: '${l.homeOpenMushaf}: ${surahName(context, s)}',
        icon: const Icon(Icons.chrome_reader_mode_outlined),
        onPressed: () => openMushafAt(context, AyahRef(s.n, 1)),
      ),
    );
  }
}
