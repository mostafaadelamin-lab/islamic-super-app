import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app_services.dart';
import '../data/audio_focus.dart';
import '../theme/design_tokens.dart';
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
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration d);
  Future<void> stop();
  Stream<bool> get playing;
  Stream<bool> get completed;
  Stream<Duration> get position;
  Stream<Duration?> get duration;
}

class JustAudioUrl implements UrlAudio {
  final _p = AudioPlayer();
  @override
  Future<void> play(String url) async {
    await _p.setUrl(url);
    unawaited(_p.play());
  }

  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> resume() async => unawaited(_p.play());
  @override
  Future<void> seek(Duration d) => _p.seek(d);
  @override
  Future<void> stop() => _p.stop();
  @override
  Stream<bool> get playing =>
      _p.playerStateStream.map((s) => s.playing && s.processingState != ProcessingState.completed);
  @override
  Stream<bool> get completed => _p.processingStateStream.map((s) => s == ProcessingState.completed);
  @override
  Stream<Duration> get position => _p.positionStream;
  @override
  Stream<Duration?> get duration => _p.durationStream;
}

@visibleForTesting
UrlAudio Function()? debugUrlAudioFactory;

/// The dhikr recording now loaded: plays once to the end (never loops), can be
/// paused, resumed, sought and stopped from [DhikrPlayerBar].
class DhikrPlayer extends ChangeNotifier {
  DhikrPlayer._() {
    // One sound at a time: the recitation or a nasheed starting pauses the dhikr.
    AudioFocus.register(this, () {
      if (playing || loading) unawaited(pause());
    });
  }
  static final instance = DhikrPlayer._();

  UrlAudio? _audio;
  String? url;
  bool playing = false;
  bool loading = false;
  bool failed = false;
  Duration position = Duration.zero;
  Duration? duration;

  /// A recording is loaded (playing or paused): the bar is shown.
  bool get active => url != null && !failed;

  UrlAudio get _a {
    if (_audio == null) {
      _audio = (debugUrlAudioFactory ?? JustAudioUrl.new)();
      _audio!.playing.listen((p) {
        playing = p;
        if (p) loading = false;
        notifyListeners();
      });
      _audio!.completed.listen((done) {
        if (done) unawaited(stop());
      });
      _audio!.position.listen((p) {
        position = p;
        notifyListeners();
      });
      _audio!.duration.listen((d) {
        duration = d;
        notifyListeners();
      });
    }
    return _audio!;
  }

  Future<void> toggle(String u) async {
    if (url == u && (playing || loading)) {
      await stop();
      return;
    }
    AudioFocus.claim(this); // pauses the recitation, which resumes later from its ayah
    url = u;
    loading = true;
    failed = false;
    position = Duration.zero;
    duration = null;
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

  Future<void> pause() async {
    if (_audio == null) return;
    await _a.pause();
  }

  Future<void> resume() async {
    if (_audio == null || url == null) return;
    AudioFocus.claim(this);
    await _a.resume();
  }

  Future<void> seek(Duration d) async {
    if (_audio == null) return;
    await _a.seek(d);
  }

  /// Stops and unloads; the bar disappears.
  Future<void> stop() async {
    final had = url != null;
    url = null;
    loading = false;
    playing = false;
    position = Duration.zero;
    duration = null;
    if (_audio != null) await _a.stop();
    if (had) notifyListeners();
  }
}

/// Play/pause, progress and ✕ (stop and close) for the dhikr recording (shown while one is loaded).
/// [inline]: drawn as a rounded strip right under the dhikr playing (adhkar, Hisn al-Muslim; owner
/// 2026-11-17) instead of a bar at the bottom of the screen.
class DhikrPlayerBar extends StatelessWidget {
  const DhikrPlayerBar({super.key, this.inline = false});
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final p = DhikrPlayer.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        if (!p.active) return const SizedBox.shrink();
        final l = context.l10n;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final total = p.duration;
        String fmt(Duration d) => context.numLtr('${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}');
        final row = Row(
          children: [
            IconButton.filled(
              key: const Key('dhikrPlayerToggle'),
              tooltip: p.playing ? l.storiesPause : l.storiesPlay,
              icon: p.loading && !p.playing
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : RIcon(p.playing ? RIcons.pause : RIcons.play),
              onPressed: () => p.playing ? p.pause() : p.resume(),
            ),
            Text(fmt(p.position), style: theme.textTheme.bodySmall),
            Expanded(
              child: Slider(
                key: const Key('dhikrPlayerSlider'),
                value: total == null || total.inMilliseconds == 0
                    ? 0
                    : p.position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                max: total == null || total.inMilliseconds == 0 ? 1 : total.inMilliseconds.toDouble(),
                onChanged: total == null ? null : (v) => p.seek(Duration(milliseconds: v.round())),
              ),
            ),
            if (total != null) Text(fmt(total), style: theme.textTheme.bodySmall),
            IconButton(
              key: const Key('dhikrPlayerStop'),
              tooltip: l.storiesStop,
              icon: const RIcon(RIcons.close),
              onPressed: p.stop,
            ),
          ],
        );
        if (inline) {
          return Container(
            key: const Key('dhikrPlayerBar'),
            margin: const EdgeInsets.only(top: DesignTokens.spaceSm),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
            ),
            child: row,
          );
        }
        return Material(
          key: const Key('dhikrPlayerBar'),
          color: scheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outline)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: row,
            ),
          ),
        );
      },
    );
  }
}

/// "Listen to this dhikr" (streams the recording; needs internet).
class DhikrListenButton extends StatelessWidget {
  const DhikrListenButton({super.key, required this.url, this.compact = false, this.inlinePlayer = true});
  final String url;
  final bool compact;

  /// Show the player under this button while its recording is loaded.
  final bool inlinePlayer;

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

        final button = compact
            ? TextButton.icon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label))
            : FilledButton.tonalIcon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label));
        // The player shows right here, under the dhikr being heard; the page stays as it is.
        if (!inlinePlayer || !mine || !p.active) return button;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: button),
            const DhikrPlayerBar(inline: true),
          ],
        );
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

/// Stops the dhikr recording when the screen holding [child] closes.
class StopDhikrAudioOnExit extends StatefulWidget {
  const StopDhikrAudioOnExit({super.key, required this.child});
  final Widget child;

  @override
  State<StopDhikrAudioOnExit> createState() => _StopDhikrAudioOnExitState();
}

class _StopDhikrAudioOnExitState extends State<StopDhikrAudioOnExit> {
  @override
  void dispose() {
    unawaited(DhikrPlayer.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
