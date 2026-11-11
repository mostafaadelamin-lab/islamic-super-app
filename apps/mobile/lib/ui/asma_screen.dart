import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'speech.dart';

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

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

/// أسماء الله الحسنى: every name with a short explanation under it.
class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key, this.loader = loadAsma, this.speaker});
  final Future<List<AsmaEntry>> Function() loader;
  final Speaker? speaker;

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  late final Future<List<AsmaEntry>> _future = widget.loader();
  String _query = '';
  late final Speaker _speaker = widget.speaker ?? DeviceSpeaker();
  String? _speaking;

  @override
  void initState() {
    super.initState();
    _speaker.onDone(() {
      if (mounted) setState(() => _speaking = null);
    });
  }

  @override
  void dispose() {
    _speaker.stop();
    super.dispose();
  }

  Future<void> _toggle(AsmaEntry e, String text) async {
    if (_speaking == e.name) {
      await _speaker.stop();
      setState(() => _speaking = null);
      return;
    }
    await _speaker.stop();
    setState(() => _speaking = e.name);
    final ok = await _speaker.speak('${e.name}. $text');
    if (!ok && mounted) {
      setState(() => _speaking = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.asmaNoVoice)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.asmaTitle)),
      body: ReadableWidth(
        child: FutureBuilder<List<AsmaEntry>>(
          future: _future,
          builder: (context, snap) {
            final all = snap.data;
            if (all == null) return const Center(child: CircularProgressIndicator());
            final byName = {for (final e in all) e.name: e};
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
                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
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
                            IconButton(
                              key: Key('asmaListen-${i - 1}'),
                              tooltip: _speaking == e.name ? l.asmaStop : l.asmaListen,
                              color: scheme.primary,
                              icon: RIcon(_speaking == e.name ? RIcons.stop : RIcons.headphones),
                              onPressed: () => _toggle(e, text),
                            ),
                          ],
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
