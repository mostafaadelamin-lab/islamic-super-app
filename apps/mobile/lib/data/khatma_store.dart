import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/khatma.dart';
import '../l10n/app_localizations.dart';
import 'reminders.dart';
import 'settings.dart';

/// The user's khatma plan and finished khatmas, persisted as JSON in the settings store.
class KhatmaController extends ChangeNotifier {
  KhatmaController(this._settings, this._today, {this.onReminderChanged}) {
    try {
      _state = KhatmaState.fromJson(jsonDecode(_settings.rawJson(_key) ?? 'null'));
    } catch (_) {
      _state = const KhatmaState();
    }
  }

  static const _key = 'khatma';
  final SettingsController _settings;

  /// Today's date in the prayer city's time zone.
  final DateTime Function() _today;

  /// Re-schedules the daily reminder.
  final Future<void> Function()? onReminderChanged;
  late KhatmaState _state;

  KhatmaState get state => _state;
  Khatma? get current => _state.current;
  DateTime get today => _today();

  Future<void> _save(KhatmaState s, {bool reminder = false}) async {
    _state = s;
    notifyListeners();
    await _settings.setRawJson(_key, jsonEncode(s.toJson()));
    if (reminder) await onReminderChanged?.call();
  }

  Future<void> start(Khatma k) => _save(KhatmaState(current: k, history: _state.history), reminder: true);
  Future<void> completeWird() =>
      _save(_state.completeWird(today), reminder: _state.current?.done == (_state.current?.wirds ?? 0) - 1);
  Future<void> reschedule() async {
    final k = current;
    if (k != null) await _save(KhatmaState(current: k.reschedule(today), history: _state.history));
  }

  Future<void> rename(String name) async {
    final k = current;
    final n = name.trim();
    if (k == null || n.isEmpty) return;
    await _save(
      KhatmaState(
        current: k.copyWith(name: n),
        history: _state.history,
      ),
    );
  }

  Future<void> setReminder(int? minutes) async {
    final k = current;
    if (k != null) {
      await _save(
        KhatmaState(
          current: k.copyWith(reminderMinutes: () => minutes),
          history: _state.history,
        ),
        reminder: true,
      );
    }
  }

  Future<void> delete() => _save(KhatmaState(history: _state.history), reminder: true);

  /// The daily reminder while a khatma with a reminder time is running.
  List<ReminderSpec> reminders(AppLocalizations l) {
    final k = current;
    final m = k?.reminderMinutes;
    if (k == null || m == null || k.finished) return const [];
    return [
      ReminderSpec(
        id: ReminderIds.khatma,
        title: l.khatmaReminderTitle,
        body: l.khatmaReminderBody(k.name),
        minutes: m,
      ),
    ];
  }
}
