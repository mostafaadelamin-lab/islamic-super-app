import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/place_names.dart';

Map<String, dynamic> _a(Map<String, String> m) => {'address': {...m, 'country': 'مصر'}};

void main() {
  test('a named compound or town wins over the street-level neighbourhood (Madinaty)', () {
    final p = PlaceNames.parse(
      _a({'town': 'مدينتي', 'city': 'القاهرة'}),
      _a({'neighbourhood': 'مباني 1', 'city': 'مدينة القاهرة الجديدة'}),
    );
    expect(p!.label(), 'مصر - مدينتي');
  });

  test('a district (suburb) is used: Nasr City', () {
    expect(PlaceNames.parse(_a({'suburb': 'مدينة نصر', 'city': 'مدينة نصر'}))!.area, 'مدينة نصر');
  });

  test('a nearby village from the district zoom is ignored when the street answer disagrees', () {
    final p = PlaceNames.parse(_a({'village': 'كفر النحال'}), _a({'road': 'شارع المؤمنين', 'city': 'الزقازيق'}));
    expect(p!.area, 'الزقازيق');
    final q = PlaceNames.parse(_a({'hamlet': 'الشاطبى', 'city': 'الإسكندرية'}), _a({'road': 'ش', 'hamlet': 'الشاطبى'}));
    expect(q!.area, 'الشاطبى');
  });

  test('works with one answer only, and BigDataCloud as the fallback', () {
    expect(PlaceNames.parse(null, _a({'city': 'الجيزة'}))!.area, 'الجيزة');
    expect(PlaceNames.parse(null, null), isNull);
    final b = PlaceNames.parseBigDataCloud({'countryName': 'مصر', 'locality': 'القاهرة الجديدة', 'city': 'القاهرة'});
    expect(b!.label(), 'مصر - القاهرة الجديدة');
    expect(PlaceName.fromJson(b.toJson())!.label(), b.label());
    expect(b.toJson()['v'], PlaceNames.version);
  });
}
