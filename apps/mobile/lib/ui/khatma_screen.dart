import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/gregorian_names.dart';
import '../domain/khatma.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'widgets.dart';
import 'adaptive.dart';

const _openingWords = 6;
const _dayPresets = [30, 60, 7];

/// Quran khatma: create a plan, follow and finish today's portion (wird), get
/// a daily reminder, reschedule when late, and the list of finished khatmas.
class KhatmaScreen extends StatelessWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.khatmaTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.khatma,
          builder: (context, _) {
            final k = s.khatma.current;
            return ListView(
              key: const Key('khatmaList'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [if (k == null) const _CreateCard() else ..._current(context, k), const _HistoryCard()],
            );
          },
        ),
      ),
    );
  }

  static String dateText(BuildContext context, DateTime d) =>
      '${context.num(d.day)} ${gregorianMonthName(d.month, arabic: context.isArabic)} ${context.num(d.year)}';

  List<Widget> _current(BuildContext context, Khatma k) {
    final s = context.services;
    final l = context.l10n;
    final today = s.khatma.today;
    final behind = k.behind(today);
    final ahead = k.ahead(today);
    final pct = (k.fraction * 100).round();
    final theme = Theme.of(context);
    final cur = k.wirdPages(k.done);
    final q = s.content.quran;
    final startRef = q.page(cur.from).start;
    final words = q.text(startRef).replaceFirst(RegExp(r'^۞\s*'), '').split(' ');
    final opening = words.take(_openingWords).join(' ') + (words.length > _openingWords ? ' …' : '');
    final rm = k.reminderMinutes;
    return [
      SectionCard(
        key: const Key('khatmaCurrent'),
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 96,
                      child: CircularProgressIndicator(
                        value: k.fraction,
                        strokeWidth: 9,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Text(
                      context.isArabic ? '${context.num(pct)}٪' : '$pct%',
                      key: const Key('khatmaPercent'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(k.name, key: const Key('khatmaName'), style: theme.textTheme.titleLarge),
                        ),
                        IconButton(
                          key: const Key('khatmaRename'),
                          tooltip: l.khatmaRename,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _rename(context, k.name),
                        ),
                      ],
                    ),
                    Text(l.khatmaEndsOn(dateText(context, k.endDate)), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.khatmaRemainingWirds, style: theme.textTheme.bodySmall),
                    Text(
                      context.num(k.wirds - k.done),
                      key: const Key('khatmaRemaining'),
                      style: theme.textTheme.titleMedium,
                    ),
                    LinearProgressIndicator(value: k.done / k.wirds),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.khatmaRemainingDays, style: theme.textTheme.bodySmall),
                    Text(context.num(k.remainingDays(today)), style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          if (behind > 0) ...[
            const SizedBox(height: DesignTokens.spaceSm),
            Container(
              key: const Key('khatmaBehind'),
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(l.khatmaBehind(context.num(behind)))),
                  TextButton(
                    key: const Key('khatmaReschedule'),
                    onPressed: s.khatma.reschedule,
                    child: Text(l.khatmaReschedule),
                  ),
                ],
              ),
            ),
          ],
          if (ahead > 0)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
              child: Text(l.khatmaAhead(context.num(ahead)), key: const Key('khatmaAhead')),
            ),
        ],
      ),
      SectionCard(
        key: const Key('khatmaWird'),
        title: l.khatmaCurrentWird(context.num(k.done + 1), context.num(k.wirds)),
        children: [
          Text(
            '${l.khatmaOpening} $opening',
            key: const Key('khatmaOpening'),
            textDirection: TextDirection.rtl,
            style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'AmiriQuran', height: 2),
          ),
          Text(
            '${l.khatmaJuz(context.num(q.juzOfPage(cur.from)))} · ${_range(context, k, k.done)}',
            key: const Key('khatmaRange'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceSm,
            children: [
              FilledButton.icon(
                key: const Key('khatmaRead'),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => PageReaderScreen(initialPage: cur.from))),
                icon: const Icon(Icons.menu_book),
                label: Text(l.khatmaRead),
              ),
              OutlinedButton.icon(
                key: const Key('khatmaDone'),
                onPressed: s.khatma.completeWird,
                icon: const Icon(Icons.check),
                label: Text(l.khatmaMarkDone),
              ),
            ],
          ),
          ExpansionTile(
            key: const Key('khatmaAll'),
            tilePadding: EdgeInsets.zero,
            title: Text(l.khatmaShowAll),
            children: [
              for (var i = 0; i < k.wirds; i++)
                ListTile(
                  key: ValueKey('khatmaWird-$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    i < k.done ? Icons.check_circle : (i == k.done ? Icons.play_circle : Icons.circle_outlined),
                    color: i <= k.done ? theme.colorScheme.primary : null,
                  ),
                  title: Text(_range(context, k, i)),
                ),
            ],
          ),
        ],
      ),
      SectionCard(
        children: [
          SwitchListTile(
            key: const Key('khatmaReminder'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.khatmaReminder),
            subtitle: rm == null ? null : Text(_hhmm(context, rm), key: const Key('khatmaReminderTime')),
            value: rm != null,
            onChanged: (on) async {
              if (!on) return s.khatma.setReminder(null);
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
              if (t != null) {
                await s.adhan.backend.requestPermission();
                await s.khatma.setReminder(t.hour * 60 + t.minute);
              }
            },
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('khatmaDelete'),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    content: Text(l.khatmaDeleteConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonClose)),
                      TextButton(
                        key: const Key('khatmaDeleteOk'),
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(l.khatmaDelete),
                      ),
                    ],
                  ),
                );
                if (ok == true) await s.khatma.delete();
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l.khatmaDelete),
            ),
          ),
        ],
      ),
    ];
  }

  static String _hhmm(BuildContext context, int minutes) =>
      context.num('${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}');

  static String _range(BuildContext context, Khatma k, int i) {
    final q = context.services.content.quran;
    final p = k.wirdPages(i);
    final a = q.page(p.from).start;
    final b = q.page(p.to).end;
    String name(int n) => context.isArabic ? q.surah(n).nameAr : q.surah(n).translit;
    return context.l10n.khatmaRange(
      name(a.surah),
      context.num(a.ayah),
      context.num(p.from),
      name(b.surah),
      context.num(b.ayah),
      context.num(p.to),
    );
  }

  Future<void> _rename(BuildContext context, String current) async {
    final s = context.services;
    final l = context.l10n;
    final ctl = TextEditingController(text: current);
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.khatmaName),
        content: TextField(
          key: const Key('khatmaNameField'),
          controller: ctl,
          maxLength: maxKhatmaName,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.commonClose)),
          TextButton(
            key: const Key('khatmaNameSave'),
            onPressed: () => Navigator.pop(c, ctl.text),
            child: Text(l.khatmaRename),
          ),
        ],
      ),
    );
    if (v != null) await s.khatma.rename(v);
  }
}

class _CreateCard extends StatefulWidget {
  const _CreateCard();
  @override
  State<_CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<_CreateCard> {
  final _name = TextEditingController();
  bool _byPages = false;
  int _days = 30;
  int _pages = 20;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> set, String key) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        key: Key('$key-minus'),
        icon: const Icon(Icons.remove),
        onPressed: value > min ? () => set(value - 1) : null,
      ),
      Text(context.num(value), key: Key('$key-value'), style: Theme.of(context).textTheme.titleMedium),
      IconButton(
        key: Key('$key-plus'),
        icon: const Icon(Icons.add),
        onPressed: value < max ? () => set(value + 1) : null,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final name = _name.text.trim().isEmpty ? l.khatmaDefaultName : _name.text.trim();
    final plan = _byPages ? Khatma.byPages(name, s.khatma.today, _pages) : Khatma.byDays(name, s.khatma.today, _days);
    final perDay = (mushafPages / plan.wirds).ceil();
    return SectionCard(
      key: const Key('khatmaCreate'),
      title: l.khatmaNew,
      children: [
        TextField(
          key: const Key('khatmaNewName'),
          controller: _name,
          maxLength: maxKhatmaName,
          decoration: InputDecoration(labelText: l.khatmaName, hintText: l.khatmaDefaultName),
          onChanged: (_) => setState(() {}),
        ),
        SegmentedButton<bool>(
          key: const Key('khatmaMode'),
          segments: [
            ButtonSegment(value: false, label: Text(l.khatmaByDays)),
            ButtonSegment(value: true, label: Text(l.khatmaByPages)),
          ],
          selected: {_byPages},
          onSelectionChanged: (v) => setState(() => _byPages = v.first),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        if (_byPages)
          _stepper(
            l.khatmaPagesPerDay,
            _pages,
            minPagesPerDay,
            maxPagesPerDay,
            (v) => setState(() => _pages = v),
            'khatmaPages',
          )
        else ...[
          _stepper(l.khatmaDays, _days, minKhatmaDays, maxKhatmaDays, (v) => setState(() => _days = v), 'khatmaDays'),
          Wrap(
            spacing: DesignTokens.spaceSm,
            children: [
              for (final d in _dayPresets)
                ActionChip(
                  key: Key('khatmaPreset-$d'),
                  label: Text(l.khatmaDaysN(context.num(d))),
                  onPressed: () => setState(() => _days = d),
                ),
            ],
          ),
        ],
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l.khatmaPreview(
            context.num(plan.wirds),
            context.num(math.max(1, perDay)),
            KhatmaScreen.dateText(context, plan.endDate),
          ),
          key: const Key('khatmaPreview'),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        FilledButton(key: const Key('khatmaStart'), onPressed: () => s.khatma.start(plan), child: Text(l.khatmaStart)),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final h = s.khatma.state.history;
    return SectionCard(
      key: const Key('khatmaHistory'),
      title: l.khatmaHistory,
      children: [
        if (h.isEmpty) Text(l.khatmaHistoryEmpty),
        for (final x in h)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_outlined),
            title: Text(x.name),
            subtitle: Text(l.khatmaFinishedOn(KhatmaScreen.dateText(context, x.finishedDate), context.num(x.days))),
          ),
      ],
    );
  }
}
