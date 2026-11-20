import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/parent_lock.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';

/// Videos opened with the parent's PIN stay open until the app goes to the background.
final parentLockOpen = ValueNotifier<bool>(false);

/// Parent lock in front of the videos tab (owner's choice 2026-11-20, Google Play
/// Families policy). First time: the parent picks a 4-digit PIN; then the PIN opens
/// videos. "Forgot the PIN?" asks a multiplication question, then a new PIN.
class ParentGate extends StatefulWidget {
  const ParentGate({super.key, required this.child, this.random});
  final Widget child;
  final Random? random;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

enum _Step { enter, create, confirm, challenge }

class _ParentGateState extends State<ParentGate> with WidgetsBindingObserver {
  final _pin = TextEditingController();
  late _Step _step;
  String? _first;
  String? _error;
  (int, int)? _q;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    parentLockOpen.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _step = context.services.settings.parentPinHash == null ? _Step.create : _Step.enter;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) parentLockOpen.value = false;
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      _step = context.services.settings.parentPinHash == null ? _Step.create : _Step.enter;
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
      builder: (context, open, _) => open ? widget.child : _lock(context),
    );
  }

  Widget _lock(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final challenge = _step == _Step.challenge;
    final prompt = switch (_step) {
      _Step.enter => l.parentLockEnter,
      _Step.create => l.parentLockSetTitle,
      _Step.confirm => l.parentLockConfirm,
      _Step.challenge => l.parentLockChallenge('${_q!.$1}', '${_q!.$2}'),
    };
    final button = switch (_step) {
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
