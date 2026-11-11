// The simple zakat calculator the owner asked for (2026-11-11), with the rules of the
// islah.eg calculator: gold nisab 85 g of 24-carat gold, silver nisab 595 g of pure silver,
// rate 2.5% after a lunar year; money is measured against the gold or the silver nisab
// (user's choice); crops: nisab 612 kg, 10% when watered without cost (rain, rivers),
// 5% when watered with machines or animals, due at harvest. Livestock (not on islah.eg):
// the tables of the Prophet's letter on zakat narrated by Anas (Sahih al-Bukhari 1454) for
// camels and sheep, and the hadith of Mu'adh (Sunan al-Tirmidhi 623) for cattle.

const goldNisabGrams = 85.0; // 24 carat
const silverNisabGrams = 595.0; // 999
const cropsNisabKg = 612.0;
const zakatRate = 0.025;

/// Pure (24-carat) grams in [grams] of [karat] gold.
double pureGold(double grams, int karat) => grams * karat / 24;

class MetalZakat {
  const MetalZakat(this.reached, this.dueGrams, this.dueMoney);
  final bool reached;
  final double dueGrams;
  final double? dueMoney;
}

MetalZakat goldZakat(double grams, int karat, double? pricePerGram24) {
  final pure = pureGold(grams, karat);
  if (pure < goldNisabGrams) return const MetalZakat(false, 0, null);
  final due = grams * zakatRate;
  return MetalZakat(true, due, pricePerGram24 == null ? null : pure * zakatRate * pricePerGram24);
}

MetalZakat silverZakat(double grams, double? pricePerGram) {
  if (grams < silverNisabGrams) return const MetalZakat(false, 0, null);
  final due = grams * zakatRate;
  return MetalZakat(true, due, pricePerGram == null ? null : due * pricePerGram);
}

/// Money: [nisab] is the value of 85 g gold or 595 g silver.
({bool reached, double due, double nisab}) moneyZakat(double amount, double nisab) =>
    (reached: nisab > 0 && amount >= nisab, due: nisab > 0 && amount >= nisab ? amount * zakatRate : 0, nisab: nisab);

/// Crops: [rainFed] = watered without cost (10%), otherwise 5%.
({bool reached, double dueKg}) cropsZakat(double kg, {required bool rainFed}) =>
    kg < cropsNisabKg ? (reached: false, dueKg: 0) : (reached: true, dueKg: kg * (rainFed ? 0.10 : 0.05));

enum Livestock { camels, cattle, sheep }

/// What is due on [count] grazing animals of [kind], as (amount, unit-key) pairs.
/// Unit keys: sheep, bintMakhad, bintLabun, hiqqa, jadhaa, tabi, musinna. Empty = below the nisab.
List<(int, String)> livestockZakat(Livestock kind, int count) {
  switch (kind) {
    case Livestock.sheep:
      if (count < 40) return const [];
      if (count <= 120) return const [(1, 'sheep')];
      if (count <= 200) return const [(2, 'sheep')];
      if (count <= 300) return const [(3, 'sheep')];
      return [(count ~/ 100, 'sheep')];
    case Livestock.camels:
      if (count < 5) return const [];
      if (count <= 24) return [(count ~/ 5, 'sheep')];
      if (count <= 35) return const [(1, 'bintMakhad')];
      if (count <= 45) return const [(1, 'bintLabun')];
      if (count <= 60) return const [(1, 'hiqqa')];
      if (count <= 75) return const [(1, 'jadhaa')];
      if (count <= 90) return const [(2, 'bintLabun')];
      if (count <= 120) return const [(2, 'hiqqa')];
      return _bestSplit(count, 40, 'bintLabun', 50, 'hiqqa');
    case Livestock.cattle:
      if (count < 30) return const [];
      if (count < 40) return const [(1, 'tabi')];
      if (count < 60) return const [(1, 'musinna')];
      return _bestSplit(count, 30, 'tabi', 40, 'musinna');
  }
}

/// Above the fixed table: one [aUnit] per [a] and one [bUnit] per [b], covering as many as possible.
List<(int, String)> _bestSplit(int count, int a, String aUnit, int b, String bUnit) {
  var best = (0, 0, -1);
  for (var nb = 0; nb * b <= count; nb++) {
    final na = (count - nb * b) ~/ a;
    final covered = na * a + nb * b;
    if (covered > best.$3) best = (na, nb, covered);
  }
  return [if (best.$1 > 0) (best.$1, aUnit), if (best.$2 > 0) (best.$2, bUnit)];
}
