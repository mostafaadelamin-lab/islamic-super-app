import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/declination.dart';

import '../helpers.dart';

void main() {
  final wmm = WorldMagneticModel.fromJson(readAppJson('assets/schemas/wmm2025.json'));
  final vectors = readRepoJson('tests/vectors/declination.json');

  test('bundled WMM2025 is identical to the shared schema', () {
    expect(readAppJson('assets/schemas/wmm2025.json'), readRepoJson('packages/shared-schemas/geo/wmm2025.json'));
  });

  test('matches the web implementation vectors (checked there against npm geomagnetism)', () {
    final cases = vectors['cases'] as List<dynamic>;
    expect(cases, hasLength(72));
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final d = wmm.declination(
        (c['lat'] as num).toDouble(),
        (c['lng'] as num).toDouble(),
        (c['year'] as num).toDouble(),
      );
      expect(d, closeTo((c['decl'] as num).toDouble(), 1e-6), reason: '${c['city']} ${c['date']}');
    }
  });

  test('decimalYear', () {
    expect(decimalYear(DateTime.utc(2026)), 2026);
    expect(decimalYear(DateTime.utc(2026, 7, 2, 12)), closeTo(2026.5, 0.01));
  });
}
