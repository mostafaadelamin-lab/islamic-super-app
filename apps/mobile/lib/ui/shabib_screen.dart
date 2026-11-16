import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/shabib.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'stories_screen.dart' show NarrationBar;

const shabibSeries = 'shabib';

Future<ShabibRecitations> loadShabib() async =>
    ShabibRecitations.parse(await rootBundle.loadString('assets/content/shabib.v1.json'));

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

extension ShabibText on BuildContext {
  String _surahName(int n) {
    final s = services.content.quran.surahs[n - 1];
    return isArabic ? s.nameAr : s.nameEn;
  }

  /// "سورة يوسف" / "ما تيسّر من سورة البقرة" / "سور الصف والجمعة" / "قصار السور".
  String shabibTitle(ShabibTrack x) {
    final l = l10n;
    if (x.surahs.isEmpty) return l.shabibShortSurahs;
    final names = [for (final n in x.surahs) _surahName(n)];
    if (names.length == 1) return x.part ? l.shabibFromSurah(names.first) : l.shabibSurah(names.first);
    return l.shabibSurahs(names.join(isArabic ? ' و' : ', '));
  }

  String shabibSubtitle(ShabibTrack x) {
    final l = l10n;
    final tag = switch (x.tag) {
      'fajr' => l.shabibTagFajr,
      'radio' => l.shabibTagRadio,
      'oct73' => l.shabibTagOct73,
      _ => null,
    };
    return [
      ?tag,
      if (x.year != null) this.num(x.year!),
      if (x.seconds > 0) l.sharawiMinutes(this.num((x.seconds / 60).round().clamp(1, 1 << 30))),
    ].join(' · ');
  }
}

/// Episode for the shared audio player (streams, or plays the offline copy).
Episode shabibEpisode(BuildContext context, ShabibTrack x) {
  final title = '${context.l10n.shabibReciter} · ${context.shabibTitle(x)}';
  return Episode(
    id: 'shabib-${x.id}',
    titleAr: title,
    titleEn: title,
    url: x.url,
    durationSec: x.seconds,
    status: ReviewStatus.approved,
  );
}

/// Sheikh Mohamed Ahmed Shabib, opened from his row in the recitation library: his murattal surahs and his
/// mujawwad recitations.
class ShabibScreen extends StatefulWidget {
  const ShabibScreen({super.key, this.loader = loadShabib});
  final Future<ShabibRecitations> Function() loader;

  @override
  State<ShabibScreen> createState() => _ShabibScreenState();
}

class _ShabibScreenState extends State<ShabibScreen> {
  late final Future<ShabibRecitations> _future = widget.loader();
  ShabibKind _kind = ShabibKind.murattal;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.shabibName)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: FutureBuilder<ShabibRecitations>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(l.shabibLoadError));
            final all = snap.data;
            if (all == null) return const Center(child: CircularProgressIndicator());
            final q = _norm(_query.trim().toLowerCase());
            final own = all.of(_kind);
            final list = [
              for (final x in own)
                if (q.isEmpty ||
                    _norm(context.shabibTitle(x).toLowerCase()).contains(q) ||
                    x.surahs.any((n) => '$n' == q || context.num(n) == q))
                  x,
            ];
            return ListenableBuilder(
              listenable: context.services.narration,
              builder: (context, _) {
                // The whole list in order: one recitation goes straight on to the next.
                final episodes = [for (final x in own) shabibEpisode(context, x)];
                final byId = {for (final (i, x) in own.indexed) x.id: episodes[i]};
                return ListView(
                  key: const Key('shabibList'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceMd,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                      ),
                      child: Text(
                        l.shabibNote(context.num(all.murattal.length), context.num(all.mujawwad.length)),
                        key: const Key('shabibNote'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                      child: SegmentedButton<ShabibKind>(
                        key: const Key('shabibKind'),
                        segments: [
                          ButtonSegment(
                            value: ShabibKind.murattal,
                            label: Text('${l.shabibMurattal} (${context.num(all.murattal.length)})'),
                          ),
                          ButtonSegment(
                            value: ShabibKind.mujawwad,
                            label: Text('${l.shabibMujawwad} (${context.num(all.mujawwad.length)})'),
                          ),
                        ],
                        selected: {_kind},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _kind = s.first),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                      ),
                      child: Text(
                        _kind == ShabibKind.murattal ? l.shabibMurattalNote : l.shabibMujawwadNote,
                        key: const Key('shabibKindNote'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                      child: TextField(
                        key: const Key('shabibSearch'),
                        decoration: InputDecoration(
                          prefixIcon: const RIcon(RIcons.search),
                          hintText: l.sharawiSearch,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    for (final x in list)
                      PlayTile(
                        key: Key('shabib-${x.id}'),
                        series: shabibSeries,
                        offline: true,
                        title: context.shabibTitle(x),
                        subtitle: context.shabibSubtitle(x),
                        episode: byId[x.id]!,
                        playlist: episodes,
                      ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(DesignTokens.spaceLg),
                        child: Text(l.shabibNoMatch, key: const Key('shabibEmpty')),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
