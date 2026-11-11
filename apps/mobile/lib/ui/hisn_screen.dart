import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/adhkar.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart';
import 'dhikr_tools.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'adaptive.dart';
import 'r_icon.dart';

/// Hisn al-Muslim: chapter list with a filter.
class HisnScreen extends StatefulWidget {
  const HisnScreen({super.key, this.section, this.title});

  /// Opens filtered to one section (e.g. 'sleep'), titled [title].
  final String? section;
  final String? title;

  @override
  State<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends State<HisnScreen> {
  String _filter = '';
  late String? _section = widget.section;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final norm = s.content.normalizer;
    final q = norm.normalize(_filter);
    final sections = s.content.adhkar.sections;
    final inSection = sections.where((x) => x.id == _section).firstOrNull?.chapters;
    final chapters = [
      for (final c in s.content.adhkar.hisn)
        if ((inSection == null || inSection.contains(c.index + 1)) &&
            (q.isEmpty || norm.normalize(c.title).contains(q)))
          c,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l.adhkarHisn)),
      body: ReadableWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
              child: TextField(
                key: const Key('hisnFilter'),
                decoration: InputDecoration(labelText: l.adhkarHisnSearch, prefixIcon: const RIcon(RIcons.search)),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            if (sections.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  key: const Key('hisnSections'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                  children: [
                    for (final id in [null, ...sections.map((x) => x.id)])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceXs),
                        child: ChoiceChip(
                          key: Key('hisnSection-${id ?? 'all'}'),
                          label: Text(id == null ? l.hisnSectionAll : hisnSectionName(l, id)),
                          selected: _section == id,
                          onSelected: (_) => setState(() => _section = id),
                        ),
                      ),
                  ],
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
      ),
    );
  }
}

class HisnChapterScreen extends StatelessWidget {
  const HisnChapterScreen({super.key, required this.chapter});
  final HisnChapter chapter;

  Widget _item(BuildContext context, int i) {
    final l = context.l10n;
    final source = l.adhkarShareSourceChapter(chapter.title, context.num(chapter.index + 1));
    return Card(
      key: Key('hisnItem-$i'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(chapter.items[i], textDirection: TextDirection.rtl, style: duaStyle(context)),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                CopyButton(text: chapter.items[i]),
                DhikrActions(
                  text: chapter.items[i],
                  source: source,
                  where: '$source · ${context.num(i + 1)}',
                  keyPrefix: 'hisn$i',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.services.settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title, textDirection: TextDirection.rtl),
        actions: const [AdhkarViewToggle()],
      ),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => settings.adhkarCards
              ? Column(
                  children: [
                    Expanded(
                      child: CardPager(count: chapter.items.length, builder: _item),
                    ),
                  ],
                )
              : ListView(
                  key: const Key('hisnChapter'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [for (var i = 0; i < chapter.items.length; i++) _item(context, i)],
                ),
        ),
      ),
    );
  }
}

/// UI label of a Hisn section id (hisn-sections.json).
String hisnSectionName(AppLocalizations l, String id) => switch (id) {
  'remembrance' => l.hisnSectionRemembrance,
  'morningEvening' => l.hisnSectionMorningEvening,
  'sleep' => l.hisnSectionSleep,
  'prayer' => l.hisnSectionPrayer,
  'home' => l.hisnSectionHome,
  'food' => l.hisnSectionFood,
  'travel' => l.hisnSectionTravel,
  'hardship' => l.hisnSectionHardship,
  'illness' => l.hisnSectionIllness,
  'nature' => l.hisnSectionNature,
  'people' => l.hisnSectionPeople,
  'hajj' => l.hisnSectionHajj,
  _ => id,
};
