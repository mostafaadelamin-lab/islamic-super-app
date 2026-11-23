import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/audio_queue.dart';
import '../domain/quran.dart';
import '../domain/stories.dart';
import 'audio_focus.dart';
import 'content.dart';
import 'settings.dart';

/// The little an audio engine has to do for recitation. Implemented with
/// just_audio in the app and by a fake in tests.
abstract class AudioBackend {
  /// Loads [url]; throws when it cannot be fetched or decoded.
  Future<void> load(String url);

  /// Starts (or resumes) playback; returns without waiting for the end.
  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  /// Playback speed (1.0 = normal).
  Future<void> setSpeed(double speed);

  /// Fires each time the loaded file has played to its end.
  Stream<void> get completed;

  /// Jumps inside the loaded file (surah files of timed reciters).
  Future<void> seek(Duration to);

  /// The play position in the loaded file, a few times a second.
  Stream<Duration> get position;
  Future<void> dispose();
}

/// just_audio implementation (streams the everyayah.com MP3 over HTTPS).
class JustAudioBackend implements AudioBackend {
  JustAudioBackend() {
    _sub = _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _completed.add(null);
    });
  }

  final _player = AudioPlayer();
  final _completed = StreamController<void>.broadcast();
  late final StreamSubscription<ProcessingState> _sub;

  @override
  Future<void> load(String url) async {
    await _player.setUrl(url).timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> play() async {
    // just_audio's play() future only completes when playback pauses or ends.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> seek(Duration to) => _player.seek(to);

  @override
  Stream<Duration> get position => _player.createPositionStream(
    minPeriod: const Duration(milliseconds: 40),
    maxPeriod: const Duration(milliseconds: 120),
  );

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _completed.close();
    await _player.dispose();
  }
}

enum RecitationState { idle, loading, playing, paused, error }

/// Plays a queue of per-ayah files (see buildQueue): the basmala before ayah 1
/// where it applies, repeat count, and the current ayah for highlighting and
/// automatic page turning.
class RecitationController extends ChangeNotifier {
  RecitationController({
    required AppContent content,
    required SettingsController settings,
    required AudioBackend Function() backendFactory,
    Future<String?> Function(String reciter, QueueItem item)? localFile,
  }) : _content = content,
       _settings = settings,
       _factory = backendFactory,
       _localFile = localFile {
    AudioFocus.register(this, () => unawaited(interrupt()));
  }

  /// A downloaded copy of an item's file, played instead of streaming.
  final Future<String?> Function(String reciter, QueueItem item)? _localFile;
  final AppContent _content;
  final SettingsController _settings;
  final AudioBackend Function() _factory;
  AudioBackend? _backend;
  StreamSubscription<void>? _completedSub;
  StreamSubscription<Duration>? _positionSub;

  // Timed reciters (one file per surah): the file in the player, where the
  // current ayah ends in it, and where the previous one ended (to go on
  // without a seek when the next ayah follows straight on).
  String? _loadedSrc;
  int? _segmentEndMs;
  int? _lastEndMs;
  bool _seeking = false;

  List<QueueItem> _queue = const [];
  int _index = 0;
  int _generation = 0;
  RecitationState _state = RecitationState.idle;
  PlayScope _scope = PlayScope.ayah;

  RecitationState get state => _state;
  List<QueueItem> get queue => List.unmodifiable(_queue);
  int get index => _index;
  PlayScope get scope => _scope;
  bool get isActive => _state != RecitationState.idle;
  bool get isPlaying => _state == RecitationState.playing || _state == RecitationState.loading;

  bool _interrupted = false;

  /// Another sound (adhkar, a nasheed…) paused the recitation; the Mushaf reopens at its ayah.
  bool get wasInterrupted => _interrupted && _state == RecitationState.paused;

  QueueItem? get current => _state == RecitationState.idle || _queue.isEmpty ? null : _queue[_index];

  /// The ayah being recited (for highlighting), null when idle.
  AyahRef? get currentRef => current?.ref;

  /// The Mushaf page of the ayah being recited, null when idle.
  int? get currentPage {
    final c = current;
    return c == null ? null : pageForItem(_content.quran, c);
  }

  /// A reciter used for this playback only (the kids' teaching Mushaf), without
  /// changing the reciter chosen in the settings. Cleared by the next ordinary play.
  String? _reciterOverride;
  String? get reciterOverride => _reciterOverride;

  Reciter get reciter => _content.reciters.byFolder(_reciterOverride ?? _settings.reciter);

  String urlFor(QueueItem item) => _content.reciters.url(reciter.folder, item.audioRef);

  AudioBackend _ensureBackend() {
    final b = _backend;
    if (b != null) return b;
    final nb = _factory();
    _completedSub = nb.completed.listen((_) => _onCompleted());
    _positionSub = nb.position.listen(_onPosition);
    return _backend = nb;
  }

  /// Plays from [from] to the end of [scope] (page, surah, or on to the end of
  /// the Quran, turning pages as it goes).
  Future<void> playFrom(AyahRef from, {PlayScope scope = PlayScope.toEnd, String? reciter}) {
    final q = _content.quran;
    _scope = scope;
    _reciterOverride = reciter;
    return _start(buildQueue(q, from, scopeEnd(q, from, scope), repeat: _settings.repeat));
  }

  Future<void> playPage(int page) => playFrom(_content.quran.page(page).start, scope: PlayScope.page);

  /// The reader's play button: from the top of [page] on through the following
  /// pages and surahs (owner, 2026-11-12: recitation must not stop at the page end).
  Future<void> playOnFrom(int page) => playFrom(_content.quran.page(page).start, scope: PlayScope.toEnd);

  Future<void> playSurah(int surah, {String? reciter}) =>
      playFrom(AyahRef(surah, 1), scope: PlayScope.surah, reciter: reciter);

  /// Plays the verse ranges of a Quranic story one after the other (with the
  /// basmala before an ayah 1, as everywhere).
  Future<void> playRanges(List<StoryRange> ranges) {
    final q = _content.quran;
    _scope = PlayScope.ranges;
    _reciterOverride = null;
    final queue = [for (final r in ranges) ...buildQueue(q, r.start, r.end, repeat: _settings.repeat)];
    if (queue.isEmpty) return Future.value();
    return _start(queue);
  }

  /// Quran radio: the whole Mushaf from surah [fromSurah], wrapping round.
  Future<void> playRadio(int fromSurah) {
    _scope = PlayScope.radio;
    _reciterOverride = null;
    return _start(radioQueue(_content.quran, fromSurah));
  }

  Future<void> _start(List<QueueItem> queue) async {
    _queue = queue;
    _index = 0;
    await _playCurrent();
  }

  /// [advancing]: the previous ayah just ended; the new file replaces it without
  /// stopping the player first, so the system keeps the app's audio (and its
  /// background service) alive between ayahs.
  Future<void> _playCurrent({bool advancing = false}) async {
    final gen = ++_generation;
    _interrupted = false;
    if (!advancing) AudioFocus.claim(this);
    final item = _queue[_index];
    if (reciter.isTimed) return _playTimed(gen, item, advancing: advancing);
    _loadedSrc = null;
    _segmentEndMs = null;
    _state = RecitationState.loading;
    notifyListeners();
    final b = _ensureBackend();
    try {
      if (!advancing) await b.stop();
      final local = await _localFile?.call(reciter.folder, item);
      if (gen != _generation) return;
      await b.load(local != null ? Uri.file(local).toString() : urlFor(item));
      if (gen != _generation) return;
      await b.setSpeed(_settings.audioSpeed);
      await b.play();
      if (gen != _generation) return;
      _state = RecitationState.playing;
    } catch (_) {
      if (gen != _generation) return;
      _state = RecitationState.error;
    }
    notifyListeners();
  }

  /// A reciter recorded per surah: plays the ayah's part of the surah file,
  /// going straight on (no seek, no gap) when it follows the previous one.
  Future<void> _playTimed(int gen, QueueItem item, {required bool advancing}) async {
    final r = reciter;
    final seg = _content.reciters.timings[r.folder]?.segment(item);
    if (seg == null) {
      // No basmala in this recording (or no timings): go on to the next item.
      if (!item.isBasmala) {
        _state = RecitationState.error;
        notifyListeners();
        return;
      }
      if (_index + 1 >= _queue.length) return stop();
      _index++;
      return _playCurrent(advancing: advancing);
    }
    final b = _ensureBackend();
    String? local;
    try {
      local = await _localFile?.call(r.folder, item);
    } catch (_) {
      local = null;
    }
    if (gen != _generation) return;
    final src = local != null ? Uri.file(local).toString() : _content.reciters.surahFileUrl(r, item.ref.surah);
    final flowsOn = advancing && _state == RecitationState.playing && _loadedSrc == src && _lastEndMs == seg.startMs;
    _segmentEndMs = seg.endMs;
    _lastEndMs = seg.endMs;
    if (flowsOn) {
      notifyListeners();
      return;
    }
    _state = RecitationState.loading;
    notifyListeners();
    try {
      _seeking = true;
      if (_loadedSrc != src) {
        _loadedSrc = null;
        await b.load(src);
        if (gen != _generation) return;
        _loadedSrc = src;
      } else {
        await b.pause();
      }
      await b.seek(Duration(milliseconds: seg.startMs));
      _seeking = false;
      if (gen != _generation) return;
      await b.setSpeed(_settings.audioSpeed);
      await b.play();
      if (gen != _generation) return;
      _state = RecitationState.playing;
    } catch (_) {
      if (gen != _generation) return;
      _loadedSrc = null;
      _state = RecitationState.error;
    } finally {
      _seeking = false;
    }
    notifyListeners();
  }

  void _onPosition(Duration p) {
    final end = _segmentEndMs;
    if (end == null || _seeking || _state != RecitationState.playing || !reciter.isTimed) return;
    if (p.inMilliseconds >= end - 20) {
      _segmentEndMs = null;
      _onCompleted();
    }
  }

  void _onCompleted() {
    if (_state != RecitationState.playing) return;
    if (_index + 1 >= _queue.length) {
      _finish();
      return;
    }
    _index++;
    unawaited(_playCurrent(advancing: true));
  }

  void _finish() {
    _generation++;
    _segmentEndMs = null;
    _lastEndMs = null;
    _state = RecitationState.idle;
    _queue = const [];
    _index = 0;
    notifyListeners();
  }

  /// Changes the playback speed now and for the next ayahs (kept in settings).
  Future<void> setSpeed(double speed) async {
    await _settings.setAudioSpeed(speed);
    await _backend?.setSpeed(_settings.audioSpeed);
    notifyListeners();
  }

  Future<void> pause() async {
    if (_state != RecitationState.playing) return;
    _state = RecitationState.paused;
    notifyListeners();
    await _backend?.pause();
  }

  /// Another sound started: pause and remember the ayah as the place to come back to.
  Future<void> interrupt() async {
    if (!isPlaying) return;
    final ref = current?.isBasmala == false ? current!.ref : null;
    if (_state == RecitationState.loading) {
      _generation++; // the file still loading must not start playing
    }
    _state = RecitationState.paused;
    _interrupted = true;
    notifyListeners();
    await _backend?.pause();
    if (ref != null) await _settings.setLastRead(ref);
  }

  Future<void> resume() async {
    _interrupted = false;
    if (_state == RecitationState.paused) {
      AudioFocus.claim(this);
      _state = RecitationState.playing;
      notifyListeners();
      await _backend?.play();
    } else if (_state == RecitationState.error) {
      await _playCurrent();
    }
  }

  /// Skips to the next ayah (past any remaining repeats of the current one).
  Future<void> next() async {
    if (_queue.isEmpty) return;
    final cur = _queue[_index].ref;
    var i = _index + 1;
    while (i < _queue.length && _queue[i].ref == cur && !_queue[i].isBasmala) {
      i++;
    }
    if (i >= _queue.length) return stop();
    _index = i;
    await _playCurrent();
  }

  /// Back to the start of the previous ayah in the queue.
  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final cur = _queue[_index].ref;
    var i = _index;
    while (i > 0 && _queue[i - 1].ref == cur) {
      i--;
    }
    if (i > 0) {
      final prev = _queue[i - 1].ref;
      i--;
      while (i > 0 && _queue[i - 1].ref == prev) {
        i--;
      }
    }
    _index = i;
    await _playCurrent();
  }

  Future<void> stop() async {
    _interrupted = false;
    _finish();
    _loadedSrc = null;
    await _backend?.stop();
  }

  @override
  void dispose() {
    AudioFocus.unregister(this);
    _generation++;
    unawaited(_completedSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_backend?.dispose());
    super.dispose();
  }
}

/// Long narrated episodes (streamed): needs seeking and progress on top of
/// [AudioBackend]. Implemented with just_audio in the app and a fake in tests.
abstract class NarrationBackend {
  Future<Duration?> load(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration to);
  Future<void> stop();
  Stream<Duration> get position;
  Stream<void> get completed;

  /// The length once the player knows it (streams often report it only after loading starts).
  Stream<Duration?> get durationChanges;
  Future<void> dispose();
}

class JustAudioNarrationBackend implements NarrationBackend {
  JustAudioNarrationBackend() {
    _sub = _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _completed.add(null);
    });
  }

  final _player = AudioPlayer();
  final _completed = StreamController<void>.broadcast();
  late final StreamSubscription<ProcessingState> _sub;

  @override
  Future<Duration?> load(String url) => _player.setUrl(url).timeout(const Duration(seconds: 30));

  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration to) => _player.seek(to);

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Stream<Duration?> get durationChanges => _player.durationStream;

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _completed.close();
    await _player.dispose();
  }
}

/// Plays one narrated episode at a time, resumes where the listener stopped
/// (saved every few seconds), and never plays together with the recitation.
class NarrationController extends ChangeNotifier {
  NarrationController({
    required SettingsController settings,
    required RecitationController recitation,
    required NarrationBackend Function() backendFactory,
    this.offlineFile,
  }) : _settings = settings,
       _recitation = recitation,
       _factory = backendFactory {
    _recitation.addListener(_onRecitation);
    AudioFocus.register(this, () => unawaited(pause()));
  }

  final SettingsController _settings;
  final RecitationController _recitation;
  final NarrationBackend Function() _factory;

  /// The saved copy of an episode (series, episode id), played instead of streaming.
  final Future<String?> Function(String seriesId, String episodeId)? offlineFile;
  NarrationBackend? _backend;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _doneSub;
  StreamSubscription<Duration?>? _durSub;

  String? _seriesId;
  Episode? _episode;
  RecitationState _state = RecitationState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;
  int _generation = 0;
  bool _remember = true;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  List<Episode> _playlist = const [];

  Episode? get episode => _episode;
  String? get seriesId => _seriesId;

  /// The list the episode was started from: when it ends the next one plays
  /// (the next surah of the recitation, the next lesson, ...). Empty for one-offs and live radio.
  List<Episode> get playlist => _playlist;

  int get _playlistIndex {
    final e = _episode;
    if (e == null) return -1;
    return _playlist.indexWhere((x) => x.id == e.id && x.url == e.url);
  }

  bool get hasNext {
    final i = _playlistIndex;
    return i >= 0 && i + 1 < _playlist.length;
  }

  bool get hasPrevious => _playlistIndex > 0;

  /// A live stream (radio): no position, no skipping.
  bool get isLive => _episode != null && _seriesId == 'radio';
  RecitationState get state => _state;
  Duration get position => _position;
  /// The full length: from the player, else the length listed for the episode (so the seek bar and
  /// the time show from the start, owner 2026-11-22).
  Duration? get duration {
    if (_duration != null && _duration! > Duration.zero) return _duration;
    final s = _episode?.durationSec;
    return s == null || s <= 0 ? null : Duration(seconds: s);
  }

  bool get isActive => _state != RecitationState.idle;
  bool get isPlaying => _state == RecitationState.playing || _state == RecitationState.loading;

  String _key(String series, Episode e) => '$series/${e.id}';

  NarrationBackend _ensure() {
    final b = _backend;
    if (b != null) return b;
    final nb = _factory();
    _posSub = nb.position.listen(_onPosition);
    _doneSub = nb.completed.listen((_) => _onDone());
    _durSub = nb.durationChanges.listen((d) {
      if (d == null || d <= Duration.zero || d == _duration || _episode == null) return;
      _duration = d;
      notifyListeners();
    });
    return _backend = nb;
  }

  void _onRecitation() {
    // One voice at a time: starting the recitation pauses the narrator.
    if (_recitation.isPlaying && isPlaying) unawaited(pause());
  }

  /// Plays [e]. [remember]: resume where the listener stopped (off for live radio streams).
  /// [playlist]: the list [e] belongs to; playback goes on to the following items.
  /// [fromStart]: ignore the saved position (going on to the next item).
  Future<void> playEpisode(
    String seriesId,
    Episode e, {
    bool remember = true,
    List<Episode>? playlist,
    bool fromStart = false,
  }) async {
    final gen = ++_generation;
    // One sound at a time: the recitation pauses (and later resumes from its ayah).
    AudioFocus.claim(this);
    _remember = remember;
    if (playlist != null) _playlist = List.unmodifiable(playlist);
    if (playlist == null && _seriesId != seriesId) _playlist = const [];
    _seriesId = seriesId;
    _episode = e;
    if (remember) unawaited(_settings.setLastEpisode(seriesId, e.id));
    _state = RecitationState.loading;
    _position = Duration.zero;
    _duration = null;
    notifyListeners();
    final b = _ensure();
    try {
      await b.stop();
      String? local;
      try {
        local = await offlineFile?.call(seriesId, e.id);
      } catch (_) {
        local = null;
      }
      _duration = await b.load(local != null ? Uri.file(local).toString() : e.url);
      if (gen != _generation) return;
      final resume = remember && !fromStart ? _settings.storyPosition(_key(seriesId, e)) : 0;
      if (resume > 5 && (_duration == null || resume < _duration!.inSeconds - 10)) {
        await b.seek(Duration(seconds: resume));
        _position = Duration(seconds: resume);
      }
      await b.play();
      if (gen != _generation) return;
      _state = RecitationState.playing;
    } catch (_) {
      if (gen != _generation) return;
      _state = RecitationState.error;
    }
    notifyListeners();
  }

  void _onPosition(Duration p) {
    if (_episode == null) return;
    _position = p;
    final now = DateTime.now();
    if (_remember && now.difference(_lastSave).inSeconds >= 5) {
      _lastSave = now;
      unawaited(_settings.setStoryPosition(_key(_seriesId!, _episode!), p.inSeconds));
    }
    notifyListeners();
  }

  void _onDone() {
    if (_episode == null || _state != RecitationState.playing) return;
    if (_remember) {
      unawaited(_settings.setStoryPosition(_key(_seriesId!, _episode!), 0));
      unawaited(_settings.setEpisodeDone(_key(_seriesId!, _episode!), true));
    }
    if (hasNext) {
      unawaited(next());
      return;
    }
    _state = RecitationState.paused;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> pause() async {
    if (!isPlaying) return;
    _state = RecitationState.paused;
    notifyListeners();
    await _backend?.pause();
    if (_remember && _episode != null) {
      await _settings.setStoryPosition(_key(_seriesId!, _episode!), _position.inSeconds);
    }
  }

  Future<void> resume() async {
    final e = _episode;
    if (e == null) return;
    if (_state == RecitationState.error) return playEpisode(_seriesId!, e, remember: _remember);
    if (_state != RecitationState.paused) return;
    AudioFocus.claim(this);
    _state = RecitationState.playing;
    notifyListeners();
    await _backend?.play();
  }

  /// The next item of the playlist (lock-screen "next" and automatic at the end).
  Future<void> next() async {
    if (!hasNext) return;
    final e = _playlist[_playlistIndex + 1];
    await playEpisode(_seriesId!, e, remember: _remember, fromStart: true);
  }

  /// The previous item of the playlist, or the start of this one.
  Future<void> previous() async {
    if (hasPrevious && _position.inSeconds < 5) {
      final e = _playlist[_playlistIndex - 1];
      await playEpisode(_seriesId!, e, remember: _remember, fromStart: true);
      return;
    }
    if (_episode == null || _backend == null || isLive) return;
    _position = Duration.zero;
    notifyListeners();
    await _backend!.seek(Duration.zero);
  }

  Future<void> seekBy(Duration d) async {
    if (_episode == null || _backend == null) return;
    var to = _position + d;
    if (to < Duration.zero) to = Duration.zero;
    final total = duration;
    if (total != null && to > total) to = total;
    _position = to;
    notifyListeners();
    await _backend!.seek(to);
  }

  Future<void> stop() async {
    _generation++;
    final e = _episode;
    if (_remember && e != null) await _settings.setStoryPosition(_key(_seriesId!, e), _position.inSeconds);
    _episode = null;
    _state = RecitationState.idle;
    notifyListeners();
    await _backend?.stop();
  }

  @override
  void dispose() {
    _generation++;
    AudioFocus.unregister(this);
    _recitation.removeListener(_onRecitation);
    unawaited(_posSub?.cancel());
    unawaited(_doneSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_backend?.dispose());
    super.dispose();
  }
}

/// "Stop the audio after N minutes" for listening before sleep: stops the
/// recitation and pauses the narrator when it fires.
class SleepTimerController extends ChangeNotifier {
  SleepTimerController({required this.onFire, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const choices = [15, 30, 45, 60];

  final Future<void> Function() onFire;
  final DateTime Function() _clock;
  Timer? _timer;
  DateTime? _endsAt;

  DateTime? get endsAt => _endsAt;
  bool get isOn => _endsAt != null;

  /// Whole minutes left (rounded up), null when off.
  int? get minutesLeft {
    final e = _endsAt;
    if (e == null) return null;
    final s = e.difference(_clock()).inSeconds;
    return s <= 0 ? 0 : (s / 60).ceil();
  }

  /// Starts (or replaces) the timer; null cancels it.
  void set(int? minutes) {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    if (minutes != null && minutes > 0) {
      _endsAt = _clock().add(Duration(minutes: minutes));
      _timer = Timer(Duration(minutes: minutes), () {
        _timer = null;
        _endsAt = null;
        notifyListeners();
        unawaited(onFire());
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
