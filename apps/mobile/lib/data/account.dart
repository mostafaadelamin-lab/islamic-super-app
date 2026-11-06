import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'bookmarks.dart';
import 'settings.dart';
import 'sync.dart';

enum AccountMessage {
  registered,
  syncDone,
  serverSaved,
  serverInvalid,
  errOffline,
  errAuth,
  errTaken,
  errPassword,
  errEmail,
  errSession,
  errRateLimit,
  errServer,
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Optional account: register / sign in / sync bookmarks.
class AccountController extends ChangeNotifier {
  AccountController(this._prefs, this._settings, this._bookmarks, this._http, {Clock? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final SettingsController _settings;
  final BookmarksController _bookmarks;
  final http.Client _http;
  final Clock _clock;

  bool _busy = false;
  AccountMessage? _message;
  String? _messageArg;

  bool get busy => _busy;
  AccountMessage? get message => _message;
  String? get messageArg => _messageArg;
  bool get isError => _message != null && _message!.name.startsWith('err') || _message == AccountMessage.serverInvalid;

  String? get token {
    final t = _prefs.getString('account.token');
    final exp = _prefs.getInt('account.expiresAt') ?? 0;
    if (t == null) return null;
    if (exp > 0 && _clock().millisecondsSinceEpoch >= exp) return null;
    return t;
  }

  String? get email => _prefs.getString('account.email');
  bool get signedIn => token != null && email != null;
  DateTime? get lastSync {
    final v = _prefs.getInt('account.lastSync');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  ApiClient get _api => ApiClient(_http, _settings.apiBaseUrl);

  void _set(AccountMessage? m, [String? arg]) {
    _message = m;
    _messageArg = arg;
    notifyListeners();
  }

  void clearMessage() => _set(null);

  Future<bool> saveServer(String url) async {
    if (!ApiClient.isValidBaseUrl(url)) {
      _set(AccountMessage.serverInvalid);
      return false;
    }
    await _settings.setApiBaseUrl(url.trim());
    _set(AccountMessage.serverSaved);
    return true;
  }

  bool _validate(String email, String password) {
    if (!_email.hasMatch(email.trim())) {
      _set(AccountMessage.errEmail);
      return false;
    }
    if (password.length < 10) {
      _set(AccountMessage.errPassword);
      return false;
    }
    return true;
  }

  Future<T?> _run<T>(Future<T> Function() f) async {
    _busy = true;
    _set(null);
    try {
      return await f();
    } on ApiException catch (e) {
      _set(_messageFor(e), e.statusCode?.toString());
      if (e.kind == ApiErrorKind.unauthorized && signedIn) await _clearSession();
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  AccountMessage _messageFor(ApiException e) => switch (e.kind) {
    ApiErrorKind.offline || ApiErrorKind.badUrl => AccountMessage.errOffline,
    ApiErrorKind.unauthorized => signedIn ? AccountMessage.errSession : AccountMessage.errAuth,
    ApiErrorKind.conflict => AccountMessage.errTaken,
    ApiErrorKind.validation => AccountMessage.errServer,
    ApiErrorKind.rateLimited => AccountMessage.errRateLimit,
    ApiErrorKind.server => AccountMessage.errServer,
  };

  Future<void> register(String email, String password) async {
    if (!_validate(email, password)) return;
    final ok = await _run(() async {
      await _api.register(email.trim(), password);
      return true;
    });
    if (ok == true) _set(AccountMessage.registered);
  }

  Future<void> login(String email, String password) async {
    if (!_validate(email, password)) return;
    final r = await _run(() => _api.login(email.trim(), password));
    if (r == null) return;
    await _prefs.setString('account.token', r.accessToken);
    await _prefs.setString('account.email', email.trim());
    await _prefs.setInt(
      'account.expiresAt',
      r.expiresIn > 0 ? _clock().millisecondsSinceEpoch + r.expiresIn * 1000 : 0,
    );
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _prefs.remove('account.token');
    await _prefs.remove('account.expiresAt');
    await _prefs.remove('account.lastSync');
    await _bookmarks.resetSyncState();
  }

  Future<void> logout() async {
    await _clearSession();
    await _prefs.remove('account.email');
    _set(null);
  }

  Future<void> syncNow() async {
    final t = token;
    if (t == null) {
      _set(AccountMessage.errSession);
      return;
    }
    final report = await _run(() => SyncService(_api, _bookmarks).sync(t));
    if (report == null) return;
    await _prefs.setInt('account.lastSync', _clock().millisecondsSinceEpoch);
    _set(AccountMessage.syncDone, '${report.active}');
  }
}
