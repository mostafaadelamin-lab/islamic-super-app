import 'package:flutter/widgets.dart';

import '../domain/text.dart';
import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  /// Number in the UI locale's digits (Arabic-Indic in ar).
  String num(Object n) => isArabic ? toArabicIndic(n) : '$n';

  /// Like [num] but wrapped in a left-to-right isolate (U+2066..U+2069) so
  /// that dates and clock times such as 2026-01-15 or 0:05:00 keep their
  /// order inside right-to-left sentences.
  String numLtr(Object n) => '\u2066${num(n)}\u2069';

  String prayerName(String key) => switch (key) {
    'fajr' => l10n.prayerFajr,
    'sunrise' => l10n.prayerSunrise,
    'dhuhr' => l10n.prayerDhuhr,
    'asr' => l10n.prayerAsr,
    'maghrib' => l10n.prayerMaghrib,
    'isha' => l10n.prayerIsha,
    _ => key,
  };
}
