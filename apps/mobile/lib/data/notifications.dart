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

class LocalNotificationsBackend implements NotificationsBackend {
  LocalNotificationsBackend({bool? fullAdhanOnAndroid})
    : _fullAdhan = fullAdhanOnAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final _plugin = FlutterLocalNotificationsPlugin();

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
    final voice = voiceName.startsWith('/') ? 'adhan_haram' : voiceName;
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
    );
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
    if (_fullAdhan) await _adhanChannel.invokeMethod<void>('cancelAll');
  }

  /// Label of the Android "stop" action (set by the scheduler from l10n).
  String stopLabel = 'إيقاف';

  /// The muezzin for the next schedule() call: an Android res/raw name or a
  /// downloaded file's path (set by the scheduler, per prayer).
  String voice = 'adhan_haram';

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime atUtc,
    String sound = 'adhan',
  }) async {
    await init();
    if (_fullAdhan && sound == 'adhan') {
      await _adhanChannel.invokeMethod<void>('schedule', {
        'id': id,
        'atMillis': atUtc.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'stopLabel': stopLabel,
        'voice': voice,
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
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: nextOccurrence(hour: hour, minute: minute, location: location, nowUtc: nowUtc, weekday: weekday),
      notificationDetails: const NotificationDetails(
        android: _reminderAndroid,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
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
  });

  /// Downloaded muezzin recordings (null in tests that do not need them).
  final AdhanVoiceFiles? voices;

  /// What Android plays for [prayer]'s adhan.
  String nativeVoiceFor(String prayer) {
    final id = settings.adhanVoiceFor(prayer);
    final fajr = prayer == 'fajr';
    final v = voices;
    if (v != null) return v.nativeVoice(id, fajr: fajr);
    return (bundledAdhanVoice(id) ?? bundledAdhanVoice(fajr ? defaultFajrVoice : defaultAdhanVoice)!).raw!;
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

  List<AdhanNotification> get lastPlan => _lastPlan;

  String get _signature => [
    settings.adhanPrayers.toList()..sort(),
    settings.adhanSound,
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
  ].join('|');

  /// Plans with the same inputs as the prayer screen.
  List<AdhanNotification> plan() {
    final enabled = settings.adhanPrayers;
    if (enabled.isEmpty) return const [];
    final ctx = PrayerInputs.resolve(content, settings);
    final schedule = PrayerSchedule(content.calculator);
    final now = clock().toUtc();
    return planAdhanNotifications(
      nowUtc: now,
      today: PrayerSchedule.localDate(ctx.location, now),
      enabled: enabled,
      days: days,
      max: max - (reserved?.call() ?? 0),
      preMinutes: settings.adhanPreMinutes,
      iqama: settings.iqamaPlan,
      sunrise: settings.sunriseAlert,
      lastThird: settings.lastThirdAlert,
      dayFor: (d) => ctx.day(schedule, d, settings.adjustments),
    );
  }

  /// Re-plans when anything relevant changed (or when [force]).
  Future<void> sync({bool force = false}) async {
    if (!settings.adhanConfigured) return;
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
      if (b is LocalNotificationsBackend) b.stopLabel = l.adhanStop;
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
    }
    await backend.schedule(
      id: adhanTestNotificationId,
      title: l.adhanTestTitle,
      body: l.adhanTestBody,
      atUtc: clock().toUtc().add(delay),
      sound: settings.adhanSound,
    );
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
  /// [source]: a bundled asset ("assets/...") or a downloaded file's path.
  Future<void> play(String source);
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
  Future<void> play(String source) async {
    if (source.startsWith('assets/')) {
      await _p.setAsset(source);
    } else {
      await _p.setFilePath(source);
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
    : _source = source ?? ((id) async => bundledAdhanVoice(id)?.asset) {
    _sub = _player.completed.listen((_) => _set(null));
  }

  final AdhanPlayer _player;
  final Future<String?> Function(String voiceId) _source;
  late final StreamSubscription<void> _sub;
  String? _voice;

  /// Whether a recording is playing; [voice] says which muezzin.
  bool get playing => _voice != null;
  String? get voice => _voice;

  void _set(String? v) {
    if (_voice == v) return;
    _voice = v;
    notifyListeners();
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
