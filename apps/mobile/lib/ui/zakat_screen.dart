import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/zakat_simple.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';

/// Zakat calculator, simplified on the owner's request (2026-11-11): five tabs only:
/// silver, gold, money, livestock, crops. Rules: lib/domain/zakat_simple.dart.
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
    final t = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(digits);
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

  Widget _result(BuildContext context, {required bool reached, required String text, String? note}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('zakatResult'),
      color: reached ? scheme.primaryContainer : scheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: reached ? scheme.onPrimaryContainer : null,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: DesignTokens.spaceXs),
              Text(note, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _page(List<Widget> children) =>
      ListView(padding: const EdgeInsets.all(DesignTokens.spaceLg), children: children);

  Widget _gold(BuildContext context) {
    final l = context.l10n;
    final grams = _d('gold') ?? 0;
    final karat = (_v['karat'] as int?) ?? 21;
    final r = goldZakat(grams, karat, _d('goldPrice'));
    return _page([
      if (grams > 0)
        _result(
          context,
          reached: r.reached,
          text: r.reached
              ? l.zakatDueGold(_fmt(context, r.dueGrams), context.num(karat)) +
                    (r.dueMoney == null ? '' : '\n${l.zakatDueMoney(_fmt(context, r.dueMoney!))}')
              : l.zakatBelowNisab,
          note: l.zakatYearNote,
        ),
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
      Text(l.zakatGoldRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _silver(BuildContext context) {
    final l = context.l10n;
    final grams = _d('silver') ?? 0;
    final r = silverZakat(grams, _d('silverPrice'));
    return _page([
      if (grams > 0)
        _result(
          context,
          reached: r.reached,
          text: r.reached
              ? l.zakatDueSilver(_fmt(context, r.dueGrams)) +
                    (r.dueMoney == null ? '' : '\n${l.zakatDueMoney(_fmt(context, r.dueMoney!))}')
              : l.zakatBelowNisab,
          note: l.zakatYearNote,
        ),
      _number('silver', l.zakatSilverGrams, suffix: l.zakatGram),
      _number('silverPrice', l.zakatSilverPrice),
      Text(l.zakatSilverRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _money(BuildContext context) {
    final l = context.l10n;
    final byGold = (_v['basis'] as String? ?? 'gold') == 'gold';
    final price = byGold ? _d('goldPrice') : _d('silverPrice');
    final amount = _d('money') ?? 0;
    final nisab = price == null ? 0.0 : price * (byGold ? goldNisabGrams : silverNisabGrams);
    final r = moneyZakat(amount, nisab);
    return _page([
      if (amount > 0)
        _result(
          context,
          reached: r.reached,
          text: price == null
              ? (byGold ? l.zakatNeedGoldPrice : l.zakatNeedSilverPrice)
              : r.reached
              ? l.zakatDueMoney(_fmt(context, r.due))
              : l.zakatBelowNisab,
          note: price == null ? null : '${l.zakatNisabIs(_fmt(context, nisab, digits: 0))}\n${l.zakatYearNote}',
        ),
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
      if (byGold) _number('goldPrice', l.zakatGoldPrice) else _number('silverPrice', l.zakatSilverPrice),
      Text(l.zakatMoneyRule, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _livestock(BuildContext context) {
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
    return _page([
      if (count > 0)
        _result(
          context,
          reached: due.isNotEmpty,
          text: due.isEmpty
              ? l.zakatBelowNisab
              : l.zakatDueAnimals(due.map((d) => '${context.num(d.$1)} ${unit(d.$2)}').join(' + ')),
          note: l.zakatLivestockNote,
        ),
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
    ]);
  }

  Widget _crops(BuildContext context) {
    final l = context.l10n;
    final kg = _d('crops') ?? 0;
    final rain = (_v['rain'] as bool?) ?? true;
    final r = cropsZakat(kg, rainFed: rain);
    return _page([
      if (kg > 0)
        _result(
          context,
          reached: r.reached,
          text: r.reached ? l.zakatDueCrops(_fmt(context, r.dueKg)) : l.zakatBelowNisab,
          note: l.zakatCropsNote,
        ),
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = [
      (l.zakatTabSilver, _silver),
      (l.zakatTabGold, _gold),
      (l.zakatTabMoney, _money),
      (l.zakatTabLivestock, _livestock),
      (l.zakatTabCrops, _crops),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.zakatTitle),
          bottom: TabBar(
            key: const Key('zakatTabs'),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: t.$1)],
          ),
        ),
        body: ReadableWidth(
          child: TabBarView(children: [for (final t in tabs) Builder(builder: t.$2)]),
        ),
      ),
    );
  }
}
