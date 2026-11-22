import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/next_prayer_notice.dart';
import 'package:rattil/data/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  Future<NextPrayerNotice> make(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final settings = SettingsController(await SharedPreferences.getInstance(), defaultCityId: c.cities.first.id);
    return NextPrayerNotice(content: c, settings: settings, clock: () => fixedNow);
  }

  test('one notice now, then one at each prayer counting down to the one after it', () async {
    final n = await make({'adhan.iqama': false});
    final slots = n.plan();
    expect(slots.first.showAt, isNull);
    expect(slots.first.id, NextPrayerNotice.firstId);
    // 12:00 Cairo: Dhuhr is next.
    expect(slots.first.title, contains('الظهر'));
    expect(slots.first.next.isAfter(fixedNow), isTrue);
    expect(slots.first.body.split(' · '), hasLength(5));
    expect(slots[1].showAt, slots.first.next);
    expect(slots[1].title, contains('العصر'));
    for (var i = 2; i < slots.length; i++) {
      expect(slots[i].showAt, slots[i - 1].next);
      expect(slots[i].id, slots[i - 1].id + 1);
    }
    expect(slots.length, lessThanOrEqualTo(NextPrayerNotice.maxSlots));
  });

  test('off in the settings: nothing', () async {
    final n = await make({'prayer.lockNotice': false});
    expect(n.plan(), isEmpty);
  });

  test('with the iqama on (default): at each adhan the countdown runs to its iqama, then to the next prayer', () async {
    final n = await make({});
    final slots = n.plan();
    expect(slots.first.title, contains('الظهر'));
    expect(slots[1].title, contains('إقامة صلاة الظهر'));
    expect(slots[1].next.difference(slots[1].showAt!), const Duration(minutes: 15));
    expect(slots[2].title, contains('العصر'));
  });
}
