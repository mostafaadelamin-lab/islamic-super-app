import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/adhkar.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// «أذكاري» (owner 2026-11-26): the user adds their own dhikr to morning/evening adhkar,
/// with how many times and in which session(s). Kept on the device only.

/// Opens the add sheet (or the edit sheet for [existing]).
Future<void> showCustomDhikrSheet(BuildContext context, AdhkarSession session, {UserDhikr? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CustomDhikrSheet(session: session, existing: existing),
    );

class CustomDhikrSheet extends StatefulWidget {
  const CustomDhikrSheet({super.key, required this.session, this.existing});
  final AdhkarSession session;
  final UserDhikr? existing;

  @override
  State<CustomDhikrSheet> createState() => _CustomDhikrSheetState();
}

const _quickCounts = [1, 3, 7, 10, 33, 100];

class _CustomDhikrSheetState extends State<CustomDhikrSheet> {
  late final TextEditingController _text = TextEditingController(text: widget.existing?.text ?? '');
  late int _count = widget.existing?.count ?? 1;
  late Set<AdhkarSession> _sessions = {...?widget.existing?.sessions};

  @override
  void initState() {
    super.initState();
    if (_sessions.isEmpty) _sessions = {widget.session};
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setCount(int n) => setState(() => _count = n.clamp(1, UserDhikr.maxCount));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canSave = _text.text.trim().isNotEmpty;
    final both = _sessions.length == 2;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? l.adhkarMineAdd : l.adhkarMineEditTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('customDhikrClose'),
                    tooltip: l.adhkarMineCancel,
                    icon: const RIcon(RIcons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(l.adhkarMineHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.primary)),
              const SizedBox(height: DesignTokens.spaceMd),
              TextField(
                key: const Key('customDhikrText'),
                controller: _text,
                autofocus: widget.existing == null,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: l.adhkarMineTextHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(l.adhkarMineCount, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DesignTokens.spaceXs),
              Row(
                children: [
                  IconButton.filledTonal(
                    key: const Key('customDhikrMinus'),
                    tooltip: l.adhkarMineLess,
                    icon: const RIcon(RIcons.minus),
                    onPressed: _count > 1 ? () => _setCount(_count - 1) : null,
                  ),
                  Expanded(
                    child: Text(
                      l.adhkarMineTimes(context.num('$_count')),
                      key: const Key('customDhikrCount'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const Key('customDhikrPlus'),
                    tooltip: l.adhkarMineMore,
                    icon: const RIcon(RIcons.plus),
                    onPressed: _count < UserDhikr.maxCount ? () => _setCount(_count + 1) : null,
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              Wrap(
                spacing: DesignTokens.spaceXs,
                alignment: WrapAlignment.center,
                children: [
                  for (final n in _quickCounts)
                    ChoiceChip(
                      key: Key('customDhikrQuick-$n'),
                      label: Text(context.num('$n')),
                      selected: _count == n,
                      onSelected: (_) => _setCount(n),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              Text(l.adhkarMineShowIn, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DesignTokens.spaceXs),
              SegmentedButton<String>(
                key: const Key('customDhikrSessions'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'morning', label: Text(l.adhkarMorning)),
                  ButtonSegment(value: 'evening', label: Text(l.adhkarEvening)),
                  ButtonSegment(value: 'both', label: Text(l.adhkarMineBoth)),
                ],
                selected: {both ? 'both' : _sessions.single.name},
                onSelectionChanged: (v) => setState(() {
                  _sessions = switch (v.single) {
                    'morning' => {AdhkarSession.morning},
                    'evening' => {AdhkarSession.evening},
                    _ => {AdhkarSession.morning, AdhkarSession.evening},
                  };
                }),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              FilledButton(
                key: const Key('customDhikrSave'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: canSave
                    ? () async {
                        final nav = Navigator.of(context);
                        await context.services.adhkar.saveCustom(
                          id: widget.existing?.id,
                          text: _text.text,
                          count: _count,
                          sessions: _sessions,
                        );
                        nav.pop();
                      }
                    : null,
                child: Text(l.adhkarMineSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «أذكاري» heading shown above the first user-added dhikr.
class CustomAdhkarHeader extends StatelessWidget {
  const CustomAdhkarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('customAdhkarHeader'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, 0),
      child: Row(
        children: [
          Text(context.l10n.adhkarMine, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: DesignTokens.spaceSm),
          const CustomAdhkarTag(),
        ],
      ),
    );
  }
}

/// Small «أضفتها أنت» label.
class CustomAdhkarTag extends StatelessWidget {
  const CustomAdhkarTag({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        context.l10n.adhkarMineTag,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

/// The big «أضف ذكرًا من عندك» button at the end of the list.
class AddCustomDhikrButton extends StatelessWidget {
  const AddCustomDhikrButton({super.key, required this.session});
  final AdhkarSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, 0),
      child: OutlinedButton.icon(
        key: const Key('customDhikrAddBig'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: scheme.secondary,
          side: BorderSide(color: scheme.secondary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
        ),
        icon: const RIcon(RIcons.plus),
        label: Text(context.l10n.adhkarMineAddLong),
        onPressed: () => showCustomDhikrSheet(context, session),
      ),
    );
  }
}

/// Edit / delete under a user-added dhikr.
class CustomDhikrTools extends StatelessWidget {
  const CustomDhikrTools({super.key, required this.dhikr, required this.session});
  final Dhikr dhikr;
  final AdhkarSession session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final id = dhikr.index - userDhikrBase;
    final item = s.adhkar.custom.where((d) => d.id == id).firstOrNull;
    if (item == null) return const SizedBox.shrink();
    return Wrap(
      children: [
        TextButton.icon(
          key: Key('customDhikrEdit-$id'),
          icon: const RIcon(RIcons.edit, size: 18),
          label: Text(l.adhkarMineEdit),
          onPressed: () => showCustomDhikrSheet(context, session, existing: item),
        ),
        TextButton.icon(
          key: Key('customDhikrDelete-$id'),
          icon: const RIcon(RIcons.trash, size: 18),
          label: Text(l.adhkarMineDelete),
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                content: Text(l.adhkarMineDeleteAsk),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.adhkarMineCancel)),
                  TextButton(
                    key: const Key('customDhikrDeleteYes'),
                    onPressed: () => Navigator.of(c).pop(true),
                    child: Text(l.adhkarMineDelete),
                  ),
                ],
              ),
            );
            if (yes == true) await s.adhkar.deleteCustom(id);
          },
        ),
      ],
    );
  }
}
