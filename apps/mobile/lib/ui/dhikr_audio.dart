import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app_services.dart';
import '../data/audio_focus.dart';
import '../data/dhikr_clips.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'lock_player.dart';
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
    // A recording saved on the phone plays from its file, without internet.
    url.startsWith('/') ? await _p.setFilePath(url) : await _p.setUrl(url);
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

/// A fresh URL player (the test double when one is set).
UrlAudio newUrlAudio() => (debugUrlAudioFactory ?? JustAudioUrl.new)();

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

  /// What is playing, shown on the player (null: the item is right above it).
  String? title;
  String? subtitle;
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

  /// [source]: the saved file of [u] when it is on the phone (played instead of streaming).
  Future<void> toggle(String u, {String? title, String? subtitle, String? source}) async {
    if (url == u && (playing || loading)) {
      await stop();
      return;
    }
    AudioFocus.claim(this); // pauses the recitation, which resumes later from its ayah
    url = u;
    this.title = title;
    this.subtitle = subtitle;
    loading = true;
    failed = false;
    position = Duration.zero;
    duration = null;
    notifyListeners();
    try {
      await _a.play(source ?? u);
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

/// The dhikr recording's player, in the same lock-screen look as every player (owner 2026-11-22):
/// title, seek bar with the time gone / full length, ±30 s, play/pause and ✕.
/// [inline]: right under the item playing (adhkar, Hisn al-Muslim, the names of Allah);
/// otherwise a bar at the bottom of the screen.
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
        return LockPlayerCard(
          key: const Key('dhikrPlayerBar'),
          id: 'dhikrPlayer',
          docked: !inline,
          title: p.title,
          subtitle: p.subtitle,
          position: p.position,
          total: p.duration,
          playing: p.playing,
          loading: p.loading,
          onToggle: () => p.playing ? p.pause() : p.resume(),
          onSeek: p.seek,
          onClose: p.stop,
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
          p.toggle(url, source: s.dhikrClips.localPath(url));
        }

        final listen = compact
            ? TextButton.icon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label))
            : FilledButton.tonalIcon(key: const Key('dhikrListen'), onPressed: onTap, icon: icon, label: Text(label));
        // «⬇» beside it keeps this recording for listening without internet (owner 2026-11-27).
        final button = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            listen,
            const SizedBox(width: 4),
            DhikrSaveButton(url: url),
          ],
        );
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

/// «⬇» / «✓ محفوظ» for one dhikr recording: saves it for listening without internet, or deletes the copy.
class DhikrSaveButton extends StatefulWidget {
  const DhikrSaveButton({super.key, required this.url});
  final String url;

  @override
  State<DhikrSaveButton> createState() => _DhikrSaveButtonState();
}

class _DhikrSaveButtonState extends State<DhikrSaveButton> {
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(context.services.dhikrClips.ready());
  }

  @override
  Widget build(BuildContext context) {
    final clips = context.services.dhikrClips;
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: clips,
      builder: (context, _) {
        final id = DhikrClips.idOf(widget.url) ?? '';
        if (clips.busy.contains(widget.url)) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (clips.isSaved(widget.url)) {
          return TextButton.icon(
            key: Key('dhikrSaved-$id'),
            style: TextButton.styleFrom(foregroundColor: scheme.tertiary),
            onPressed: () => clips.delete(widget.url),
            icon: const RIcon(RIcons.checkCircle, size: 18),
            label: Text(l.dhikrSaved),
          );
        }
        return IconButton.outlined(
          key: Key('dhikrSave-$id'),
          tooltip: _failed ? l.dhikrDownloadFailed : l.dhikrDownload,
          icon: RIcon(_failed ? RIcons.refresh : RIcons.download, size: 20),
          onPressed: () async {
            final ok = await clips.download(widget.url);
            if (mounted) setState(() => _failed = !ok);
          },
        );
      },
    );
  }
}

/// «استماع بدون إنترنت · حمّل الكل» at the top of a page of adhkar that can be heard: downloads every
/// recording of the page at once, with the progress, cancel, and delete once all are saved.
class DhikrOfflineCard extends StatefulWidget {
  const DhikrOfflineCard({super.key, required this.group, required this.urls});

  /// Which page (one "download all" runs at a time; its progress shows on its own page).
  final String group;
  final List<String> urls;

  @override
  State<DhikrOfflineCard> createState() => _DhikrOfflineCardState();
}

class _DhikrOfflineCardState extends State<DhikrOfflineCard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(context.services.dhikrClips.ready());
  }

  @override
  Widget build(BuildContext context) {
    final clips = context.services.dhikrClips;
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urls = widget.urls.toSet().toList();
    if (urls.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: clips,
      builder: (context, _) {
        final saved = clips.savedCount(urls);
        final all = saved == urls.length;
        final running = clips.batch == widget.group;
        final Widget body;
        if (running) {
          final total = clips.batchTotal == 0 ? 1 : clips.batchTotal;
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.dhikrOfflineProgress(context.num('${clips.batchDone}'), context.num('${clips.batchTotal}')),
                      key: const Key('dhikrOfflineProgress'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    key: const Key('dhikrOfflineCancel'),
                    onPressed: clips.cancel,
                    child: Text(l.dhikrOfflineCancel),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                child: LinearProgressIndicator(value: clips.batchDone / total, minHeight: 8),
              ),
            ],
          );
        } else if (all) {
          body = Row(
            children: [
              RIcon(RIcons.checkCircle, color: scheme.tertiary),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Text(l.dhikrOfflineDone, key: const Key('dhikrOfflineDone'), style: theme.textTheme.titleSmall),
              ),
              TextButton(
                key: const Key('dhikrOfflineDelete'),
                onPressed: () => clips.deleteAll(urls),
                child: Text(l.dhikrOfflineDelete),
              ),
            ],
          );
        } else {
          body = Row(
            children: [
              const RIcon(RIcons.headphones),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.dhikrOfflineTitle, style: theme.textTheme.titleSmall),
                    Text(
                      clips.batchFailed == widget.group
                          ? l.dhikrOfflineRetry
                          : l.dhikrOfflineCount(context.num('${urls.length}')),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: const Key('dhikrOfflineAll'),
                onPressed: clips.batch != null ? null : () => clips.downloadAll(widget.group, urls),
                icon: const RIcon(RIcons.download, size: 18),
                label: Text(l.dhikrOfflineAll),
              ),
            ],
          );
        }
        return Card(
          key: Key('dhikrOffline-${widget.group}'),
          margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            side: BorderSide(color: scheme.secondary, width: 1.5),
          ),
          child: Padding(padding: const EdgeInsets.all(DesignTokens.spaceMd), child: body),
        );
      },
    );
  }
}

/// [DhikrOfflineCard] for the recordings [pick] finds in the audio map (nothing when there are none).
class DhikrOfflineFor extends StatelessWidget {
  const DhikrOfflineFor({super.key, required this.group, required this.pick});
  final String group;
  final Iterable<String?> Function(DhikrAudioMap m) pick;

  @override
  Widget build(BuildContext context) => FutureBuilder<DhikrAudioMap?>(
    future: DhikrAudioMap.load(DefaultAssetBundle.of(context)),
    builder: (context, snap) {
      final m = snap.data;
      final urls = m == null ? const <String>[] : pick(m).whereType<String>().toList();
      return urls.isEmpty ? const SizedBox.shrink() : DhikrOfflineCard(group: group, urls: urls);
    },
  );
}
