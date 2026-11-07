import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/adhkar.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';

/// Hisn al-Muslim: chapter list with a filter.
class HisnScreen extends StatefulWidget {
  const HisnScreen({super.key});

  @override
  State<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends State<HisnScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final norm = s.content.normalizer;
    final q = norm.normalize(_filter);
    final chapters = [
      for (final c in s.content.adhkar.hisn)
        if (q.isEmpty || norm.normalize(c.title).contains(q)) c,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.adhkarHisn)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
            child: TextField(
              key: const Key('hisnFilter'),
              decoration: InputDecoration(labelText: l.adhkarHisnSearch, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          if (!context.isArabic) ReviewNotice(l.adhkarArabicOnly),
          Expanded(
            child: chapters.isEmpty
                ? Center(child: Text(l.quranNoResults))
                : ListView.builder(
                    key: const Key('hisnList'),
                    itemCount: chapters.length,
                    itemBuilder: (context, i) {
                      final c = chapters[i];
                      return ListTile(
                        key: Key('hisn-${c.index}'),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                          child: Text(context.num(c.index + 1)),
                        ),
                        title: Text(c.title, textDirection: TextDirection.rtl),
                        subtitle: Text(l.adhkarHisnCount(context.num(c.items.length))),
                        onTap: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute<void>(builder: (_) => HisnChapterScreen(chapter: c))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class HisnChapterScreen extends StatelessWidget {
  const HisnChapterScreen({super.key, required this.chapter});
  final HisnChapter chapter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title, textDirection: TextDirection.rtl)),
      body: ListView(
        key: const Key('hisnChapter'),
        padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
        children: [
          ReviewNotice(l.adhkarReviewNotice),
          for (var i = 0; i < chapter.items.length; i++)
            Card(
              key: Key('hisnItem-$i'),
              margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(chapter.items[i], textDirection: TextDirection.rtl, style: duaStyle(context)),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: CopyButton(text: chapter.items[i]),
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
