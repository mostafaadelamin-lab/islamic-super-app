import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'share_capture.dart';

/// "Share as image": a preview of the ayah on a card in the Rattil colours (the
/// stored text unchanged, display map applied as everywhere else) and a button
/// that sends the PNG to the system share sheet.
class AyahImageScreen extends StatefulWidget {
  const AyahImageScreen({super.key, required this.ayah});
  final AyahRef ayah;

  @override
  State<AyahImageScreen> createState() => _AyahImageScreenState();
}

class _AyahImageScreenState extends State<AyahImageScreen> {
  final _cardKey = GlobalKey();

  String _reference() {
    final q = context.services.content.quran;
    return '﴿${q.surah(widget.ayah.surah).nameAr}: ${toArabicIndic(widget.ayah.ayah)}﴾';
  }

  Future<void> _share() async {
    final s = context.services;
    final png = await capturePng(_cardKey, pixelRatio: 3);
    if (png == null || !mounted) return;
    final r = widget.ayah;
    await s.sharer.sharePng(
      png,
      fileName: 'rattil-${r.surah}-${r.ayah}.png',
      text: '${s.content.quran.text(r)} ${_reference()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final c = DesignTokens.light;
    final text = s.content.renderMap.forDisplay(s.content.quran.text(widget.ayah));
    return Scaffold(
      appBar: AppBar(title: Text(l.mushafShareImageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              key: const Key('ayahImage.card'),
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              color: c['paper'],
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: c['frame']!, width: 2)),
                padding: const EdgeInsets.all(DesignTokens.spaceXs),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: c['frame']!, width: 0.6)),
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXl),
                  child: Column(
                    children: [
                      Text(
                        text,
                        key: const Key('ayahImage.text'),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontQuran,
                          fontSize: 26,
                          height: 2,
                          color: c['paperInk'],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Text(
                        _reference(),
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: c['primary'], fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(l.appName, style: TextStyle(color: c['frame'], fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          FilledButton.icon(
            key: const Key('ayahImage.share'),
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: Text(l.mushafShareNow),
          ),
        ],
      ),
    );
  }
}
