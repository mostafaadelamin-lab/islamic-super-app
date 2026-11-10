import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/adhan_voices.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// Picks the muezzin for the adhan, or for the Fajr adhan when [fajr]: the
/// bundled voices first, then the whole collection. Tapping a muezzin that is
/// not on the phone yet downloads it and then chooses it.
class MuezzinScreen extends StatefulWidget {
  const MuezzinScreen({super.key, required this.fajr});
  final bool fajr;

  @override
  State<MuezzinScreen> createState() => _MuezzinScreenState();
}

class _MuezzinScreenState extends State<MuezzinScreen> {
  List<AdhanVoice>? _all;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_all != null) return;
    _all = const [];
    context.services.adhanVoices.catalog().then((c) {
      if (mounted) setState(() => _all = c);
    });
  }

  Future<void> _choose(AdhanVoice v) async {
    final s = context.services;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!s.adhanVoices.isReady(v.id) && !await s.adhanVoices.download(v.id)) {
      messenger.showSnackBar(SnackBar(content: Text(l.adhanVoiceDownloadFailed)));
      return;
    }
    await s.settings.setAdhanVoice(v.id, fajr: widget.fajr);
  }

  static String _norm(String s) => s
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp('[ً-ْ]'), '')
      .toLowerCase();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final q = _norm(_query.trim());
    final voices = [
      for (final v in _all ?? const <AdhanVoice>[])
        if (v.fajr == widget.fajr || (!widget.fajr && v.bundled && !v.fajr))
          if (q.isEmpty || _norm('${v.nameAr} ${v.nameEn} ${v.place}').contains(q)) v,
    ];
    // Several recordings of one muezzin are numbered 1, 2, …
    final count = <String, int>{};
    for (final v in voices) {
      count[v.nameAr] = (count[v.nameAr] ?? 0) + 1;
    }
    final seen = <String, int>{};
    return Scaffold(
      appBar: AppBar(title: Text(widget.fajr ? l.adhanFajrVoice : l.adhanVoice)),
      body: ListenableBuilder(
        listenable: Listenable.merge([s.settings, s.adhanVoices, s.adhanPreview]),
        builder: (context, _) {
          final selected = widget.fajr ? s.settings.adhanFajrVoice : s.settings.adhanVoice;
          return ListView.builder(
            key: const Key('muezzinList'),
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            itemCount: voices.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fajr ? l.adhanFajrVoiceNote : l.adhanVoiceNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: DesignTokens.spaceSm),
                      TextField(
                        key: const Key('muezzinSearch'),
                        decoration: InputDecoration(
                          prefixIcon: const RIcon(RIcons.search),
                          hintText: l.adhanVoiceSearch,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                );
              }
              final v = voices[i - 1];
              final n = (seen[v.nameAr] = (seen[v.nameAr] ?? 0) + 1);
              final numbered = (count[v.nameAr] ?? 0) > 1 ? ' (${context.num(n)})' : '';
              return _MuezzinTile(
                voice: v,
                title: '${v.name(context.isArabic)}$numbered',
                selected: v.id == selected,
                onTap: () => _choose(v),
              );
            },
          );
        },
      ),
    );
  }
}

class _MuezzinTile extends StatelessWidget {
  const _MuezzinTile({required this.voice, required this.title, required this.selected, required this.onTap});
  final AdhanVoice voice;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final files = s.adhanVoices;
    final downloading = files.isDownloading(voice.id);
    final ready = files.isReady(voice.id);
    final playing = s.adhanPreview.voice == voice.id;
    final subtitle = [
      if (voice.place.isNotEmpty) voice.place,
      if (voice.bundled) l.adhanVoiceBundled else if (ready) l.adhanVoiceDownloaded else l.adhanVoiceTapToDownload,
    ].join(' · ');
    return ListTile(
      key: Key('muezzin-${voice.id}'),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
      leading: downloading
          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : RIcon(
              selected ? RIcons.checkCircle : (ready ? RIcons.radioOff : RIcons.download),
              color: selected ? scheme.primary : null,
            ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        key: Key('muezzinPlay-${voice.id}'),
        tooltip: l.adhanVoiceListen(title),
        icon: RIcon(playing ? RIcons.stop : RIcons.play),
        onPressed: downloading ? null : () => s.adhanPreview.toggle(voice.id),
      ),
      onTap: downloading ? null : onTap,
    );
  }
}
