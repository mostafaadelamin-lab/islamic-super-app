import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adhan_schedule.dart';
import '../domain/adhan_voices.dart';
import '../domain/hijri.dart';
import '../domain/page_khatma.dart';
import '../domain/prayer_schedule.dart';
import '../domain/quran.dart';
import '../theme/design_tokens.dart';

/// User preferences, persisted in shared_preferences.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs, {String defaultCityId = 'c1'}) : _defaultCityId = defaultCityId {
    hijriOffsetDays = hijriOffset;
  }

  static const defaultApiBaseUrl = 'http://10.0.2.2:8000';
  static const minFontSize = 18.0;
  static const maxFontSize = 40.0;
  static const defaultFontSize = 26.0;

  final SharedPreferences _prefs;
  final String _defaultCityId;

  Locale get locale => Locale(_prefs.getString('locale') ?? 'ar');
  bool get isArabic => locale.languageCode == 'ar';
  Future<void> setLocale(String code) async {
    if (code != 'ar' && code != 'en') throw ArgumentError(code);
    await _prefs.setString('locale', code);
    notifyListeners();
  }

  /// Reels reviewer mode: also show reels that have not been religiously reviewed yet.
  bool get reelsReviewer => _prefs.getBool('reelsReviewer') ?? false;
  Future<void> setReelsReviewer(bool v) async {
    await _prefs.setBool('reelsReviewer', v);
    notifyListeners();
  }

  /// Where the listener stopped in a narrated episode (seconds), keyed "series/episode".
  int storyPosition(String key) => _prefs.getInt('storyPos.$key') ?? 0;
  Future<void> setStoryPosition(String key, int seconds) async {
    if (seconds > 5) {
      await _prefs.setInt('storyPos.$key', seconds);
    } else {
      await _prefs.remove('storyPos.$key');
    }
  }

  ThemeMode get themeMode => switch (_prefs.getString('theme')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  Future<void> setThemeMode(ThemeMode m) async {
    await _prefs.setString('theme', m.name);
    notifyListeners();
  }

  /// Colour style (owner 2026-11-15): 'emerald' (style 1, default) or 'madinah' (style 2).
  String get palette {
    final v = _prefs.getString('palette');
    return DesignTokens.paletteIds.contains(v) ? v! : DesignTokens.defaultPalette;
  }

  Future<void> setPalette(String id) async {
    if (!DesignTokens.paletteIds.contains(id)) throw ArgumentError(id);
    await _prefs.setString('palette', id);
    notifyListeners();
  }

  double get quranFontSize => (_prefs.getDouble('quranFontSize') ?? defaultFontSize).clamp(minFontSize, maxFontSize);
  Future<void> setQuranFontSize(double v) async {
    await _prefs.setDouble('quranFontSize', v.clamp(minFontSize, maxFontSize).roundToDouble());
    notifyListeners();
  }

  /// Mushaf page zoom (1 = fits the screen; owner asked for bigger/smaller Quran text).
  static const mushafZoomMin = 1.0;
  // Up to 3× since pinch zoom came (owner 2026-11-16), same as the website.
  static const mushafZoomMax = 3.0;
  double get mushafZoom => (_prefs.getDouble('mushafZoom') ?? 1.0).clamp(mushafZoomMin, mushafZoomMax);
  Future<void> setMushafZoom(double v) async {
    await _prefs.setDouble('mushafZoom', v.clamp(mushafZoomMin, mushafZoomMax));
    notifyListeners();
  }

  bool get showTranslation => _prefs.getBool('showTranslation') ?? false;
  Future<void> setShowTranslation(bool v) async {
    await _prefs.setBool('showTranslation', v);
    notifyListeners();
  }

  /// Days added to the Umm al-Qura Hijri date (-2..+2) to match the local moon sighting.
  int get hijriOffset => clampHijriOffset(_prefs.getInt('hijriOffset') ?? 0);
  Future<void> setHijriOffset(int v) async {
    final c = clampHijriOffset(v);
    await _prefs.setInt('hijriOffset', c);
    hijriOffsetDays = c;
    notifyListeners();
  }

  // --- Prayer ---------------------------------------------------------------
  /// Id used for "my location" (GPS) instead of a listed city.
  static const gpsCityId = 'gps';

  String get cityId => _prefs.getString('cityId') ?? _defaultCityId;

  /// True until the user picks a city or a position is found.
  bool get cityNeverChosen => _prefs.getString('cityId') == null;

  /// Coordinates from "use my location" (null when never located).
  ({double lat, double lng, String nearestCityId})? get gpsLocation {
    final lat = _prefs.getDouble('gps.lat');
    final lng = _prefs.getDouble('gps.lng');
    final near = _prefs.getString('gps.near');
    return lat == null || lng == null || near == null ? null : (lat: lat, lng: lng, nearestCityId: near);
  }

  /// Uses the device position for prayer times; the time zone and the default
  /// method come from the nearest listed city.
  Future<void> setGpsLocation(
    double lat,
    double lng,
    String nearestCityId,
    String recommendedMethod, {
    bool keepMethod = false,
  }) async {
    await _prefs.setDouble('gps.lat', (lat * 10000).roundToDouble() / 10000);
    await _prefs.setDouble('gps.lng', (lng * 10000).roundToDouble() / 10000);
    await _prefs.setString('gps.near', nearestCityId);
    await _prefs.setString('cityId', gpsCityId);
    await _prefs.remove('gps.place.ar');
    await _prefs.remove('gps.place.en');
    if (!keepMethod || _prefs.getString('method') == null) await _prefs.setString('method', recommendedMethod);
    notifyListeners();
  }

  /// The area name of the GPS position per language ("ar"/"en": {country, area}).
  Map<String, dynamic>? gpsPlace(String lang) {
    final raw = _prefs.getString('gps.place.$lang');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setGpsPlace(String lang, Map<String, dynamic>? place) async {
    if (place == null) {
      await _prefs.remove('gps.place.$lang');
    } else {
      await _prefs.setString('gps.place.$lang', jsonEncode(place));
    }
    notifyListeners();
  }

  /// Find the phone's position by itself when the app opens (on by default).
  bool get autoLocation => _prefs.getBool('autoLocation') ?? true;
  Future<void> setAutoLocation(bool v) async {
    await _prefs.setBool('autoLocation', v);
    notifyListeners();
  }

  /// 12-hour clock (with AM/PM, ص/م) instead of 24-hour for prayer times.
  bool get clock12 => _prefs.getString('clock') == '12';
  Future<void> setClock12(bool v) async {
    await _prefs.setString('clock', v ? '12' : '24');
    notifyListeners();
  }

  /// Selecting a city also selects that city's recommended method.
  Future<void> setCity(String id, String recommendedMethod) async {
    await _prefs.setString('cityId', id);
    await _prefs.setString('method', recommendedMethod);
    notifyListeners();
  }

  /// Automatic prayer times (owner, 2026-11-11): the city's recommended method and no
  /// manual minute adjustments. Choosing a method or adjusting a time switches to manual.
  bool get prayerAuto => _prefs.getBool('prayer.auto') ?? !_prefs.containsKey('adjustments');
  Future<void> setPrayerAuto(bool v) async {
    await _prefs.setBool('prayer.auto', v);
    notifyListeners();
  }

  /// Null means "use the city's recommended method".
  String? get method => prayerAuto ? null : _prefs.getString('method');
  Future<void> setMethod(String m) async {
    await _prefs.setBool('prayer.auto', false);
    await _prefs.setString('method', m);
    notifyListeners();
  }

  String get asr => _prefs.getString('asr') ?? 'standard';
  Future<void> setAsr(String a) async {
    await _prefs.setString('asr', a);
    notifyListeners();
  }

  Map<String, int> get adjustments {
    if (prayerAuto) return const {};
    final raw = _prefs.getString('adjustments');
    if (raw == null) return const {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in m.entries) e.key: clampAdjustment((e.value as num).toInt())};
  }

  Future<void> setAdjustment(String key, int minutes) async {
    final m = Map<String, int>.of(adjustments)..[key] = clampAdjustment(minutes);
    m.removeWhere((_, v) => v == 0);
    await _prefs.setBool('prayer.auto', false);
    await _prefs.setString('adjustments', jsonEncode(m));
    notifyListeners();
  }

  Future<void> resetAdjustments() async {
    await _prefs.remove('adjustments');
    notifyListeners();
  }

  // --- Reading position ------------------------------------------------------
  AyahRef? get lastRead {
    final s = _prefs.getInt('lastRead.surah');
    final a = _prefs.getInt('lastRead.ayah');
    return s == null || a == null ? null : AyahRef(s, a);
  }

  Future<void> setLastRead(AyahRef r) async {
    if (lastRead == r) return;
    await _prefs.setInt('lastRead.surah', r.surah);
    await _prefs.setInt('lastRead.ayah', r.ayah);
    notifyListeners();
  }

  // --- Recitation ---------------------------------------------------------------
  /// everyayah.com folder of the chosen reciter (null = catalogue default).
  String? get reciter => _prefs.getString('audio.reciter');
  Future<void> setReciter(String folder) async {
    await _prefs.setString('audio.reciter', folder);
    notifyListeners();
  }

  static const repeatChoices = [1, 2, 3, 5, 10];
  static const speedChoices = [0.75, 1.0, 1.25, 1.5, 2.0];

  /// Recitation playback speed (one of [speedChoices]; 1.0 = normal).
  double get audioSpeed {
    final v = _prefs.getDouble('audio.speed') ?? 1.0;
    return speedChoices.contains(v) ? v : 1.0;
  }

  Future<void> setAudioSpeed(double v) async {
    await _prefs.setDouble('audio.speed', speedChoices.contains(v) ? v : 1.0);
    notifyListeners();
  }

  /// How many times each ayah is played.
  int get repeat => (_prefs.getInt('audio.repeat') ?? 1).clamp(1, 10);
  Future<void> setRepeat(int n) async {
    await _prefs.setInt('audio.repeat', n.clamp(1, 10));
    notifyListeners();
  }

  /// Whether the mini player shows the tafsir of the ayah being recited (default off).
  bool get tafsirWithRecitation => _prefs.getBool('audio.tafsir') ?? false;
  Future<void> setTafsirWithRecitation(bool on) async {
    await _prefs.setBool('audio.tafsir', on);
    notifyListeners();
  }

  /// The Mushaf reader's player slid down to a thin strip (owner 2026-11-17), so it stops covering the page.
  bool get readerPlayerMin => _prefs.getBool('reader.playerMin') ?? false;
  Future<void> setReaderPlayerMin(bool on) async {
    await _prefs.setBool('reader.playerMin', on);
    notifyListeners();
  }

  // --- Khatma (see domain/khatma.dart) ----------------------------------------------
  /// The current khatma, or null when none was started.
  PageKhatma? get khatma {
    final at = _prefs.getInt('khatma.startedAt');
    if (at == null) return null;
    return PageKhatma.decode(at, _prefs.getStringList('khatma.read') ?? const []);
  }

  Future<void> startKhatma(DateTime now) async {
    await _prefs.setInt('khatma.startedAt', now.millisecondsSinceEpoch);
    await _prefs.setStringList('khatma.read', const []);
    notifyListeners();
  }

  Future<void> markKhatmaPage(int page) async {
    final k = khatma;
    if (k == null) return;
    final next = k.markRead(page);
    if (identical(next, k)) return;
    await _prefs.setStringList('khatma.read', next.encoded);
    notifyListeners();
  }

  Future<void> clearKhatma() async {
    await _prefs.remove('khatma.startedAt');
    await _prefs.remove('khatma.read');
    notifyListeners();
  }

  // --- First run ---------------------------------------------------------------------
  /// True once the welcome tour and the permissions setup were finished or skipped.
  /// How many times the Mushaf's full-screen hint (how to turn pages) was shown.
  int get readerHintShown => _prefs.getInt('reader.hintShown') ?? 0;
  Future<void> setReaderHintShown(int n) => _prefs.setInt('reader.hintShown', n);

  /// True once the first-open guide to the Mushaf's touches was closed (owner 2026-11-15).
  bool get readerGuideDone => _prefs.getBool('reader.guideDone') ?? false;
  Future<void> setReaderGuideDone() => _prefs.setBool('reader.guideDone', true);

  bool get onboardingDone => _prefs.getBool('onboarding.done') ?? false;
  Future<void> setOnboardingDone(bool v) async {
    await _prefs.setBool('onboarding.done', v);
    notifyListeners();
  }

  // --- Adhan notifications --------------------------------------------------------
  /// Android: play the full adhan even when the phone is on silent / vibrate (on the
  /// alarm volume, like an alarm clock). Off by default. iOS does not allow it.
  bool get adhanPlayOnSilent => _prefs.getBool('adhan.playOnSilent') ?? false;
  Future<void> setAdhanPlayOnSilent(bool v) async {
    await _prefs.setBool('adhan.playOnSilent', v);
    notifyListeners();
  }

  bool get adhanEnabled => _prefs.getBool('adhan.enabled') ?? false;

  /// False until the user has touched the adhan switch (nothing to cancel then).
  bool get adhanConfigured => _prefs.containsKey('adhan.enabled');
  Future<void> setAdhanEnabled(bool v) async {
    await _prefs.setBool('adhan.enabled', v);
    notifyListeners();
  }

  /// Per-prayer switch (all five on by default once notifications are enabled).
  bool adhanFor(String prayer) => _prefs.getBool('adhan.$prayer') ?? true;
  Future<void> setAdhanFor(String prayer, bool v) async {
    await _prefs.setBool('adhan.$prayer', v);
    notifyListeners();
  }

  /// Muezzin for the adhan of Dhuhr, Asr, Maghrib and Isha (see adhan_voices.dart).
  String get adhanVoice {
    final v = _prefs.getString('adhan.voice');
    return isAdhanVoiceId(v) ? v! : defaultAdhanVoice;
  }

  /// Muezzin for the Fajr adhan, which has its own wording ("as-salatu khayrun min an-nawm").
  String get adhanFajrVoice {
    final v = _prefs.getString('adhan.voice.fajr');
    return isAdhanVoiceId(v) ? v! : defaultFajrVoice;
  }

  /// The voice for [prayer]'s adhan.
  String adhanVoiceFor(String prayer) => prayer == 'fajr' ? adhanFajrVoice : adhanVoice;

  Future<void> setAdhanVoice(String id, {bool fajr = false}) async {
    if (!isAdhanVoiceId(id)) throw ArgumentError.value(id, 'voice');
    await _prefs.setString(fajr ? 'adhan.voice.fajr' : 'adhan.voice', id);
    notifyListeners();
  }

  /// Notification sound: 'adhan' (the adhan recording, default), 'tone' (the
  /// phone's notification sound) or 'silent'.
  static const adhanSounds = ['adhan', 'tone', 'silent'];
  String get adhanSound {
    final v = _prefs.getString('adhan.sound');
    return adhanSounds.contains(v) ? v! : 'adhan';
  }

  Future<void> setAdhanSound(String v) async {
    if (!adhanSounds.contains(v)) throw ArgumentError.value(v, 'sound');
    await _prefs.setString('adhan.sound', v);
    notifyListeners();
  }

  /// Reminder this many minutes before each adhan (0 = off).
  int get adhanPreMinutes {
    final v = _prefs.getInt('adhan.pre') ?? 0;
    return preAdhanChoices.contains(v) ? v : 0;
  }

  Future<void> setAdhanPreMinutes(int v) async {
    if (!preAdhanChoices.contains(v)) throw ArgumentError.value(v, 'minutes');
    await _prefs.setInt('adhan.pre', v);
    notifyListeners();
  }

  /// Iqama alert after each enabled adhan.
  bool get iqamaEnabled => _prefs.getBool('adhan.iqama') ?? false;
  Future<void> setIqamaEnabled(bool v) async {
    await _prefs.setBool('adhan.iqama', v);
    notifyListeners();
  }

  /// Minutes from the adhan to the iqama for [prayer].
  int iqamaMinutes(String prayer) => clampIqama(_prefs.getInt('iqama.$prayer') ?? defaultIqamaMinutes[prayer] ?? 15);
  Future<void> setIqamaMinutes(String prayer, int v) async {
    await _prefs.setInt('iqama.$prayer', clampIqama(v));
    notifyListeners();
  }

  /// Iqama minutes per prayer when the iqama alert is on, else null.
  Map<String, int>? get iqamaPlan => iqamaEnabled ? {for (final p in obligatoryPrayers) p: iqamaMinutes(p)} : null;

  /// Sound for [prayer]'s adhan: its own choice, else the general [adhanSound].
  String adhanSoundFor(String prayer) {
    final v = _prefs.getString('adhan.sound.$prayer');
    return adhanSounds.contains(v) ? v! : adhanSound;
  }

  /// Whether [prayer] has its own sound (otherwise it follows [adhanSound]).
  bool hasOwnSound(String prayer) => adhanSounds.contains(_prefs.getString('adhan.sound.$prayer'));

  /// Null clears the prayer's own choice (it follows the general sound again).
  Future<void> setAdhanSoundFor(String prayer, String? v) async {
    if (v == null) {
      await _prefs.remove('adhan.sound.$prayer');
    } else {
      if (!adhanSounds.contains(v)) throw ArgumentError.value(v, 'sound');
      await _prefs.setString('adhan.sound.$prayer', v);
    }
    notifyListeners();
  }

  /// Notification at sunrise (end of the Fajr time).
  bool get sunriseAlert => _prefs.getBool('alert.sunrise') ?? false;
  Future<void> setSunriseAlert(bool v) async {
    await _prefs.setBool('alert.sunrise', v);
    notifyListeners();
  }

  /// Notification at the start of the last third of the night (qiyam).
  bool get lastThirdAlert => _prefs.getBool('alert.lastThird') ?? false;
  Future<void> setLastThirdAlert(bool v) async {
    await _prefs.setBool('alert.lastThird', v);
    notifyListeners();
  }

  /// Friday reminder (Surat al-Kahf) as minutes after midnight, or null when off.
  int? get fridayReminder => _prefs.getInt('alert.friday');
  Future<void> setFridayReminder(int? minutes) async {
    if (minutes == null) {
      await _prefs.remove('alert.friday');
    } else {
      await _prefs.setInt('alert.friday', minutes.clamp(0, 24 * 60 - 1));
    }
    notifyListeners();
  }

  /// Morning / evening adhkar reminders as minutes after midnight, or null when off.
  int? adhkarReminder(bool morning) => _prefs.getInt(morning ? 'alert.adhkarMorning' : 'alert.adhkarEvening');
  Future<void> setAdhkarReminder(bool morning, int? minutes) async {
    final key = morning ? 'alert.adhkarMorning' : 'alert.adhkarEvening';
    if (minutes == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, minutes.clamp(0, 24 * 60 - 1));
    }
    notifyListeners();
  }

  /// The home radio station (owner, 2026-11-11: Cairo Quran radio by default). "mushaf" = the
  /// app's whole-Mushaf radio; otherwise a live stream (id, name, url).
  String get radioStation => _prefs.getString('radio.station') ?? 'radio-eg';
  String? get radioStationName => _prefs.getString('radio.stationName');
  String? get radioStationUrl => _prefs.getString('radio.stationUrl');
  Future<void> setRadioStation(String id, {String? name, String? url}) async {
    await _prefs.setString('radio.station', id);
    if (name != null) await _prefs.setString('radio.stationName', name);
    if (url != null) await _prefs.setString('radio.stationUrl', url);
    notifyListeners();
  }

  /// Adhkar and Hisn al-Muslim shown one card at a time instead of a list.
  bool get adhkarCards => _prefs.getBool('adhkar.cards') ?? true;
  Future<void> setAdhkarCards(bool v) async {
    await _prefs.setBool('adhkar.cards', v);
    notifyListeners();
  }

  /// Days the app was opened, for the one-time "share Rattil" suggestion, and whether it was answered.
  List<String> get sharePromptDays => _prefs.getStringList('sharePrompt.days') ?? const [];
  bool get sharePromptDone => _prefs.getBool('sharePrompt.done') ?? false;
  Future<void> setSharePrompt({List<String>? days, bool? done}) async {
    if (days != null) await _prefs.setStringList('sharePrompt.days', days);
    if (done != null) await _prefs.setBool('sharePrompt.done', done);
  }

  /// Zakat calculator: what the user typed (kept on this device only).
  Map<String, double> get zakatValues {
    final raw = _prefs.getString('zakat.values');
    if (raw == null) return const {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          if (e.value is num && (e.value as num) > 0) e.key: (e.value as num).toDouble(),
      };
    } on FormatException {
      return const {};
    } on TypeError {
      return const {};
    }
  }

  double get zakatGoldPrice => _prefs.getDouble('zakat.price') ?? 0;
  bool get zakatYearPassed => _prefs.getBool('zakat.year') ?? false;

  Future<void> setZakat({Map<String, double>? values, double? price, bool? yearPassed}) async {
    if (values != null) await _prefs.setString('zakat.values', jsonEncode(values));
    if (price != null) await _prefs.setDouble('zakat.price', price);
    if (yearPassed != null) await _prefs.setBool('zakat.year', yearPassed);
  }

  /// Saved hadiths as "book:n" keys, newest first.
  List<String> get hadithFavourites => _prefs.getStringList('hadith.favourites') ?? const [];

  Future<void> toggleHadithFavourite(String book, int n) async {
    final key = '$book:$n';
    final list = hadithFavourites;
    await _prefs.setStringList(
      'hadith.favourites',
      list.contains(key)
          ? [
              for (final k in list)
                if (k != key) k,
            ]
          : [key, ...list],
    );
    notifyListeners();
  }

  /// Prayers that should get a notification right now.
  Set<String> get adhanPrayers => adhanEnabled
      ? {
          for (final p in obligatoryPrayers)
            if (adhanFor(p)) p,
        }
      : const {};

  // --- Tasbih and adhkar progress (raw JSON, owned by their controllers) --------
  String? rawJson(String key) => _prefs.getString(key);
  Future<void> setRawJson(String key, String value) => _prefs.setString(key, value);

  // --- Account ----------------------------------------------------------------
  String get apiBaseUrl => _prefs.getString('apiBaseUrl') ?? defaultApiBaseUrl;
  Future<void> setApiBaseUrl(String url) async {
    await _prefs.setString('apiBaseUrl', url);
    notifyListeners();
  }
}
