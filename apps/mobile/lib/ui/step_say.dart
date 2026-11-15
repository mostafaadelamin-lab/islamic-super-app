import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/step_duas.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart' show CopyButton;
import 'hajj_art.dart';
import 'l10n_ext.dart';
import 'reader_widgets.dart' show AyahTextBlock;
import 'review_notice.dart' show duaStyle;

/// The picture of where a step of a Hajj kind happens: our own drawings, picked from the step's words.
HajjScene? hajjSceneForStep(String title) {
  const words = {
    'الوداع': HajjScene.farewell,
    'طواف': HajjScene.tawaf,
    'سعي': HajjScene.sai,
    'رمي': HajjScene.jamarat,
    'عرفة': HajjScene.arafah,
    'ذبح': HajjScene.nahr,
    'الحلق': HajjScene.halq,
    'منى': HajjScene.mina,
    'الإحرام': HajjScene.ihram,
  };
  for (final e in words.entries) {
    if (title.contains(e.key)) return e.value;
  }
  return hajjSceneFor(title);
}

/// Everything said at a step's places, in full, each under its Hisn al-Muslim heading (owner 2026-11-15).
class StepSay extends StatelessWidget {
  const StepSay({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final groups = context.services.content.stepDuas.forStep(title);
    if (groups.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        key: const Key('stepSay'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: DesignTokens.spaceXl),
          Text(context.l10n.hajjSayTitle, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
          for (final g in groups) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Text(g.title, style: theme.textTheme.titleSmall),
            for (final x in g.say) _SayView(item: x),
          ],
        ],
      ),
    );
  }
}

class _SayView extends StatelessWidget {
  const _SayView({required this.item});
  final SayItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shaded = BoxDecoration(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
    );
    const gap = EdgeInsets.only(top: DesignTokens.spaceSm);
    if (item.ayah case final ref?) {
      final surah = context.services.content.quran.surah(ref.surah);
      return Container(
        key: const Key('sayQuran'),
        margin: gap,
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: shaded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AyahTextBlock(ref: ref, size: 22),
            Text(
              '[${surah.nameAr}: ${_arabic(ref.ayah)}]',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    final text = item.text ?? '';
    return switch (item.kind) {
      SayKind.dua => Container(
        key: const Key('sayDua'),
        margin: gap,
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: shaded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: duaStyle(context).copyWith(color: scheme.onSecondaryContainer)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CopyButton(text: text),
            ),
          ],
        ),
      ),
      SayKind.hadith => Container(
        key: const Key('sayHadith'),
        margin: gap,
        padding: const EdgeInsetsDirectional.only(start: DesignTokens.spaceMd),
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: scheme.secondary, width: 3)),
        ),
        child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.9)),
      ),
      SayKind.note => Padding(
        padding: gap,
        child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ),
    };
  }

  static String _arabic(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
}
