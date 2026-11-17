import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/zakat_simple.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';

/// Zakat calculator, simplified on the owner's request (2026-11-11): money, gold, silver, livestock and
/// crops; since 2026-11-17 all on one screen, each with its zakat beside it and the total at the bottom. Rules: lib/domain/zakat_simple.dart.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  static const _key = 'zakat.simple';
  Map<String, dynamic> _v = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_v.isEmpty) {
      try {
        _v = jsonDecode(context.services.settings.rawJson(_key) ?? '{}') as Map<String, dynamic>;
      } catch (_) {
        _v = {};
      }
    }
  }

  double? _d(String k) => (_v[k] as num?)?.toDouble();
  void _set(String k, Object? v) {
    setState(() => v == null ? _v.remove(k) : _v[k] = v);
    context.services.settings.setRawJson(_key, jsonEncode(_v));
  }

  String _fmt(BuildContext context, double v, {int digits = 2}) {
    final t = v == v.roundToDouble()
        ? v.round().toString()
        : v.toStringAsFixed(digits).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return context.num(t);
  }

  Widget _number(String key, String label, {String? suffix}) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
    child: TextFormField(
      key: Key('zakat.$key'),
      initialValue: _d(key) == null ? '' : _fmtRaw(_d(key)!),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
      onChanged: (t) => _set(key, double.tryParse(_ascii(t.trim()))),
    ),
  );

  static String _fmtRaw(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
  static String _ascii(String t) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final c in t.split('')) {
      final i = ar.indexOf(c);
      b.write(i >= 0 ? '$i' : (c == '٫' || c == ',' ? '.' : c));
    }
    return b.toString();
  }

  /// One kind of zakat as a card: its name with the zakat due on it beside it, then its fields.
  Widget _section(BuildContext context, String id, String title, String due, bool reached, List<Widget> children) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: Key('zakatSection-$id'),
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Container(
                  key: Key('zakatDue-$id'),
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceXs),
                  decoration: BoxDecoration(
                    color: reached ? _calm(scheme).withValues(alpha: 0.14) : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Text(
                    due,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: reached ? _calm(scheme) : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            ...children,
            const SizedBox(height: DesignTokens.spaceMd),
          ],
        ),
      ),
    );
  }

  /// The distinct, calm colour of the amounts due (a soft teal, readable in light and dark).
  static Color _calm(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark ? const Color(0xFF7CC8BE) : const Color(0xFF2E7D74);

  String _g(BuildContext context, double v) => context.l10n.zakatDueShortGrams(_fmt(context, v));
  String _m(BuildContext context, double v) => context.l10n.zakatDueShortMoney(_fmt(context, v, digits: 0));

  /// What is due on each kind, for its header and the total: money (EGP) and the dues not priced in money.
  ({double money, List<String> other, bool any}) _totals = (money: 0, other: const [], any: false);

  Widget _gold(BuildContext context, void Function(double? money, String? other, bool entered) add) {
    final l = context.l10n;
    final grams = _d('gold') ?? 0;
    final karat = (_v['karat'] as int?) ?? 21;
    final r = goldZakat(grams, karat, _d('goldPrice'));
    final reached = grams > 0 && r.reached;
    add(
      reached ? r.dueMoney : null,
      reached && r.dueMoney == null ? '${_g(context, r.dueGrams)} (${l.zakatTabGold})' : null,
      grams > 0,
    );
    final due = grams <= 0
        ? l.zakatDueEmpty
        : !r.reached
        ? l.zakatDueNone
        : r.dueMoney != null
        ? _m(context, r.dueMoney!)
        : _g(context, r.dueGrams);
    return _section(context, 'gold', l.zakatTabGold, due, reached, [
      _number('gold', l.zakatGoldGrams, suffix: l.zakatGram),
      Text(l.zakatKarat, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: DesignTokens.spaceXs),
      SegmentedButton<int>(
        key: const Key('zakat.karat'),
        segments: [
          for (final k in const [24, 21, 18]) ButtonSegment(value: k, label: Text(context.num(k))),
        ],
        selected: {karat},
        onSelectionChanged: (v) => _set('karat', v.single),
      ),
      const SizedBox(height: DesignTokens.spaceMd),
      _number('goldPrice', l.zakatGoldPrice),
      if (reached) Text(l.zakatDueGold(_fmt(context, r.dueGrams), context.num(karat)), key: const Key('zakatResult')),
      Text(l.zakatGoldRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _silver(BuildContext context, void Function(double? money, String? other, bool entered) add) {
    final l = context.l10n;
    final grams = _d('silver') ?? 0;
    final r = silverZakat(grams, _d('silverPrice'));
    final reached = grams > 0 && r.reached;
    add(
      reached ? r.dueMoney : null,
      reached && r.dueMoney == null ? '${_g(context, r.dueGrams)} (${l.zakatTabSilver})' : null,
      grams > 0,
    );
    final due = grams <= 0
        ? l.zakatDueEmpty
        : !r.reached
        ? l.zakatDueNone
        : r.dueMoney != null
        ? _m(context, r.dueMoney!)
        : _g(context, r.dueGrams);
    return _section(context, 'silver', l.zakatTabSilver, due, reached, [
      _number('silver', l.zakatSilverGrams, suffix: l.zakatGram),
      _number('silverPrice', l.zakatSilverPrice),
      if (reached) Text(l.zakatDueSilver(_fmt(context, r.dueGrams)), key: const Key('zakatResult')),
      Text(l.zakatSilverRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _money(BuildContext context, void Function(double? money, String? other, bool entered) add) {
    final l = context.l10n;
    final byGold = (_v['basis'] as String? ?? 'gold') == 'gold';
    final price = byGold ? _d('goldPrice') : _d('silverPrice');
    final amount = _d('money') ?? 0;
    final nisab = price == null ? 0.0 : price * (byGold ? goldNisabGrams : silverNisabGrams);
    final r = moneyZakat(amount, nisab);
    final reached = amount > 0 && price != null && r.reached;
    add(reached ? r.due : null, null, amount > 0);
    final due = amount <= 0
        ? l.zakatDueEmpty
        : price == null
        ? l.zakatDueEmpty
        : reached
        ? _m(context, r.due)
        : l.zakatDueNone;
    return _section(context, 'money', l.zakatTabMoney, due, reached, [
      _number('money', l.zakatMoney),
      Text(l.zakatBasis, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: DesignTokens.spaceXs),
      SegmentedButton<String>(
        key: const Key('zakat.basis'),
        segments: [
          ButtonSegment(value: 'gold', label: Text(l.zakatBasisGold)),
          ButtonSegment(value: 'silver', label: Text(l.zakatBasisSilver)),
        ],
        selected: {byGold ? 'gold' : 'silver'},
        onSelectionChanged: (v) => _set('basis', v.single),
      ),
      const SizedBox(height: DesignTokens.spaceMd),
      // The price fields are in the gold and silver cards; say which one is needed.
      if (amount > 0 && price == null)
        Text(
          byGold ? l.zakatNeedGoldPrice : l.zakatNeedSilverPrice,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        )
      else if (price != null)
        Text(l.zakatNisabIs(_fmt(context, nisab, digits: 0)), style: Theme.of(context).textTheme.bodySmall),
      Text(l.zakatMoneyRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _livestock(BuildContext context, void Function(double? money, String? other, bool entered) add) {
    final l = context.l10n;
    final kind = Livestock.values.byName(_v['animal'] as String? ?? 'sheep');
    final count = (_d('animals') ?? 0).floor();
    final due = livestockZakat(kind, count);
    String unit(String u) => switch (u) {
      'sheep' => l.zakatUnitSheep,
      'bintMakhad' => l.zakatUnitBintMakhad,
      'bintLabun' => l.zakatUnitBintLabun,
      'hiqqa' => l.zakatUnitHiqqa,
      'jadhaa' => l.zakatUnitJadhaa,
      'tabi' => l.zakatUnitTabi,
      'musinna' => l.zakatUnitMusinna,
      _ => u,
    };
    final text = due.map((d) => '${context.num(d.$1)} ${unit(d.$2)}').join(' + ');
    add(null, due.isEmpty ? null : text, count > 0);
    return _section(
      context,
      'livestock',
      l.zakatTabLivestock,
      count <= 0 ? l.zakatDueEmpty : (due.isEmpty ? l.zakatDueNone : text),
      due.isNotEmpty,
      [
        SegmentedButton<Livestock>(
          key: const Key('zakat.animal'),
          segments: [
            ButtonSegment(value: Livestock.sheep, label: Text(l.zakatSheep)),
            ButtonSegment(value: Livestock.cattle, label: Text(l.zakatCattle)),
            ButtonSegment(value: Livestock.camels, label: Text(l.zakatCamels)),
          ],
          selected: {kind},
          onSelectionChanged: (v) => _set('animal', v.single.name),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        _number('animals', l.zakatAnimalCount),
        Text(l.zakatLivestockRule, style: Theme.of(context).textTheme.bodySmall),
        if (count > 0) Text(l.zakatLivestockNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _crops(BuildContext context, void Function(double? money, String? other, bool entered) add) {
    final l = context.l10n;
    final kg = _d('crops') ?? 0;
    final rain = (_v['rain'] as bool?) ?? true;
    final r = cropsZakat(kg, rainFed: rain);
    final reached = kg > 0 && r.reached;
    final short = l.zakatDueShortKg(_fmt(context, r.dueKg));
    add(null, reached ? '$short (${l.zakatTabCrops})' : null, kg > 0);
    return _section(
      context,
      'crops',
      l.zakatTabCrops,
      kg <= 0 ? l.zakatDueEmpty : (reached ? short : l.zakatDueNone),
      reached,
      [
        _number('crops', l.zakatCropsKg, suffix: l.zakatKg),
        SegmentedButton<bool>(
          key: const Key('zakat.rain'),
          segments: [
            ButtonSegment(value: true, label: Text(l.zakatRain)),
            ButtonSegment(value: false, label: Text(l.zakatIrrigated)),
          ],
          selected: {rain},
          onSelectionChanged: (v) => _set('rain', v.single),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(l.zakatCropsRule, style: Theme.of(context).textTheme.bodySmall),
        if (kg > 0) Text(l.zakatCropsNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// The total of every kind, at the bottom, the amount in the calm colour.
  Widget _total(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = _totals;
    final calm = _calm(scheme);
    final has = t.money > 0 || t.other.isNotEmpty;
    return Card(
      key: const Key('zakatTotal'),
      color: calm.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: calm.withValues(alpha: 0.45)),
      ),
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.zakatTotalTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            if (!t.any)
              Text(l.zakatTotalEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)
            else if (!has)
              Text(l.zakatTotalNone, textAlign: TextAlign.center, style: theme.textTheme.titleMedium)
            else ...[
              if (t.money > 0)
                Text(
                  _m(context, t.money),
                  key: const Key('zakatTotalAmount'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: calm),
                ),
              if (t.other.isNotEmpty)
                Text(
                  t.money > 0 ? l.zakatTotalAlso(t.other.join('، ')) : t.other.join('، '),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: calm),
                ),
            ],
            const SizedBox(height: DesignTokens.spaceSm),
            Text(l.zakatYearNote, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    var money = 0.0;
    final other = <String>[];
    var any = false;
    void add(double? m, String? o, bool entered) {
      if (m != null) money += m;
      if (o != null) other.add(o);
      any = any || entered;
    }

    // One screen, every kind under the other (owner, 2026-11-17), the total at the bottom.
    final sections = [
      _money(context, add),
      _gold(context, add),
      _silver(context, add),
      _livestock(context, add),
      _crops(context, add),
    ];
    _totals = (money: money, other: other, any: any);
    return Scaffold(
      appBar: AppBar(title: Text(l.zakatTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('zakatList'),
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          children: [...sections, _total(context)],
        ),
      ),
    );
  }
}
