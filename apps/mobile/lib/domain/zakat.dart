/// Zakat on money, following the published fatwas of Dar al-Ifta al-Misriyya
/// (content/zakat/dar-alifta.v1.json, held for a shar'i review). The rules (85 g of
/// 21-karat gold, 2.5%, a full lunar year) and every quote shown come from that file;
/// this file only does the arithmetic.
library;

class ZakatSource {
  const ZakatSource({
    required this.id,
    required this.number,
    required this.date,
    required this.url,
    required this.titleAr,
    required this.quotes,
  });

  factory ZakatSource.fromJson(Map<String, dynamic> j) => ZakatSource(
    id: j['id'] as String,
    number: j['number'] as int,
    date: j['date'] as String,
    url: j['url'] as String,
    titleAr: j['titleAr'] as String,
    quotes: [for (final q in j['quotes'] as List<dynamic>) q as String],
  );

  final String id;
  final int number;
  final String date;
  final String url;
  final String titleAr;
  final List<String> quotes;
}

class ZakatField {
  const ZakatField({required this.id, this.karat, this.subtract = false, this.sources = const []});

  factory ZakatField.fromJson(Map<String, dynamic> j) => ZakatField(
    id: j['id'] as String,
    karat: j['karat'] as int?,
    subtract: j['subtract'] as bool? ?? false,
    sources: [for (final s in j['sources'] as List<dynamic>) s as String],
  );

  final String id;

  /// Set for gold fields (grams of this karat).
  final int? karat;

  /// Debts: taken away from the total.
  final bool subtract;
  final List<String> sources;
}

enum ZakatStatus { needPrice, belowNisab, yearNotPassed, due }

class ZakatResult {
  const ZakatResult(this.status, {this.net = 0, this.nisab = 0, this.zakat = 0});
  final ZakatStatus status;
  final double net;
  final double nisab;
  final double zakat;
}

class ZakatGuide {
  const ZakatGuide({
    required this.reviewStatus,
    required this.referenceAr,
    required this.referenceEn,
    required this.nisabGoldGrams,
    required this.nisabKarat,
    required this.rate,
    required this.sources,
    required this.fields,
  });

  factory ZakatGuide.fromJson(Map<String, dynamic> j) {
    final ref = j['reference'] as Map<String, dynamic>;
    final rules = j['rules'] as Map<String, dynamic>;
    return ZakatGuide(
      reviewStatus: j['reviewStatus'] as String,
      referenceAr: ref['nameAr'] as String,
      referenceEn: ref['nameEn'] as String,
      nisabGoldGrams: (rules['nisabGoldGrams'] as num).toDouble(),
      nisabKarat: rules['nisabKarat'] as int,
      rate: (rules['rate'] as num).toDouble(),
      sources: [for (final s in j['sources'] as List<dynamic>) ZakatSource.fromJson(s as Map<String, dynamic>)],
      fields: [for (final f in j['fields'] as List<dynamic>) ZakatField.fromJson(f as Map<String, dynamic>)],
    );
  }

  static const empty = ZakatGuide(
    reviewStatus: 'pending',
    referenceAr: '',
    referenceEn: '',
    nisabGoldGrams: 0,
    nisabKarat: 1,
    rate: 0,
    sources: [],
    fields: [],
  );

  final String reviewStatus;
  final String referenceAr;
  final String referenceEn;
  final double nisabGoldGrams;
  final int nisabKarat;
  final double rate;
  final List<ZakatSource> sources;
  final List<ZakatField> fields;

  ZakatSource? source(String id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  static double _amount(double? v) => v != null && v.isFinite && v > 0 ? v : 0;

  /// [values]: what the user typed per field id (money in their currency, gold in grams).
  /// [gramPrice]: today's price of one gram of 21-karat gold. [yearPassed]: a full lunar
  /// year has passed since the wealth reached the nisab.
  ZakatResult compute(Map<String, double> values, double gramPrice, bool yearPassed) {
    final price = _amount(gramPrice);
    if (price == 0) return const ZakatResult(ZakatStatus.needPrice);
    var net = 0.0;
    for (final f in fields) {
      final v = _amount(values[f.id]);
      // Gold of another karat counts as 21-karat grams by purity, then is priced.
      final value = f.karat == null ? v : v * f.karat! * price / nisabKarat;
      net += f.subtract ? -value : value;
    }
    final nisab = nisabGoldGrams * price;
    if (net < nisab) return ZakatResult(ZakatStatus.belowNisab, net: net, nisab: nisab);
    if (!yearPassed) return ZakatResult(ZakatStatus.yearNotPassed, net: net, nisab: nisab);
    return ZakatResult(ZakatStatus.due, net: net, nisab: nisab, zakat: net * rate);
  }
}
