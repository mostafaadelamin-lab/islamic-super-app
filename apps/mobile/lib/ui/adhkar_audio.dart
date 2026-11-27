import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app_services.dart';
import '../data/adhkar_audio_files.dart';
import '../data/audio_focus.dart';
import '../data/media_session.dart';
import '../l10n/app_localizations.dart';
import '../domain/nasheeds.dart';
import '../theme/design_tokens.dart';
import 'background_audio.dart';
import 'dhikr_audio.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'youtube_player.dart';

/// Sheikh Mishary Alafasy's morning and evening adhkar are downloaded the first
/// time they are played and then play offline (AdhkarAudioFiles); the others
/// play from his official channel.
const offlineAdhkarAudio = <AdhkarAudio, String>{
  AdhkarAudio.morning: 'adhkar_morning_alafasy',
  AdhkarAudio.evening: 'adhkar_evening_alafasy',
};

/// The player the sheet uses; replaced in widget tests.
abstract class AssetAudio {
  /// [source]: a bundled asset ("assets/...") or a file on the phone.
  Future<Duration?> load(String source);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration d);
  Future<void> dispose();
  Stream<Duration> get position;
  Stream<bool> get playing;
}

class JustAudioAsset implements AssetAudio {
  final _p = AudioPlayer();
  @override
  Future<Duration?> load(String source) => source.startsWith('assets/') ? _p.setAsset(source) : _p.setFilePath(source);
  @override
  Future<void> play() async => unawaited(_p.play());
  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> seek(Duration d) => _p.seek(d);
  @override
  Future<void> dispose() => _p.dispose();
  @override
  Stream<Duration> get position => _p.positionStream;
  @override
  Stream<bool> get playing =>
      _p.playerStateStream.map((s) => s.playing && s.processingState != ProcessingState.completed);
}

@visibleForTesting
AssetAudio Function()? debugAssetAudioFactory;

/// Opens the right player: offline for morning/evening, YouTube otherwise.
Future<void> openAdhkarAudio(BuildContext context, AdhkarAudio a, String title) {
  final l = context.l10n;
  final file = offlineAdhkarAudio[a];
  if (file == null) {
    return showYouTubeSheet(context, videoId: adhkarAudioVideo[a]!, title: title, subtitle: l.adhkarAlafasy);
  }
  final s = context.services;
  if (s.recitation.isPlaying) s.recitation.pause();
  if (s.narration.isPlaying) s.narration.pause();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: AdhkarAudioPlayer(
        files: s.adhkarAudio,
        file: file,
        videoId: adhkarAudioVideo[a],
        title: title,
        subtitle: l.adhkarAlafasy,
      ),
    ),
  );
}

/// The player of one whole Alafasy recording: downloads it the first time, then plays from the phone.
/// Shown inside the adhkar page itself (owner 2026-11-27), with ✕ ([onClose]).
class AdhkarAudioPlayer extends StatefulWidget {
  const AdhkarAudioPlayer({
    super.key,
    required this.files,
    required this.file,
    this.videoId,
    required this.title,
    required this.subtitle,
    this.onClose,
  });

  /// ✕: stops and hides the player (inside a page). Null in a bottom sheet.
  final VoidCallback? onClose;

  final AdhkarAudioFiles files;

  /// Name of the recording (AdhkarAudioFiles).
  final String file;

  /// The same recording on the official channel, offered when the download fails.
  final String? videoId;
  final String title;
  final String subtitle;

  @override
  State<AdhkarAudioPlayer> createState() => _AssetPlayerState();
}

class _AssetPlayerState extends State<AdhkarAudioPlayer> {
  late final AssetAudio _a = (debugAssetAudioFactory ?? JustAudioAsset.new)();
  Duration _total = Duration.zero;
  Duration _pos = Duration.zero;
  bool _playing = false;
  final _subs = <StreamSubscription<Object?>>[];

  /// Lock screen / notification entry, so the recording goes on in the background.
  late final SimpleMediaSource _media = SimpleMediaSource(
    id: 'adhkar/${widget.file}',
    title: widget.title,
    artist: widget.subtitle,
    onAction: (a) {
      if (a == 'play') _a.play();
      if (a == 'pause' || a == 'stop') _a.pause();
    },
  );

  @override
  void initState() {
    super.initState();
    // One sound at a time: this recording pauses the recitation, and the other way round.
    AudioFocus.register(this, () {
      if (_playing) unawaited(_a.pause());
    });
    _subs
      ..add(_a.position.listen((p) => setState(() => _pos = p)))
      ..add(
        _a.playing.listen((p) {
          if (p) AudioFocus.claim(this);
          setState(() => _playing = p);
          _media.playing = p;
        }),
      );
    unawaited(_start());
  }

  RecitationMediaBridge? _bridge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = context.services.media;
    if (b == _bridge) return;
    _bridge?.detach(_media);
    _bridge = b?..attach(_media);
  }

  /// null: looking for the file; true: downloading it; false: ready (or failed, see [_failed]).
  bool? _downloading;
  bool _failed = false;

  Future<void> _start() async {
    final files = widget.files;
    if (_failed) {
      setState(() {
        _failed = false;
        _downloading = null;
      });
    }
    try {
      var path = await files.local(widget.file);
      if (path == null) {
        if (!mounted) return;
        setState(() => _downloading = true);
        path = await files.fetch(widget.file);
      }
      if (!mounted) return;
      if (path == null) {
        setState(() {
          _downloading = false;
          _failed = true;
        });
        return;
      }
      setState(() => _downloading = false);
      final d = await _a.load(path);
      if (!mounted) return;
      setState(() => _total = d ?? Duration.zero);
      await _a.play();
    } catch (e) {
      debugPrint('adhkar audio failed: $e');
      if (mounted) {
        setState(() {
          _downloading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    AudioFocus.unregister(this);
    for (final s in _subs) {
      s.cancel();
    }
    _media.loaded = false;
    _bridge?.detach(_media);
    _media.dispose();
    _a.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      key: const Key('adhkarAudioSheet'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (widget.onClose case final close?)
                IconButton(
                  key: const Key('adhkarAudioClose'),
                  tooltip: l.adhkarListenClose,
                  icon: const RIcon(RIcons.close),
                  onPressed: close,
                ),
            ],
          ),
          if (_downloading ?? true) ...[
            const SizedBox(height: DesignTokens.spaceLg),
            const Center(child: CircularProgressIndicator(key: Key('adhkarAudioLoading'))),
            const SizedBox(height: DesignTokens.spaceSm),
            if (_downloading == true) Text(l.adhkarAudioDownloading, textAlign: TextAlign.center),
          ] else if (_failed) ...[
            const SizedBox(height: DesignTokens.spaceLg),
            Text(l.adhkarAudioDownloadFailed, key: const Key('adhkarAudioFailed'), textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.spaceSm),
            FilledButton(key: const Key('adhkarAudioRetry'), onPressed: _start, child: Text(l.commonRetry)),
            if (widget.videoId case final id?)
              TextButton(
                key: const Key('adhkarAudioYouTube'),
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (widget.onClose case final close?) {
                    close();
                  } else {
                    nav.pop();
                  }
                  showYouTubeSheet(nav.context, videoId: id, title: widget.title, subtitle: widget.subtitle);
                },
                child: Text(l.adhkarAudioWatchOnline),
              ),
          ] else
            ..._player(l, theme),
        ],
      ),
    );
  }

  List<Widget> _player(AppLocalizations l, ThemeData theme) {
    final max = _total.inMilliseconds.toDouble();
    return [
      Slider(
        key: const Key('adhkarAudioSeek'),
        value: max <= 0 ? 0 : _pos.inMilliseconds.clamp(0, max).toDouble(),
        max: max <= 0 ? 1 : max,
        onChanged: max <= 0 ? null : (v) => _a.seek(Duration(milliseconds: v.round())),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fmt(_pos)), Text(_fmt(_total))]),
      Center(
        child: IconButton.filled(
          key: const Key('adhkarAudioPlay'),
          iconSize: 36,
          tooltip: _playing ? l.audioPause : l.audioPlay,
          icon: RIcon(_playing ? RIcons.pause : RIcons.play, color: theme.colorScheme.onPrimary),
          onPressed: () => _playing ? _a.pause() : _a.play(),
        ),
      ),
      const SizedBox(height: DesignTokens.spaceXs),
      Text(l.adhkarOfflineNote, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
    ];
  }
}

/// «استمع للأذكار كاملة» at the top of the morning / evening adhkar page: the whole Alafasy recording plays
/// right here, in the page (owner 2026-11-27), not in a separate sheet.
class AlafasyListenCard extends StatefulWidget {
  const AlafasyListenCard({super.key, required this.audio, required this.title, this.autoStart = false});
  final AdhkarAudio audio;
  final String title;
  final bool autoStart;

  @override
  State<AlafasyListenCard> createState() => _AlafasyListenCardState();
}

class _AlafasyListenCardState extends State<AlafasyListenCard> with AutomaticKeepAliveClientMixin {
  late bool _open = widget.autoStart;

  // The recording goes on while the reader scrolls the list away from it.
  @override
  bool get wantKeepAlive => _open;

  void _set(bool v) {
    setState(() => _open = v);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final file = offlineAdhkarAudio[widget.audio];
    if (file == null) return const SizedBox.shrink();
    final l = context.l10n;
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: Key('alafasyCard-${widget.audio.name}'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
      child: _open
          ? Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
              child: AdhkarAudioPlayer(
                files: s.adhkarAudio,
                file: file,
                videoId: adhkarAudioVideo[widget.audio],
                title: widget.title,
                subtitle: l.adhkarListenAllSub,
                onClose: () => _set(false),
              ),
            )
          : ListTile(
              key: const Key('alafasyListen'),
              leading: RIcon(RIcons.headphones, color: scheme.primary, size: 28),
              title: Text(l.adhkarListenAll, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: FutureBuilder<String?>(
                future: s.adhkarAudio.local(file),
                builder: (context, snap) => Text(
                  snap.data == null ? l.adhkarListenAllSub : '${l.adhkarListenAllSub} · ✓ ${l.adhkarListenSaved}',
                ),
              ),
              trailing: RIcon(RIcons.playCircle, color: scheme.primary),
              onTap: () {
                if (s.recitation.isPlaying) s.recitation.pause();
                if (s.narration.isPlaying) s.narration.pause();
                unawaited(DhikrPlayer.instance.stop());
                _set(true);
              },
            ),
    );
  }
}
