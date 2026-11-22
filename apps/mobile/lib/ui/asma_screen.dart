import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'dhikr_audio.dart';
import 'r_icon.dart';

/// One of the 99 names with its simplified explanation, quoted verbatim from a
/// published source (see docs/CONTENT_SOURCES.md; never written by us).
class AsmaEntry {
  const AsmaEntry({required this.name, required this.text, this.group, this.seeAlso, required this.page});
  final String name;
  final String? text;
  final String? group;
  final String? seeAlso;
  final int page;

  static List<AsmaEntry> parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final e in j['names'] as List)
        AsmaEntry(
          name: e['name'] as String,
          text: e['text'] as String?,
          group: e['group'] as String?,
          seeAlso: e['seeAlso'] as String?,
          page: e['printedPage'] as int,
        ),
    ];
  }
}

Future<List<AsmaEntry>> loadAsma() async => AsmaEntry.parse(await rootBundle.loadString('assets/content/asma.v1.json'));

/// Recorded lessons on each name by Sheikh Muhammad Ratib al-Nabulsi, by index in asma.v1.json
/// (built by tools/asma_audio.py; 1 or 2 parts per name; some names have none).
Future<Map<int, List<String>>> loadAsmaLessons() async {
  try {
    final j = jsonDecode(await rootBundle.loadString('assets/content/asma-audio.v1.json')) as Map<String, dynamic>;
    return {
      for (final e in (j['names'] as Map<String, dynamic>).entries)
        int.parse(e.key): (e.value as List<dynamic>).cast<String>(),
    };
  } catch (_) {
    return const {};
  }
}

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

/// أسماء الله الحسنى: every name with a short explanation under it.
class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key, this.loader = loadAsma, this.lessons = loadAsmaLessons});
  final Future<List<AsmaEntry>> Function() loader;
  final Future<Map<int, List<String>>> Function() lessons;

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  late final Future<List<AsmaEntry>> _future = widget.loader();
  String _query = '';
  late final Future<Map<int, List<String>>> _lessons = widget.lessons();
  Map<int, List<String>> _byIndex = const {};

  @override
  void initState() {
    super.initState();
    _lessons.then((m) {
      if (mounted) setState(() => _byIndex = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return StopDhikrAudioOnExit(
      child: Scaffold(
        appBar: AppBar(title: Text(l.asmaTitle)),
        body: ReadableWidth(
          child: FutureBuilder<List<AsmaEntry>>(
            future: _future,
            builder: (context, snap) {
              final all = snap.data;
              if (all == null) return const Center(child: CircularProgressIndicator());
              final byName = {for (final e in all) e.name: e};
              final indexOf = {for (var k = 0; k < all.length; k++) all[k].name: k};
              final q = _norm(_query.trim());
              final list = [
                for (final e in all)
                  if (q.isEmpty || _norm('${e.name} ${e.group ?? ''}').contains(q)) e,
              ];
              return ListView.builder(
                key: const Key('asmaList'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                itemCount: list.length + 2,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceMd,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                      ),
                      child: TextField(
                        key: const Key('asmaSearch'),
                        decoration: InputDecoration(
                          prefixIcon: const RIcon(RIcons.search),
                          hintText: l.asmaSearch,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    );
                  }
                  if (i == list.length + 1) {
                    return Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Text(
                        l.asmaSource,
                        key: const Key('asmaSource'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  final e = list[i - 1];
                  final target = e.text == null && e.seeAlso != null ? byName[e.seeAlso] : null;
                  final text = e.text ?? target?.text ?? '';
                  return Card(
                    key: Key('asma-${i - 1}'),
                    margin: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                      vertical: DesignTokens.spaceXs,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
                                child: Text(
                                  context.num('$i'),
                                  style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: DesignTokens.spaceMd),
                              Expanded(
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontFamily: DesignTokens.fontQuran,
                                    fontSize: 26,
                                    height: 1.6,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _Lessons(
                            name: e.name,
                            urls: _byIndex[indexOf[e.name]] ?? const [],
                            keyPrefix: 'asmaListen-${i - 1}',
                          ),
                          if (e.group != null && e.group != e.name)
                            Text(
                              e.group!,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.secondary),
                            ),
                          const SizedBox(height: DesignTokens.spaceSm),
                          _Explanation(text: text, seeAlso: target == null ? null : l.asmaSeeAlso(target.name)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "Listen to the explanation" by Sheikh al-Nabulsi: one button per recorded lesson on this name.
/// The player opens right here, under this name (owner 2026-11-22), not on another page.
class _Lessons extends StatelessWidget {
  const _Lessons({required this.name, required this.urls, required this.keyPrefix});
  final String name;
  final List<String> urls;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final player = DhikrPlayer.instance;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
        padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.spaceSm,
          children: [
            Text(l.asmaLessonBy, style: Theme.of(context).textTheme.labelMedium),
            for (var k = 0; k < urls.length; k++)
              Builder(
                builder: (context) {
                  final on = player.url == urls[k] && (player.playing || player.loading);
                  final label = urls.length == 1 ? l.asmaListenLesson : l.asmaPart(context.num('${k + 1}'));
                  return TextButton.icon(
                    key: Key(k == 0 ? keyPrefix : '$keyPrefix-${k + 1}'),
                    onPressed: () => player.toggle(
                      urls[k],
                      title: urls.length == 1 ? l.asmaLessonTitle(name) : '${l.asmaLessonTitle(name)} · $label',
                      subtitle: l.asmaLessonBy,
                    ),
                    icon: RIcon(on ? RIcons.stop : RIcons.headphones, size: 20),
                    label: Text(on ? l.asmaStop : label),
                  );
                },
              ),
          ],
        ),
          ),
          if (player.active && urls.contains(player.url))
            const Padding(
              padding: EdgeInsets.only(top: DesignTokens.spaceXs),
              child: DhikrPlayerBar(inline: true),
            ),
        ],
      ),
    );
  }
}

/// The explanation, folded to four lines with "more" when it is long.
class _Explanation extends StatefulWidget {
  const _Explanation({required this.text, this.seeAlso});
  final String text;
  final String? seeAlso;

  @override
  State<_Explanation> createState() => _ExplanationState();
}

class _ExplanationState extends State<_Explanation> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8);
    final long = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.seeAlso != null) Text(widget.seeAlso!, style: Theme.of(context).textTheme.labelMedium),
        Text(
          widget.text,
          style: style,
          maxLines: long && !_open ? 4 : null,
          overflow: long && !_open ? TextOverflow.ellipsis : TextOverflow.visible,
        ),
        if (long)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            onPressed: () => setState(() => _open = !_open),
            child: Text(_open ? context.l10n.asmaLess : context.l10n.asmaMore),
          ),
      ],
    );
  }
}
