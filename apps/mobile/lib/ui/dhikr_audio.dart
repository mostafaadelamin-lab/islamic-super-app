import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app_services.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// Per-dhikr recordings of Hisn al-Muslim (owner, 2026-11-11: "listen" plays only the
/// dhikr on screen; every dhikr can be listened to, online). Built by tools/adhkar_audio.py.
class DhikrAudioMap {
  DhikrAudioMap(this.base, this.adhkar, this.hisn);

  factory DhikrAudioMap.fromJson(Map<String, dynamic> j) => DhikrAudioMap(
    j['base'] as String,
    {for (final e in (j['adhkar'] as Map<String, dynamic>).entries) int.parse(e.key): e.value as int},
    {for (final e in (j['hisn'] as Map<String, dynamic>).entries) e.key: e.value as int},
  );

  static const asset = 'assets/content/adhkar-audio.v1.json';
  static DhikrAudioMap? _cached;

  /// Loaded once from the bundle; null while loading or when missing.
  static Future<DhikrAudioMap?> load(AssetBundle bundle) async {
    if (_cached != null) return _cached;
    try {
      _cached = DhikrAudioMap.fromJson(jsonDecode(await bundle.loadString(asset)) as Map<String, dynamic>);
    } catch (_) {}
    return _cached;
  }

  final String base;
  final Map<int, int> adhkar;
  final Map<String, int> hisn;

  String? _url(int? id) => id == null ? null : base.replaceAll('{id}', '$id');
  String? forDhikr(int index) => _url(adhkar[index]);
  String? forHisn(int chapter, int item) => _url(hisn['$chapter:$item']);
}

/// One shared player for dhikr recordings: starting one stops the previous.
abstract class UrlAudio {
  Future<void> play(String url);
  Future<void> stop();
  Stream<bool> get playing;
}

class JustAudioUrl implements UrlAudio {
  final _p = AudioPlayer();
  @override
  Future<void> play(String url) async {
    await _p.setUrl(url);
    unawaited(_p.play());
  }

  @override
  Future<void> stop() => _p.stop();
  @override
  Stream<bool> get playing =>
      _p.playerStateStream.map((s) => s.playing && s.processingState != ProcessingState.completed);
}

@visibleForTesting
UrlAudio Function()? debugUrlAudioFactory;

class DhikrPlayer extends ChangeNotifier {
  DhikrPlayer._();
  static final instance = DhikrPlayer._();

  UrlAudio? _audio;
  String? url;
  bool playing = false;
  bool loading = false;
  bool failed = false;

  UrlAudio get _a {
    if (_audio == null) {
      _audio = (debugUrlAudioFactory ?? JustAudioUrl.new)();
      _audio!.playing.listen((p) {
        playing = p;
        if (p) loading = false;
        notifyListeners();
      });
    }
    return _audio!;
  }

  Future<void> toggle(String u) async {
    if (url == u && (playing || loading)) {
      loading = false;
      await _a.stop();
      notifyListeners();
      return;
    }
    url = u;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      await _a.play(u);
    } catch (e) {
      debugPrint('dhikr audio failed: $e');
      loading = false;
      failed = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_audio == null) return;
    loading = false;
    await _a.stop();
    notifyListeners();
  }
}

/// "Listen to this dhikr" (streams the recording; needs internet).
class DhikrListenButton extends StatelessWidget {
  const DhikrListenButton({super.key, required this.url, this.compact = false});
  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = DhikrPlayer.instance;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final mine = p.url == url;
        final on = mine && (p.playing || p.loading);
        final label = mine && p.failed ? l.dhikrListenFailed : (on ? l.dhikrListenStop : l.dhikrListen);
        final icon = mine && p.loading
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : RIcon(on ? RIcons.stop : RIcons.headphones, size: 20);
        void onTap() {
          final s = context.services;
          if (s.recitation.isPlaying) s.recitation.pause();
          if (s.narration.isPlaying) s.narration.pause();
          p.toggle(url);
        }

        return compact
            ? TextButton.icon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label))
            : FilledButton.tonalIcon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label));
      },
    );
  }
}

/// Builds [builder] once the audio map is loaded (null url = no recording for this dhikr).
class DhikrAudioUrl extends StatelessWidget {
  const DhikrAudioUrl({super.key, required this.pick, required this.builder});
  final String? Function(DhikrAudioMap m) pick;
  final Widget Function(BuildContext context, String url) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<DhikrAudioMap?>(
    future: DhikrAudioMap.load(DefaultAssetBundle.of(context)),
    builder: (context, snap) {
      final m = snap.data;
      final u = m == null ? null : pick(m);
      return u == null ? const SizedBox.shrink() : builder(context, u);
    },
  );
}
