import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../domain/text.dart';
import '../domain/zakat.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'widgets.dart';
import 'r_icon.dart';

/// Zakat on money after the published fatwas of Dar al-Ifta al-Misriyya, held for a
/// shar'i review. Every rule links to its fatwa; the numbers stay on this device.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  late Map<String, double> _values;
  late double _price;
  late bool _yearPassed;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final s = context.services.settings;
    _values = Map.of(s.zakatValues);
    _price = s.zakatGoldPrice;
    _yearPassed = s.zakatYearPassed;
  }

  /// Accepts Western and Arabic-Indic digits and the Arabic decimal comma.
  static double _parse(String raw) {
    final western = raw
        .split('')
        .map((c) {
          final code = c.codeUnitAt(0);
          if (code >= 0x0660 && code <= 0x0669) return String.fromCharCode(code - 0x0660 + 0x30);
          return c == '٫' ? '.' : c;
        })
        .join()
        .replaceAll(',', '');
    final v = double.tryParse(western.trim()) ?? 0;
    return v.isFinite && v > 0 ? v : 0;
  }

  String _money(double v, bool arabic) {
    final fixed = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final text = parts.length > 1 ? '$whole.${parts[1]}' : whole;
    return arabic ? toArabicIndic(text) : text;
  }

  void _save() => context.services.settings.setZakat(values: _values, price: _price, yearPassed: _yearPassed);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final guide = context.services.content.zakat;
    final result = guide.compute(_values, _price, _yearPassed);
    final adornment = guide.source('adornment');
    String n(num v) => arabic ? toArabicIndic('$v') : '$v';

    Widget numberField(String key, String label, double initial, ValueChanged<double> onChanged) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: TextFormField(
        key: Key(key),
        initialValue: initial > 0 ? _money(initial, false).replaceAll(',', '') : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (raw) {
          setState(() => onChanged(_parse(raw)));
          _save();
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.zakatTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('zakatList'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            ReviewNotice(l.zakatReview, key: const Key('zakatReview')),
            SectionCard(
              title: l.zakatPriceTitle,
              children: [
                numberField('zakatPrice', l.zakatPrice, _price, (v) => _price = v),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                  child: Text(
                    l.zakatNisabRule(n(guide.nisabGoldGrams.round()), n(guide.nisabKarat)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
              ],
            ),
            SectionCard(
              title: l.zakatWealth,
              children: [
                for (final f in guide.fields)
                  numberField('zakat-${f.id}', _fieldLabel(l, f.id), _values[f.id] ?? 0, (v) => _values[f.id] = v),
                CheckboxListTile(
                  key: const Key('zakatYear'),
                  value: _yearPassed,
                  title: Text(l.zakatYearPassed),
                  onChanged: (v) {
                    setState(() => _yearPassed = v ?? false);
                    _save();
                  },
                ),
              ],
            ),
            SectionCard(
              title: l.zakatResult,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: _ResultView(result: result, money: (v) => _money(v, arabic)),
                ),
              ],
            ),
            if (adornment != null)
              SectionCard(
                title: l.zakatAdornment,
                children: [
                  _Quote(key: const Key('zakatAdornment'), text: adornment.quotes.first),
                  _fatwaLink(l, adornment, n),
                ],
              ),
            SectionCard(
              title: l.zakatSources(arabic ? guide.referenceAr : guide.referenceEn),
              children: [
                for (final s in guide.sources)
                  ExpansionTile(
                    key: Key('zakatSource-${s.id}'),
                    title: Text(s.titleAr, textDirection: TextDirection.rtl),
                    children: [
                      for (final q in s.quotes) _Quote(text: q),
                      _fatwaLink(l, s, n),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fatwaLink(AppLocalizations l, ZakatSource s, String Function(num) n) => ListTile(
    key: Key('zakatLink-${s.id}'),
    leading: const RIcon(RIcons.external),
    title: Text(l.zakatFatwa(n(s.number))),
    onTap: () => launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
  );

  static String _fieldLabel(AppLocalizations l, String id) => switch (id) {
    'cash' => l.zakatFieldCash,
    'certificates' => l.zakatFieldCertificates,
    'certificateReturns' => l.zakatFieldCertificateReturns,
    'shares' => l.zakatFieldShares,
    'trade' => l.zakatFieldTrade,
    'gold24' => l.zakatFieldGold24,
    'gold21' => l.zakatFieldGold21,
    'gold18' => l.zakatFieldGold18,
    'debts' => l.zakatFieldDebts,
    _ => id,
  };
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.money});
  final ZakatResult result;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final net = money(result.net);
    final nisab = money(result.nisab);
    final text = switch (result.status) {
      ZakatStatus.needPrice => l.zakatNeedPrice,
      ZakatStatus.belowNisab => l.zakatBelowNisab(net, nisab),
      ZakatStatus.yearNotPassed => l.zakatYearNotPassed(net, nisab),
      ZakatStatus.due => null,
    };
    if (text != null) return Text(text, key: Key('zakatResult-${result.status.name}'));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.zakatDue(money(result.zakat)),
          key: const Key('zakatAmount'),
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(l.zakatDueDetail(net, nisab), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// A fatwa's words, unchanged, in Arabic.
class _Quote extends StatelessWidget {
  const _Quote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
    child: Container(
      padding: const EdgeInsetsDirectional.only(start: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 3)),
      ),
      child: Text('«$text»', textDirection: TextDirection.rtl, style: duaStyle(context, size: 16)),
    ),
  );
}
