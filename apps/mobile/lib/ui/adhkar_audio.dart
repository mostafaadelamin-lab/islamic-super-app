import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app_services.dart';
import '../domain/nasheeds.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'youtube_player.dart';

/// Sheikh Mishary Alafasy's morning and evening adhkar ship inside the app
/// (offline); the others play from his official channel.
const offlineAdhkarAudio = <AdhkarAudio, String>{
  AdhkarAudio.morning: 'assets/audio/adhkar_morning_alafasy.mp3',
  AdhkarAudio.evening: 'assets/audio/adhkar_evening_alafasy.mp3',
};

/// The player the sheet uses; replaced in widget tests.
abstract class AssetAudio {
  Future<Duration?> load(String asset);
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
  Future<Duration?> load(String asset) => _p.setAsset(asset);
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
  final asset = offlineAdhkarAudio[a];
  if (asset == null) {
    return showYouTubeSheet(context, videoId: adhkarAudioVideo[a]!, title: title, subtitle: l.adhkarAlafasy);
  }
  final s = context.services;
  if (s.recitation.isPlaying) s.recitation.pause();
  if (s.narration.isPlaying) s.narration.pause();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: _AssetPlayer(asset: asset, title: title, subtitle: l.adhkarAlafasy),
    ),
  );
}

class _AssetPlayer extends StatefulWidget {
  const _AssetPlayer({required this.asset, required this.title, required this.subtitle});
  final String asset;
  final String title;
  final String subtitle;

  @override
  State<_AssetPlayer> createState() => _AssetPlayerState();
}

class _AssetPlayerState extends State<_AssetPlayer> {
  late final AssetAudio _a = (debugAssetAudioFactory ?? JustAudioAsset.new)();
  Duration _total = Duration.zero;
  Duration _pos = Duration.zero;
  bool _playing = false;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_a.position.listen((p) => setState(() => _pos = p)))
      ..add(_a.playing.listen((p) => setState(() => _playing = p)));
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final d = await _a.load(widget.asset);
      if (!mounted) return;
      setState(() => _total = d ?? Duration.zero);
      await _a.play();
    } catch (e) {
      debugPrint('adhkar audio failed: $e');
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _a.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final max = _total.inMilliseconds.toDouble();
    return Padding(
      key: const Key('adhkarAudioSheet'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(widget.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
        ],
      ),
    );
  }
}
