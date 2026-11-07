import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/audio_queue.dart';
import '../domain/quran.dart';
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

  /// Fires each time the loaded file has played to its end.
  Stream<void> get completed;
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
  Stream<void> get completed => _completed.stream;

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
  }) : _content = content,
       _settings = settings,
       _factory = backendFactory;

  final AppContent _content;
  final SettingsController _settings;
  final AudioBackend Function() _factory;
  AudioBackend? _backend;
  StreamSubscription<void>? _completedSub;

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

  QueueItem? get current => _state == RecitationState.idle || _queue.isEmpty ? null : _queue[_index];

  /// The ayah being recited (for highlighting), null when idle.
  AyahRef? get currentRef => current?.ref;

  /// The Mushaf page of the ayah being recited, null when idle.
  int? get currentPage {
    final c = current;
    return c == null ? null : pageForItem(_content.quran, c);
  }

  Reciter get reciter => _content.reciters.byFolder(_settings.reciter);

  String urlFor(QueueItem item) => _content.reciters.url(reciter.folder, item.audioRef);

  AudioBackend _ensureBackend() {
    final b = _backend;
    if (b != null) return b;
    final nb = _factory();
    _completedSub = nb.completed.listen((_) => _onCompleted());
    return _backend = nb;
  }

  /// Plays from [from] to the end of [scope] (page, surah, or on to the end of
  /// the Quran, turning pages as it goes).
  Future<void> playFrom(AyahRef from, {PlayScope scope = PlayScope.toEnd}) {
    final q = _content.quran;
    _scope = scope;
    return _start(buildQueue(q, from, scopeEnd(q, from, scope), repeat: _settings.repeat));
  }

  Future<void> playPage(int page) => playFrom(_content.quran.page(page).start, scope: PlayScope.page);

  Future<void> playSurah(int surah) => playFrom(AyahRef(surah, 1), scope: PlayScope.surah);

  Future<void> _start(List<QueueItem> queue) async {
    _queue = queue;
    _index = 0;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final gen = ++_generation;
    final item = _queue[_index];
    _state = RecitationState.loading;
    notifyListeners();
    final b = _ensureBackend();
    try {
      await b.stop();
      await b.load(urlFor(item));
      if (gen != _generation) return;
      await b.play();
      if (gen != _generation) return;
      _state = RecitationState.playing;
    } catch (_) {
      if (gen != _generation) return;
      _state = RecitationState.error;
    }
    notifyListeners();
  }

  void _onCompleted() {
    if (_state != RecitationState.playing) return;
    if (_index + 1 >= _queue.length) {
      _finish();
      return;
    }
    _index++;
    unawaited(_playCurrent());
  }

  void _finish() {
    _generation++;
    _state = RecitationState.idle;
    _queue = const [];
    _index = 0;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_state != RecitationState.playing) return;
    _state = RecitationState.paused;
    notifyListeners();
    await _backend?.pause();
  }

  Future<void> resume() async {
    if (_state == RecitationState.paused) {
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
    _finish();
    await _backend?.stop();
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_completedSub?.cancel());
    unawaited(_backend?.dispose());
    super.dispose();
  }
}
