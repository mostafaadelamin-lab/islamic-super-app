import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/adhan_schedule.dart';
import '../domain/adhan_voices.dart';
import 'adhan_voice_files.dart';
import '../domain/prayer_schedule.dart';
import '../l10n/app_localizations.dart';
import '../ui/prayer_model.dart';
import 'content.dart';
import 'settings.dart';

/// What the adhan scheduler needs from a notification plugin.
abstract class NotificationsBackend {
  Future<void> init();

  /// Asks the user (Android 13+ / iOS); true when notifications are allowed.
  Future<bool> requestPermission();
  Future<void> cancelAll();
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime atUtc,
    String sound = 'adhan',
    AdhanRing? ring,
  });

  /// A notification repeating every day (or every week on [weekday], 1 = Monday)
  /// at [hour]:[minute] in [location] (the prayer city's time zone).
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required tz.Location location,
    required DateTime nowUtc,
    int? weekday,
    String? sound,
  });

  Future<void> cancel(int id);
}

/// The next instant at [hour]:[minute] (on [weekday] when given) in [location]
/// strictly after [nowUtc].
tz.TZDateTime nextOccurrence({
  required int hour,
  required int minute,
  required tz.Location location,
  required DateTime nowUtc,
  int? weekday,
}) {
  final now = tz.TZDateTime.from(nowUtc, location);
  var t = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
  while (!t.isAfter(now) || (weekday != null && t.weekday != weekday)) {
    t = tz.TZDateTime(location, t.year, t.month, t.day + 1, hour, minute);
  }
  return t;
}

/// Id of the one-off "try it now" notification (real ids are yyyymmddN).
const adhanTestNotificationId = 1;

/// iPhone: "open the app to keep the full adhan", shortly before the full adhans planned run out.
const adhanOpenAppNotificationId = 2;

/// iPhone: how one adhan rings. iOS plays at most 30 s of a notification sound, so the recording is cut
/// (natively, at the pauses between its phrases) into [parts] of at most 29 s, saved as
/// Library/Sounds/[adhanPartSound]. Owner 2026-11-26: only the first part rings, as ONE notification
/// (each further part used to show as its own «تكملة الأذان» notification on the lock screen, five or six
/// per prayer); tapping it plays the rest in the app. With [alarm] (iOS 26+, AlarmKit) the whole recording
/// rings as one system alarm instead.
class AdhanRing {
  const AdhanRing({
    required this.voice,
    required this.parts,
    this.alarm = false,
    this.count,
    this.moreBody = '',
    this.openLabel = '',
  });

  /// The muezzin's id (see adhan_voices.dart) whose recording was cut.
  final String voice;

  /// Length of each part in whole seconds; empty when the recording could not be cut (then the opening
  /// takbir, Runner/adhan_short.caf, rings alone).
  final List<int> parts;

  /// Ring as a system alarm with the whole recording.
  final bool alarm;

  /// How many of the [parts] ring (fewer when the 64 pending notifications iOS allows run out: the far
  /// days then ring the first 30 s only); null = all.
  final int? count;

  AdhanRing take(int n) =>
      AdhanRing(voice: voice, parts: parts, alarm: alarm, count: n, moreBody: moreBody, openLabel: openLabel);

  /// Line added under the notification's text when the adhan is longer than what rings ("tap to hear
  /// the whole adhan in the app").
  final String moreBody;

  /// Label of the alarm's button that opens the app to continue the adhan.
  final String openLabel;

  int get seconds => parts.fold(0, (a, b) => a + b);

  /// What opening the app from this adhan's notification (or alarm) hands to [AdhanScheduler.continueFrom].
  /// The last field is how many parts ring as notifications (the rest plays in the app).
  String payload(int id, DateTime atUtc) =>
      'adhan|$id|$voice|${atUtc.millisecondsSinceEpoch}|${parts.join(',')}|${count ?? parts.length}';
}

/// File name (in Library/Sounds) of part [k] of [voice]'s recording, written by AppDelegate.swift.
String adhanPartSound(String voice, int k) => 'rattil_adhan_${voice}_$k.caf';

/// File name of [voice]'s whole recording for the iOS alarm.
String adhanFullSound(String voice) => 'rattil_adhan_${voice}_full.caf';

/// iPhone: cuts a muezzin's recording into notification sounds (native code in AppDelegate.swift).
abstract class AdhanSoundParts {
  /// Lengths (seconds) of the parts of [voice]'s recording at [source] (a bundled "assets/..." path or a
  /// downloaded file); empty when it cannot be done. Cached: the cut happens once per recording.
  Future<List<int>> prepare(String voice, String source);

  /// iOS 26+ alarms: 'unavailable', 'notDetermined', 'denied' or 'authorized'.
  Future<String> alarmState();

  /// Asks iOS for the alarm permission; the new state.
  Future<String> requestAlarms();

  /// The adhan the user opened the app for from an alarm's "continue" button, once (or null).
  Future<String?> takeAlarmTap();
}

class NativeAdhanSoundParts implements AdhanSoundParts {
  static const _channel = MethodChannel('org.rattil.app/adhan');
  final _cache = <String, List<int>>{};

  @override
  Future<List<int>> prepare(String voice, String source) async {
    final key = '$voice|$source';
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final r = await _channel.invokeListMethod<int>('prepareParts', {
        'voice': voice,
        if (source.startsWith('assets/')) 'asset': source else 'path': source,
      });
      final parts = (r ?? const <int>[]).where((s) => s > 0).toList();
      if (parts.isNotEmpty) _cache[key] = parts;
      return parts;
    } catch (e) {
      debugPrint('adhan parts for $voice failed: $e');
      return const [];
    }
  }

  @override
  Future<String> alarmState() async {
    try {
      return await _channel.invokeMethod<String>('alarmState') ?? 'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  @override
  Future<String> requestAlarms() async {
    try {
      return await _channel.invokeMethod<String>('alarmRequest') ?? 'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  @override
  Future<String?> takeAlarmTap() async {
    try {
      return await _channel.invokeMethod<String>('takeAlarmTap');
    } catch (_) {
      return null;
    }
  }
}

class LocalNotificationsBackend implements NotificationsBackend {
  LocalNotificationsBackend({bool? fullAdhanOnAndroid})
    : _fullAdhan = fullAdhanOnAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final _plugin = FlutterLocalNotificationsPlugin();

  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  final _taps = StreamController<String>.broadcast();
  String? _launchTap;

  /// iPhone: payloads ([AdhanRing.payload]) of the adhan notifications the user opens the app from.
  Stream<String> get adhanTaps => _taps.stream;

  /// The adhan notification that started the app, once (or null).
  String? takeLaunchTap() {
    final p = _launchTap;
    _launchTap = null;
    return p;
  }

  /// Android plays the whole adhan through an exact alarm + a media foreground
  /// service (android/.../AdhanAlarms.kt, AdhanService.kt): a notification
  /// sound alone may be cut short. Tone and silent alerts stay notifications.
  final bool _fullAdhan;
  static const _adhanChannel = MethodChannel('org.rattil.app/adhan');
  bool _ready = false;
  bool _exact = false;

  // Android ties the sound to the channel, so each sound choice has its own
  // channel (the user can still fine-tune each one in the system settings).
  static AndroidNotificationDetails _android(String sound, String stopLabel, String voiceName) {
    // A downloaded recording cannot be a channel sound: the channel keeps the default adhan.
    final voice = voiceName.startsWith('/') ? 'adhan_mulla' : voiceName;
    return switch (sound) {
      'tone' => const AndroidNotificationDetails(
        'adhan_tone',
        'تنبيه الصلاة (نغمة) · Prayer alert (tone)',
        channelDescription: 'Prayer time notifications with the phone sound',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
      'silent' => const AndroidNotificationDetails(
        'adhan_silent',
        'تنبيه الصلاة (صامت) · Prayer alert (silent)',
        channelDescription: 'Prayer time notifications without sound',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
      ),
      _ => AndroidNotificationDetails(
        // One channel per muezzin: a channel's sound cannot change once created.
        voice == 'adhan' ? 'adhan_voice' : 'adhan_voice_$voice',
        'الأذان · Adhan',
        channelDescription: 'Prayer time notifications with the adhan recording',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        // res/raw/<voice>.ogg (see assets/audio/ADHAN_AUDIO.md for the licences).
        sound: RawResourceAndroidNotificationSound(voice),
        // Tapping "stop" or the notification itself silences the adhan.
        actions: [AndroidNotificationAction('stop', stopLabel, cancelNotification: true)],
      ),
    };
  }

  // iOS plays at most 30 s of a notification sound, so it gets the opening
  // takbir only (Runner/adhan_short.caf); the full adhan plays inside the app.
  static DarwinNotificationDetails _darwin(String sound) => switch (sound) {
    'tone' => const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    'silent' => const DarwinNotificationDetails(presentAlert: true, presentSound: false),
    _ => const DarwinNotificationDetails(presentAlert: true, presentSound: true, sound: 'adhan_short.caf'),
  };

  @override
  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_rattil'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.startsWith('adhan|')) _taps.add(p);
      },
    );
    if (_ios) {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final p = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && p != null && p.startsWith('adhan|')) _launchTap = p;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    _exact = await android?.canScheduleExactNotifications() ?? false;
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission() ?? false;
      if (ok && !_exact) {
        // Exact alarms keep the adhan on the minute; without them Android may delay it.
        await android.requestExactAlarmsPermission();
        _exact = await android.canScheduleExactNotifications() ?? false;
      }
      return ok;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true, badge: false) ?? false;
    return false;
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
    if (_fullAdhan || _ios) {
      try {
        await _adhanChannel.invokeMethod<void>('cancelAll');
      } catch (e) {
        debugPrint('adhan cancelAll: $e');
      }
    }
  }

  /// Label of the Android "stop" action (set by the scheduler from l10n).
  String stopLabel = 'إيقاف';

  /// The muezzin for the next schedule() call: an Android res/raw name or a
  /// downloaded file's path (set by the scheduler, per prayer).
  String voice = 'adhan_mulla';

  /// Android: play the full adhan even in silent / vibrate mode (set by the scheduler).
  bool playOnSilent = false;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime atUtc,
    String sound = 'adhan',
    AdhanRing? ring,
  }) async {
    await init();
    if (_ios && ring != null && sound == 'adhan') return _scheduleIos(id, title, body, atUtc, ring);
    if (_fullAdhan && sound == 'adhan') {
      await _adhanChannel.invokeMethod<void>('schedule', {
        'id': id,
        'atMillis': atUtc.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'stopLabel': stopLabel,
        'voice': voice,
        'playOnSilent': playOnSilent,
      });
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(atUtc, tz.UTC),
      notificationDetails: NotificationDetails(android: _android(sound, stopLabel, voice), iOS: _darwin(sound)),
      androidScheduleMode: _exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// iPhone: the full adhan as parts back to back, or as one system alarm (see [AdhanRing]).
  Future<void> _scheduleIos(int id, String title, String body, DateTime atUtc, AdhanRing ring) async {
    final payload = ring.payload(id, atUtc);
    if (ring.alarm) {
      await _adhanChannel.invokeMethod<void>('alarmSchedule', {
        'id': id,
        'atMillis': atUtc.millisecondsSinceEpoch,
        'title': title,
        'sound': adhanFullSound(ring.voice),
        'stopLabel': stopLabel,
        'openLabel': ring.openLabel,
        'payload': payload,
      });
      return;
    }
    final parts = ring.parts.isEmpty ? const [0] : ring.parts;
    final count = (ring.count ?? parts.length).clamp(1, parts.length);
    var offset = 0;
    for (var k = 0; k < count; k++) {
      await _plugin.zonedSchedule(
        id: k == 0 ? id : adhanPartId(id, k),
        title: title,
        body: k == 0
            ? (count < parts.length && ring.moreBody.isNotEmpty ? '$body\n${ring.moreBody}' : body)
            : ring.moreBody,
        scheduledDate: tz.TZDateTime.from(atUtc.add(Duration(seconds: offset)), tz.UTC),
        notificationDetails: NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            // In the app only the first part shows a banner; the rest just sound.
            presentBanner: k == 0,
            presentList: k == 0,
            presentSound: true,
            sound: ring.parts.isEmpty ? 'adhan_short.caf' : adhanPartSound(ring.voice, k),
            threadIdentifier: 'adhan_$id',
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      offset += parts[k];
    }
  }

  static const _reminderAndroid = AndroidNotificationDetails(
    'reminders',
    'تذكيرات (الورد، الأذكار، الجمعة) · Reminders',
    channelDescription: 'Daily khatma portion, morning/evening adhkar and Friday reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required tz.Location location,
    required DateTime nowUtc,
    int? weekday,
    String? sound,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: nextOccurrence(hour: hour, minute: minute, location: location, nowUtc: nowUtc, weekday: weekday),
      notificationDetails: sound == null
          ? const NotificationDetails(
              android: _reminderAndroid,
              iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
            )
          : NotificationDetails(
              // One channel per dhikr: Android ties the sound to the channel. The system
              // plays it only when the ringer is on, so a silent phone just shows the dhikr.
              android: AndroidNotificationDetails(
                'dhikr_$sound',
                'تذكير بالذكر · Dhikr reminder',
                channelDescription: 'The chosen dhikr, said aloud by Sheikh Mishary Alafasy',
                importance: Importance.high,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound(sound),
              ),
              iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, sound: '$sound.caf'),
            ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }
}

/// Keeps the scheduled adhan notifications in line with the settings: the
/// next [days] days for the enabled prayers of the selected city.
class AdhanScheduler {
  AdhanScheduler({
    required this.content,
    required this.settings,
    required this.backend,
    required this.clock,
    this.days = 7,
    this.max = 60,
    this.reserved,
    this.afterReset,
    this.voices,
    this.parts,
  });

  /// iPhone: cuts the recordings into notification sounds so the whole adhan rings (null elsewhere).
  final AdhanSoundParts? parts;

  /// Downloaded muezzin recordings (null in tests that do not need them).
  final AdhanVoiceFiles? voices;

  /// What Android plays for [prayer]'s adhan.
  String nativeVoiceFor(String prayer) {
    final id = settings.adhanVoiceFor(prayer);
    final fajr = prayer == 'fajr';
    final v = voices;
    if (v != null) return v.nativeVoice(id, fajr: fajr);
    final b = findAdhanVoice(id);
    return (b != null && b.bundled ? b : findAdhanVoice(fajr ? defaultFajrVoice : defaultAdhanVoice)!).raw!;
  }

  /// Pending slots kept for the repeating reminders (khatma, adhkar, Friday),
  /// taken from [max] (iOS keeps at most 64 pending notifications in all).
  final int Function()? reserved;

  /// Runs after every re-plan (which cancels all pending notifications), so
  /// the repeating reminders are scheduled again.
  final Future<void> Function()? afterReset;

  final AppContent content;
  final SettingsController settings;
  final NotificationsBackend backend;
  final DateTime Function() clock;
  final int days;

  /// Cap on pending notifications (iOS keeps at most 64 per app).
  final int max;
  String? _lastSignature;
  List<AdhanNotification> _lastPlan = const [];

  /// iPhone: how each prayer's adhan rings (only prayers with the adhan sound), set by [sync].
  Map<String, AdhanRing> _rings = const {};

  /// The muezzin that really sounds for [prayer]: the chosen one once it is on the phone, else the default.
  String voiceFor(String prayer) {
    final id = settings.adhanVoiceFor(prayer);
    final fallback = prayer == 'fajr' ? defaultFajrVoice : defaultAdhanVoice;
    final v = voices;
    if (v != null) return v.isReady(id) ? id : fallback;
    return (findAdhanVoice(id)?.bundled ?? false) ? id : fallback;
  }

  Future<Map<String, AdhanRing>> _iosRings(AdhanSoundParts p) async {
    final l = lookupAppLocalizations(Locale(settings.locale.languageCode));
    final alarm = settings.adhanIosAlarm && await p.alarmState() == 'authorized';
    final out = <String, AdhanRing>{};
    for (final prayer in obligatoryPrayers) {
      if (settings.adhanSoundFor(prayer) != 'adhan') continue;
      final voice = voiceFor(prayer);
      final source = findAdhanVoice(voice)?.asset ?? voices?.localPath(voice);
      final durations = source == null ? const <int>[] : await p.prepare(voice, source);
      out[prayer] = AdhanRing(
        voice: voice,
        parts: durations,
        alarm: alarm && durations.isNotEmpty,
        moreBody: l.adhanTapForFull,
        openLabel: l.adhanOpenApp,
      );
    }
    return out;
  }

  /// Notifications [prayer]'s adhan takes on iPhone: 0 = a system alarm, else 1 (owner 2026-11-26: one
  /// notification per adhan, never the parts one after another).
  int _partsFor(String prayer) => (_rings[prayer]?.alarm ?? false) ? 0 : 1;

  List<AdhanNotification> get lastPlan => _lastPlan;

  String get _signature => [
    settings.adhanPrayers.toList()..sort(),
    settings.adhanSound,
    settings.adhanPlayOnSilent,
    [for (final p in obligatoryPrayers) nativeVoiceFor(p)],
    [for (final p in obligatoryPrayers) settings.adhanSoundFor(p)],
    settings.sunriseAlert,
    settings.lastThirdAlert,
    settings.adhanPreMinutes,
    settings.iqamaPlan,
    settings.cityId,
    settings.gpsLocation,
    settings.method,
    settings.asr,
    settings.adjustments,
    settings.locale.languageCode,
    PrayerSchedule.localDate(tz.UTC, clock().toUtc()),
    [for (final e in _rings.entries) '${e.key}:${e.value.voice}:${e.value.parts.length}:${e.value.alarm}'],
  ].join('|');

  /// iPhone: the notifications the adhan and its alerts take in the next 48 hours (each full adhan as
  /// all its parts) plus the "open the app" reminder; 0 on Android. Owner 2026-11-22: the adhan comes
  /// first, the dhikr reminders only get what is left of the 64.
  int get iosNeed {
    if (parts == null || settings.adhanPrayers.isEmpty) return 0;
    final now = clock().toUtc();
    final until = now.add(const Duration(hours: 48));
    var n = 1;
    for (final a in _alerts(now, 1 << 20)) {
      if (!a.at.isBefore(until)) break;
      n += a.kind == adhanKind ? _partsFor(a.prayer).clamp(0, maxAdhanParts) : 1;
    }
    return n;
  }

  List<AdhanNotification> _alerts(DateTime now, int max) {
    final enabled = settings.adhanPrayers;
    if (enabled.isEmpty) return const [];
    final ctx = PrayerInputs.resolve(content, settings);
    final schedule = PrayerSchedule(content.calculator);
    return planAdhanNotifications(
      nowUtc: now,
      today: PrayerSchedule.localDate(ctx.location, now),
      enabled: enabled,
      days: days,
      max: max,
      preMinutes: settings.adhanPreMinutes,
      iqama: settings.iqamaPlan,
      sunrise: settings.sunriseAlert,
      lastThird: settings.lastThirdAlert,
      dayFor: (d) => ctx.day(schedule, d, settings.adjustments),
    );
  }

  /// Plans with the same inputs as the prayer screen.
  List<AdhanNotification> plan() {
    final enabled = settings.adhanPrayers;
    if (enabled.isEmpty) return const [];
    final ctx = PrayerInputs.resolve(content, settings);
    final schedule = PrayerSchedule(content.calculator);
    final now = clock().toUtc();
    final budget = max - (reserved?.call() ?? 0);
    final all = planAdhanNotifications(
      nowUtc: now,
      today: PrayerSchedule.localDate(ctx.location, now),
      enabled: enabled,
      days: days,
      // iPhone: every alert first, then [fitFullAdhan] shares the budget with the full adhans.
      max: parts == null ? budget : 1 << 20,
      preMinutes: settings.adhanPreMinutes,
      iqama: settings.iqamaPlan,
      sunrise: settings.sunriseAlert,
      lastThird: settings.lastThirdAlert,
      dayFor: (d) => ctx.day(schedule, d, settings.adjustments),
    );
    if (parts == null) return all;
    // One slot stays for the "open the app" reminder.
    return fitFullAdhan(all, partsFor: _partsFor, nowUtc: now, max: budget - 1);
  }

  /// Re-plans when anything relevant changed (or when [force]).
  Future<void> sync({bool force = false}) async {
    if (!settings.adhanConfigured) return;
    final p = parts;
    if (p != null && settings.adhanEnabled) {
      try {
        _rings = await _iosRings(p);
      } catch (e) {
        _rings = const {};
        debugPrint('adhan parts failed: $e');
      }
    }
    final sig = _signature;
    if (!force && sig == _lastSignature) return;
    _lastSignature = sig;
    try {
      final items = plan();
      _lastPlan = items;
      await backend.cancelAll();
      await afterReset?.call();
      if (items.isEmpty) return;
      final l = lookupAppLocalizations(Locale(settings.locale.languageCode));
      final b = backend;
      if (b is LocalNotificationsBackend) {
        b.stopLabel = l.adhanStop;
        b.playOnSilent = settings.adhanPlayOnSilent;
      }
      final city = resolveCity(content, settings).name(settings.isArabic);
      for (final n in items) {
        final name = _prayerName(l, n.prayer);
        final minutes = n.minutes.toString();
        // Reminders and iqama alerts use the short phone tone (never the adhan
        // recording), or stay silent when the user chose silent alerts.
        final extraSound = settings.adhanSound == 'silent' ? 'silent' : 'tone';
        if (b is LocalNotificationsBackend) b.voice = nativeVoiceFor(n.prayer);
        await backend.schedule(
          id: n.id,
          title: switch (n.kind) {
            sunriseKind => l.alertSunriseTitle,
            lastThirdKind => l.alertLastThirdTitle,
            preAdhanKind => l.adhanPreTitle(minutes, name),
            iqamaKind => l.adhanIqamaTitle(name),
            _ => l.adhanTitle(name),
          },
          body: switch (n.kind) {
            sunriseKind => l.alertSunriseBody(city),
            lastThirdKind => l.alertLastThirdBody,
            preAdhanKind => l.adhanPreBody(name),
            iqamaKind => l.adhanIqamaBody(name, minutes),
            _ => l.adhanBody(name, city),
          },
          atUtc: n.at,
          sound: n.kind == adhanKind ? settings.adhanSoundFor(n.prayer) : extraSound,
          ring: n.kind == adhanKind ? _rings[n.prayer]?.take(n.parts) : null,
        );
      }
    } catch (e) {
      // A plugin failure must never break the app; the next sync retries.
      _lastSignature = null;
      debugPrint('adhan scheduling failed: $e');
    }
  }

  /// A notification [delay] from now with the chosen sound, so the user can
  /// check that the adhan really sounds on this phone.
  Future<void> test({Duration delay = const Duration(seconds: 10)}) async {
    final l = lookupAppLocalizations(Locale(settings.locale.languageCode));
    final b = backend;
    if (b is LocalNotificationsBackend) {
      b.stopLabel = l.adhanStop;
      b.voice = nativeVoiceFor('dhuhr');
      b.playOnSilent = settings.adhanPlayOnSilent;
    }
    await backend.schedule(
      id: adhanTestNotificationId,
      title: l.adhanTestTitle,
      body: l.adhanTestBody,
      atUtc: clock().toUtc().add(delay),
      sound: settings.adhanSound,
      ring: _rings['dhuhr'],
    );
  }

  /// iPhone: the user opened the app from an adhan notification (or the alarm's "continue" button), so the
  /// rest of the adhan plays in the app from where the notifications reached, and its remaining
  /// notifications are removed (which also silences the one sounding now). [payload]: [AdhanRing.payload].
  Future<void> continueFrom(String payload, AdhanPreview preview) async {
    final f = payload.split('|');
    if (f.length < 5 || f[0] != 'adhan') return;
    final id = int.tryParse(f[1]);
    final start = int.tryParse(f[3]);
    final parts = [for (final s in f[4].split(',')) ?int.tryParse(s)];
    if (id == null || start == null) return;
    final total = parts.fold<int>(0, (a, b) => a + b);
    var elapsed = clock().toUtc().millisecondsSinceEpoch - start;
    // How many parts rang as notifications (0 or missing = all of them, or the alarm with the whole adhan).
    final rang = f.length > 5 ? (int.tryParse(f[5]) ?? 0) : 0;
    if (rang > 0 && rang < parts.length) {
      // Only the start rang (owner 2026-11-26: one notification per adhan): the rest plays from where that
      // stopped, also when the user taps the notification a while later (up to half an hour).
      final heard = parts.take(rang).fold<int>(0, (a, b) => a + b) * 1000;
      if (elapsed < -60000 || elapsed > 30 * 60000) return;
      if (elapsed > heard) elapsed = heard;
    } else if (elapsed < -60000 || elapsed > (total - 2) * 1000) {
      // Too early (a stale notification) or the adhan is over: nothing to continue.
      return;
    }
    for (var k = 0; k < parts.length && k < maxAdhanParts; k++) {
      try {
        await backend.cancel(k == 0 ? id : adhanPartId(id, k));
      } catch (_) {}
    }
    await preview.continueAdhan(f[2], Duration(milliseconds: elapsed < 0 ? 0 : elapsed));
  }

  static String _prayerName(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    _ => l.prayerIsha,
  };
}

/// Plays an adhan recording inside the app (settings "listen" buttons).
abstract class AdhanPlayer {
  /// [source]: a bundled asset ("assets/...") or a downloaded file's path; [from]: where to start.
  Future<void> play(String source, {Duration from = Duration.zero});
  Future<void> stop();

  /// Fires when the recording reaches its end.
  Stream<void> get completed;
}

class JustAudioAdhanPlayer implements AdhanPlayer {
  AudioPlayer? _player;
  final _completed = StreamController<void>.broadcast();

  AudioPlayer get _p {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    p.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _completed.add(null);
    });
    return _player = p;
  }

  @override
  Future<void> play(String source, {Duration from = Duration.zero}) async {
    final at = from > Duration.zero ? from : null;
    if (source.startsWith('assets/')) {
      await _p.setAsset(source, initialPosition: at);
    } else {
      await _p.setFilePath(source, initialPosition: at);
    }
    unawaited(_p.play());
  }

  @override
  Future<void> stop() async => _player?.stop();

  @override
  Stream<void> get completed => _completed.stream;
}

class AdhanPreview extends ChangeNotifier {
  AdhanPreview(this._player, {Future<String?> Function(String voiceId)? source})
    : _source = source ?? ((id) async => findAdhanVoice(id)?.asset) {
    _sub = _player.completed.listen((_) => _set(null));
  }

  final AdhanPlayer _player;
  final Future<String?> Function(String voiceId) _source;
  late final StreamSubscription<void> _sub;
  String? _voice;

  /// Whether a recording is playing; [voice] says which muezzin.
  bool get playing => _voice != null;
  String? get voice => _voice;

  /// The adhan playing was continued from a prayer-time alert (the app shows a stop bar for it).
  bool get fromAlert => _alert && _voice != null;
  bool _alert = false;

  void _set(String? v) {
    if (v == null) _alert = false;
    if (_voice == v) return;
    _voice = v;
    notifyListeners();
  }

  /// Plays [voiceId]'s recording from [from] (the rest of an adhan that started as a notification).
  Future<void> continueAdhan(String voiceId, Duration from) async {
    if (_voice != null) await _player.stop();
    _alert = true;
    _voice = null;
    _set(voiceId);
    try {
      final source = await _source(voiceId);
      if (source == null || _voice != voiceId) {
        if (_voice == voiceId) _set(null);
        return;
      }
      await _player.play(source, from: from);
    } catch (e) {
      _set(null);
      debugPrint('adhan continue failed: $e');
    }
  }

  /// Stops whatever is playing.
  Future<void> stop() async {
    if (_voice == null) return;
    _set(null);
    await _player.stop();
  }

  /// Plays [voiceId] (downloading it first when needed), or stops it when it is the one playing.
  Future<void> toggle([String voiceId = defaultAdhanVoice]) async {
    final was = _voice;
    if (was != null) {
      _set(null);
      await _player.stop();
      if (was == voiceId) return;
    }
    _set(voiceId);
    try {
      final source = await _source(voiceId);
      if (source == null || _voice != voiceId) {
        if (_voice == voiceId) _set(null);
        return;
      }
      await _player.play(source);
    } catch (e) {
      _set(null);
      debugPrint('adhan preview failed: $e');
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    unawaited(_player.stop());
    super.dispose();
  }
}
