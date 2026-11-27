import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/reels.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'reels_screen.dart';

/// The reciters list (owner 2026-11-27, mockup page 3): every reciter by group, each with a
/// switch to show or hide their recitations. Channels the viewer added come last.
class RecitersScreen extends StatelessWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final feed = context.services.reelsFeed;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reelsReciters),
        actions: [
          IconButton(
            key: const Key('reciters.add'),
            tooltip: l.reelsAddChannel,
            icon: const RIcon(RIcons.plus),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const ChannelSearchSheet(),
            ),
          ),
        ],
      ),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: feed,
          builder: (context, _) {
            final ar = context.isArabic;
            final hidden = feed.hidden;
            final all = feed.sources;
            final groups = [...Reel.groups, null];
            return ListView(
              key: const Key('reciters.list'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceMd,
                    DesignTokens.spaceLg,
                    0,
                  ),
                  child: Text(l.reelsRecitersHint, style: Theme.of(context).textTheme.bodyMedium),
                ),
                for (final g in groups) ...[
                  if (all.any((s) => s.group == g)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceLg,
                        4,
                      ),
                      child: Text(
                        g == null
                            ? l.reelsMyChannels
                            : '${reelGroupLabel(l, g)} (${context.num(all.where((s) => s.group == g).length)})',
                        key: Key('reciters.group.${g ?? 'mine'}'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final s in all.where((s) => s.group == g))
                      SwitchListTile(
                        key: Key('reciters.toggle.${s.id}'),
                        title: Text(s.name(ar)),
                        subtitle: Text(hidden.contains(s.id) ? l.reelsHiddenLabel : l.reelsShown),
                        value: !hidden.contains(s.id),
                        onChanged: (on) => on ? feed.unhide(s.id) : feed.hide(s.id),
                      ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
