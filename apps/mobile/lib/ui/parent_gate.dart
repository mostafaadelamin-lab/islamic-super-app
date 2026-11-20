import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/kids.dart';
import '../domain/parent_lock.dart';
import '../theme/design_tokens.dart';
import 'kids_screen.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'ruqyah_screen.dart' show loadKids;

/// Videos opened with the parent's PIN stay open until the app goes to the background.
final parentLockOpen = ValueNotifier<bool>(false);

/// Parent lock in front of the videos tab (owner 2026-11-20, Google Play Families
/// policy). First time: a neutral age-group screen (owner's wording). 13 or older: videos open,
/// never asked again. Younger: the parent picks a 4-digit PIN, and the PIN opens
/// videos each time. "Forgot the PIN?" asks a multiplication question, then a new PIN.
/// Owner 2026-11-20 20:37: under 13 sees only the kids section videos here; the
/// parent's PIN opens all videos.
class ParentGate extends StatefulWidget {
  const ParentGate({super.key, required this.child, this.random, this.kidsLoader = loadKids});
  final Widget child;
  final Random? random;
  final Future<KidsContent> Function() kidsLoader;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

enum _Step { age, enter, create, confirm, challenge }

class _ParentGateState extends State<ParentGate> with WidgetsBindingObserver {
  final _pin = TextEditingController();
  late _Step _step;
  String? _first;
  String? _error;
  (int, int)? _q;
  bool _parentAsked = false;
  late final Future<KidsContent> _kids = widget.kidsLoader();

  _Step _startStep() {
    final s = context.services.settings;
    if (s.parentLockAge == null) return _Step.age;
    return s.parentPinHash == null ? _Step.create : _Step.enter;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    parentLockOpen.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _step = _startStep();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) parentLockOpen.value = false;
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      _step = _startStep();
      _parentAsked = false;
      _pin.clear();
      _error = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    parentLockOpen.removeListener(_changed);
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final settings = context.services.settings;
    final v = _pin.text.trim();
    switch (_step) {
      case _Step.age:
        return;
      case _Step.enter:
        if (pinMatches(v, settings.parentPinHash)) {
          parentLockOpen.value = true;
        } else {
          setState(() => _error = l.parentLockWrong);
          _pin.clear();
        }
      case _Step.create:
        if (!isValidPin(v)) return;
        setState(() {
          _first = v;
          _step = _Step.confirm;
          _error = null;
        });
        _pin.clear();
      case _Step.confirm:
        if (v == _first) {
          await settings.setParentPinHash(hashPin(v));
          parentLockOpen.value = true;
        } else {
          setState(() {
            _step = _Step.create;
            _first = null;
            _error = l.parentLockMismatch;
          });
          _pin.clear();
        }
      case _Step.challenge:
        final q = _q!;
        if (int.tryParse(v) == q.$1 * q.$2) {
          setState(() {
            _step = _Step.create;
            _error = null;
          });
        } else {
          setState(() {
            _q = parentChallenge(widget.random ?? Random());
            _error = l.parentLockChallengeWrong;
          });
        }
        _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: parentLockOpen,
      builder: (context, open, _) =>
          open || context.services.settings.parentLockAge == 'adult' ? widget.child : _lock(context),
    );
  }

  Widget _lock(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (_step == _Step.age) return _ageScreen(context);
    if (!_parentAsked) return _kidsVideos(context);
    final challenge = _step == _Step.challenge;
    final prompt = switch (_step) {
      _Step.age => '',
      _Step.enter => l.parentLockEnter,
      _Step.create => l.parentLockSetTitle,
      _Step.confirm => l.parentLockConfirm,
      _Step.challenge => l.parentLockChallenge('${_q!.$1}', '${_q!.$2}'),
    };
    final button = switch (_step) {
      _Step.age => '',
      _Step.enter => l.parentLockUnlock,
      _Step.create => l.parentLockNext,
      _Step.confirm => l.parentLockSave,
      _Step.challenge => l.parentLockReset,
    };
    return Scaffold(
      key: const Key('parentGate'),
      appBar: AppBar(title: Text(l.navVideos)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 56, color: scheme.primary),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Text(l.parentLockTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(l.parentLockIntro, textAlign: TextAlign.center),
                  if (_step == _Step.create || _step == _Step.confirm) ...[
                    const SizedBox(height: DesignTokens.spaceSm),
                    Text(
                      l.parentLockHandOver,
                      key: const Key('parentGate.handOver'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spaceXl),
                  Text(
                    prompt,
                    key: const Key('parentGate.prompt'),
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  SizedBox(
                    width: challenge ? 160 : 200,
                    child: TextField(
                      key: const Key('parentGate.pin'),
                      controller: _pin,
                      autofocus: false,
                      obscureText: !challenge,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: challenge ? 3 : 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 28, letterSpacing: 12),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: challenge ? l.parentLockAnswer : l.parentLockPin,
                        hintStyle: const TextStyle(fontSize: 16, letterSpacing: 0),
                        errorText: _error,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  FilledButton(key: const Key('parentGate.submit'), onPressed: _submit, child: Text(button)),
                  if (_step == _Step.enter) ...[
                    const SizedBox(height: DesignTokens.spaceSm),
                    TextButton(
                      key: const Key('parentGate.forgot'),
                      onPressed: () => setState(() {
                        _step = _Step.challenge;
                        _q = parentChallenge(widget.random ?? Random());
                        _error = null;
                        _pin.clear();
                      }),
                      child: Text(l.parentLockForgot),
                    ),
                  ],
                  TextButton(
                    key: const Key('parentGate.back'),
                    onPressed: () => setState(() {
                      _parentAsked = false;
                      _step = _startStep();
                      _error = null;
                      _pin.clear();
                    }),
                    child: Text(l.parentLockBack),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Neutral age-group screen (owner 2026-11-20): two equal buttons, no hint which
  /// answer opens what (Families policy). Saved only on the device.
  Widget _ageScreen(BuildContext context) {
    final l = context.l10n;
    Future<void> pick(bool adult) async {
      await context.services.settings.setParentLockAge(adult ? 'adult' : 'child');
      if (!mounted) return;
      setState(() {
        _step = _startStep();
        _error = null;
      });
    }

    Widget choice(String key, String label, bool adult) => Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
      child: SizedBox(
        width: 260,
        child: OutlinedButton(
          key: Key('parentGate.age.$key'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          onPressed: () => pick(adult),
          child: Text(label),
        ),
      ),
    );

    return Scaffold(
      key: const Key('parentGate'),
      appBar: AppBar(title: Text(l.navVideos)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            child: Column(
              key: const Key('parentGate.age'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.parentLockAgeTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.spaceLg),
                Text(l.parentLockAgeAsk, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.spaceMd),
                choice('under13', l.parentLockAgeUnder13, false),
                choice('13plus', l.parentLockAge13plus, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Under 13: only the kids section videos (prophets' stories and the kids stories),
  /// and a button for the parent to open all videos with the PIN.
  Widget _kidsVideos(BuildContext context) {
    final l = context.l10n;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return Scaffold(
      key: const Key('parentGate.kids'),
      appBar: AppBar(title: Text(l.parentLockKidsTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: OutlinedButton.icon(
            key: const Key('parentGate.parent'),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(l.parentLockParentOpen),
            onPressed: () => setState(() {
              _parentAsked = true;
              _step = _startStep();
              _error = null;
              _pin.clear();
            }),
          ),
        ),
      ),
      body: FutureBuilder<KidsContent>(
        future: _kids,
        builder: (context, snap) {
          final k = snap.data;
          if (k == null) return const Center(child: CircularProgressIndicator());
          final series = [
            (k.byId('kids-prophets'), l.kidsProphets, l.kidsProphetsSub),
            (k.byId('kids-rasoul'), l.kidsRasoul, l.kidsRasoulSub),
            (k.byId('kids-ramadan'), l.kidsRamadan, l.kidsRamadanSub),
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            children: [
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Text(l.parentLockKidsNote, style: Theme.of(context).textTheme.bodyMedium),
              ),
              for (final (s, title, sub) in series)
                if (s != null)
                  Card(
                    key: Key('parentGate.kids.${s.id}'),
                    margin: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                      vertical: DesignTokens.spaceXs,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceLg,
                        vertical: DesignTokens.spaceSm,
                      ),
                      leading: const RIconBadge(RIcons.video, size: 48),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      subtitle: Text(sub),
                      trailing: const RIcon(RIcons.chevronForward),
                      onTap: () => push(KidsSeriesScreen(series: s, title: title)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
