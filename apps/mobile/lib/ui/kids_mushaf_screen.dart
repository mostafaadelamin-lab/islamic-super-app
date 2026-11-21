import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_services.dart';
import '../data/audio_focus.dart';
import '../domain/quran.dart';
import '../domain/teacher_timings.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'dhikr_audio.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// The timings of one surah; decoded here (not in an isolate) so it also loads in widget tests.
Future<TeacherTimings> loadTeacherTimings(int surah) async {
  final data = await rootBundle.load(TeacherTimings.assetFor(surah));
  return TeacherTimings.parse(utf8.decode(data.buffer.asUint8List()));
}

const _starsKey = 'kidsTeacherStars';

/// Stars a child earned per surah (one per full listen), kept on this device only.
Future<Map<String, int>> readTeacherStars() async {
  try {
    final p = await SharedPreferences.getInstance();
    final m = jsonDecode(p.getString(_starsKey) ?? '{}') as Map<String, dynamic>;
    return {for (final e in m.entries) e.key: (e.value as num).toInt()};
  } catch (_) {
    return {};
  }
}

Future<int> addTeacherStar(int surah) async {
  final all = await readTeacherStars();
  final n = (all['$surah'] ?? 0) + 1;
  all['$surah'] = n;
  final p = await SharedPreferences.getInstance();
  await p.setString(_starsKey, jsonEncode(all));
  return n;
}

const _sizes = [26.0, 32.0, 40.0, 50.0];
const _repeats = 3;

/// «المصحف المعلّم» as a real Mushaf for children (owner 2026-11-20): big Mushaf text, the word the
/// sheikh is reading lights up, a tapped word is said on its own, a tapped ayah number plays that ayah
/// (three times with «كرّر»), and a full listen earns a star. Text = KFGQPC v18 exactly.
class KidsMushafScreen extends StatefulWidget {
  const KidsMushafScreen({super.key, required this.surah, required this.reciters, this.initialReciter, this.loader});
  final int surah;
  final List<String> reciters;
  final String? initialReciter;

  /// Defaults to the surah's bundled timings file.
  final Future<TeacherTimings> Function()? loader;

  @override
  State<KidsMushafScreen> createState() => _KidsMushafScreenState();
}

class _KidsMushafScreenState extends State<KidsMushafScreen> {
  late String _reciter = widget.initialReciter ?? widget.reciters.first;
  TeacherTimings? _t;
  int _size = 1;
  bool _repeat = false;
  bool _playing = false;
  bool _cheer = false;
  int _stars = 0;
  ({int ayah, int? word})? _pos;
  String? _tapped; // "ayah:token" of the word being said
  (int, int)? _only; // one ayah only: (ayah index, plays left)
  String? _loadedUrl;
  UrlAudio? _rec;
  UrlAudio? _word;
  final _subs = <StreamSubscription<Object?>>[];
  final _taps = <String, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    AudioFocus.register(this, () => unawaited(_pauseAll()));
    unawaited(_init());
  }

  Future<void> _init() async {
    final t = await (widget.loader ?? () => loadTeacherTimings(widget.surah))();
    final stars = await readTeacherStars();
    if (!mounted) return;
    setState(() {
      _t = t;
      if (t.reciters[_reciter]?.surahs[widget.surah] == null) _reciter = _available(t).first;
      _stars = stars['${widget.surah}'] ?? 0;
    });
  }

  /// The reciters with timings for this surah (Minshawi has none for al-Ahzab).
  List<String> _available(TeacherTimings t) => [
    for (final f in widget.reciters)
      if (t.reciters[f]?.surahs[widget.surah] != null) f,
  ];

  TeacherRecording get _recording => _t!.reciters[_reciter]!;
  List<TeacherAyah> get _ayahs => _recording.surahs[widget.surah]!;

  UrlAudio get _r {
    if (_rec == null) {
      final a = newUrlAudio();
      _rec = a;
      _subs
        ..add(a.playing.listen((p) => mounted ? setState(() => _playing = p) : null))
        ..add(a.position.listen(_onPosition))
        ..add(a.completed.listen((done) => done ? _onEnded() : null));
    }
    return _rec!;
  }

  UrlAudio get _w {
    if (_word == null) {
      final a = newUrlAudio();
      _word = a;
      _subs.add(a.completed.listen((done) => done && mounted ? setState(() => _tapped = null) : null));
    }
    return _word!;
  }

  void _onPosition(Duration d) {
    if (!mounted || _t == null || _loadedUrl == null) return;
    final ms = d.inMilliseconds;
    final o = _only;
    if (o != null) {
      final a = _ayahs[o.$1];
      if (ms >= a.end) {
        if (o.$2 > 1) {
          _only = (o.$1, o.$2 - 1);
          unawaited(_r.seek(Duration(milliseconds: a.start)));
        } else {
          _only = null;
          unawaited(_r.pause());
          setState(() => _pos = null);
        }
        return;
      }
    }
    final p = _recording.at(widget.surah, ms);
    if (p != _pos) setState(() => _pos = p);
  }

  Future<void> _onEnded() async {
    if (!mounted) return;
    final wasWhole = _only == null && _pos != null;
    setState(() {
      _pos = null;
      _only = null;
      _playing = false;
    });
    await _r.stop();
    _loadedUrl = null;
    if (wasWhole) {
      final n = await addTeacherStar(widget.surah);
      if (mounted) {
        setState(() {
          _stars = n;
          _cheer = true;
        });
      }
    }
  }

  Future<void> _pauseAll() async {
    if (_rec != null) await _r.pause();
    if (_word != null) await _w.stop();
  }

  Future<void> _start(int ayah, {required bool only}) async {
    final s = context.services;
    AudioFocus.claim(this);
    unawaited(s.recitation.stop());
    if (_word != null) unawaited(_w.stop());
    setState(() {
      _tapped = null;
      _cheer = false;
      _only = only ? (ayah, _repeat ? _repeats : 1) : null;
    });
    final url = _recording.url(widget.surah);
    if (_loadedUrl != url) {
      _loadedUrl = url;
      await _r.play(url);
    } else {
      await _r.resume();
    }
    await _r.seek(Duration(milliseconds: _ayahs[ayah].start));
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _r.pause();
    } else if (_pos != null && _loadedUrl != null) {
      AudioFocus.claim(this);
      await _r.resume();
    } else {
      await _start(0, only: false);
    }
  }

  void _step(int d) {
    final cur = _pos?.ayah ?? -1;
    unawaited(_start((cur + d).clamp(0, _ayahs.length - 1), only: false));
  }

  Future<void> _sayWord(int a, int k, List<String> words) async {
    final w = quranComWord(words, k);
    if (w == null) return;
    AudioFocus.claim(this);
    unawaited(context.services.recitation.stop());
    if (_rec != null) await _r.pause();
    setState(() {
      _only = null;
      _pos = null;
      _tapped = '$a:$k';
    });
    try {
      await _w.play(_t!.wordAudio(widget.surah, a + 1, w));
    } catch (_) {
      if (mounted) setState(() => _tapped = null);
    }
  }

  Future<void> _pickReciter(String r) async {
    if (_rec != null) await _r.stop();
    _loadedUrl = null;
    setState(() {
      _reciter = r;
      _pos = null;
      _only = null;
    });
  }

  TapGestureRecognizer _tap(String key, VoidCallback onTap) =>
      _taps.putIfAbsent(key, TapGestureRecognizer.new)..onTap = onTap;

  @override
  void dispose() {
    AudioFocus.unregister(this);
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    for (final r in _taps.values) {
      r.dispose();
    }
    unawaited(_rec?.stop());
    unawaited(_word?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final theme = Theme.of(context);
    final q = s.content.quran;
    final dark = theme.brightness == Brightness.dark;
    final c = DesignTokens.palettes[AppTheme.palette]![dark ? 'dark' : 'light']!;
    final ink = c['paperInk']!;
    final frame = c['frame']!;
    final hlAyah = const Color(0xFF28A06E).withValues(alpha: 0.28);
    final hlWord = const Color(0xFFF0B01E).withValues(alpha: 0.45);
    String label(String folder) => folder.startsWith('Minshawy') ? l.kidsTeacherMinshawy : l.kidsTeacherHusary;
    final t = _t;
    final size = _sizes[_size];
    final surah = q.surah(widget.surah);
    return Scaffold(
      appBar: AppBar(title: Text(l.kidsTeacherSurah(surah.nameAr))),
      bottomNavigationBar: t == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceMd,
                  DesignTokens.spaceXs,
                  DesignTokens.spaceMd,
                  DesignTokens.spaceSm,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.spaceSm,
                  runSpacing: DesignTokens.spaceXs,
                  children: [
                    IconButton.outlined(
                      key: const Key('kidsMushaf.prev'),
                      tooltip: l.kidsTeacherPrev,
                      icon: const RIcon(RIcons.prev),
                      onPressed: () => _step(-1),
                    ),
                    FilledButton.icon(
                      key: const Key('kidsMushaf.play'),
                      style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
                      icon: RIcon(_playing ? RIcons.pause : RIcons.play),
                      label: Text(_playing ? l.kidsTeacherPause : l.kidsTeacherPlay),
                      onPressed: () => unawaited(_toggle()),
                    ),
                    IconButton.outlined(
                      key: const Key('kidsMushaf.next'),
                      tooltip: l.kidsTeacherNext,
                      icon: const RIcon(RIcons.next),
                      onPressed: () => _step(1),
                    ),
                    FilterChip(
                      key: const Key('kidsMushaf.repeat'),
                      avatar: const RIcon(RIcons.repeat, size: 18),
                      label: Text(l.kidsTeacherRepeat),
                      selected: _repeat,
                      onSelected: (v) => setState(() => _repeat = v),
                    ),
                  ],
                ),
              ),
            ),
      body: t == null
          ? const Center(child: CircularProgressIndicator())
          : ReadableWidth(
              child: ListView(
                key: const Key('kidsMushaf'),
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                children: [
                  SegmentedButton<String>(
                    key: const Key('kidsMushaf.reciter'),
                    showSelectedIcon: false,
                    segments: [
                      for (final f in _available(_t!))
                        ButtonSegment(
                          value: f,
                          label: Text(label(f), textAlign: TextAlign.center),
                        ),
                    ],
                    selected: {_reciter},
                    onSelectionChanged: (v) => unawaited(_pickReciter(v.single)),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Row(
                    children: [
                      Expanded(child: Text(l.kidsTeacherHint, style: theme.textTheme.bodySmall)),
                      IconButton.outlined(
                        key: const Key('kidsMushaf.smaller'),
                        tooltip: l.kidsTeacherSmaller,
                        onPressed: _size == 0 ? null : () => setState(() => _size--),
                        icon: const Text('أ-', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      IconButton.outlined(
                        key: const Key('kidsMushaf.bigger'),
                        tooltip: l.kidsTeacherBigger,
                        onPressed: _size == _sizes.length - 1 ? null : () => setState(() => _size++),
                        icon: const Text('أ+', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Container(
                    key: const Key('kidsMushaf.page'),
                    decoration: BoxDecoration(
                      color: c['paper'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: frame, width: 3),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      DesignTokens.spaceMd,
                      DesignTokens.spaceLg,
                      DesignTokens.spaceLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(frame.withValues(alpha: 0.14), c['paper']!),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: frame.withValues(alpha: 0.7), width: 2),
                            ),
                            child: Text(
                              l.kidsTeacherSurah(surah.nameAr),
                              style: TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: 22, color: ink),
                            ),
                          ),
                        ),
                        if (widget.surah != 1 && widget.surah != 9)
                          Text(
                            s.content.renderMap.forDisplay(q.text(const AyahRef(1, 1))),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.quran(context, size * 0.85).copyWith(color: ink),
                          ),
                        Text.rich(
                          key: const Key('kidsMushaf.text'),
                          TextSpan(children: _spans(q, ink, hlAyah, hlWord)),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          style: AppTheme.quran(context, size).copyWith(color: ink, height: 2.1),
                        ),
                      ],
                    ),
                  ),
                  if (_cheer)
                    Padding(
                      padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
                      child: Text(
                        '⭐ ${l.kidsTeacherWell}',
                        key: const Key('kidsMushaf.cheer'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                    child: Text(
                      '${'⭐' * _stars.clamp(0, 5)} ${l.kidsTeacherStars(context.num(_stars))}',
                      key: const Key('kidsMushaf.stars'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<InlineSpan> _spans(QuranContent q, Color ink, Color hlAyah, Color hlWord) {
    final map = context.services.content.renderMap;
    final out = <InlineSpan>[];
    final count = q.surah(widget.surah).ayahCount;
    for (var a = 0; a < count; a++) {
      final text = q.text(AyahRef(widget.surah, a + 1));
      final tk = ayahTokens(text);
      final on = _pos?.ayah == a;
      final bg = on ? hlAyah : null;
      for (var k = 0; k < tk.words.length; k++) {
        final lit = (on && _pos?.word == k) || _tapped == '$a:$k';
        out.add(
          TextSpan(
            text: map.forDisplay(tk.words[k]),
            recognizer: _tap('w$a:$k', () => unawaited(_sayWord(a, k, tk.words))),
            style: TextStyle(backgroundColor: lit ? Color.alphaBlend(hlWord, hlAyah) : bg),
          ),
        );
        if (k < tk.gaps.length) {
          out.add(
            TextSpan(
              text: tk.gaps[k],
              style: TextStyle(backgroundColor: bg),
            ),
          );
        }
      }
      out
        ..add(
          TextSpan(
            text: '\u00A0',
            style: TextStyle(backgroundColor: bg),
          ),
        )
        ..add(
          TextSpan(
            text: ayahMarker(a + 1),
            recognizer: _tap('a$a', () => unawaited(_start(a, only: true))),
            style: TextStyle(backgroundColor: bg),
            semanticsLabel: context.l10n.kidsTeacherAyah(context.num(a + 1)),
          ),
        )
        ..add(const TextSpan(text: ' '));
    }
    return out;
  }
}
