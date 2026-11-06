import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/account.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _url;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _url = TextEditingController(text: context.services.settings.apiBaseUrl);
      context.services.account.clearMessage();
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  static String messageText(AppLocalizations l, AccountMessage m, String? arg) => switch (m) {
    AccountMessage.registered => l.accountRegistered,
    AccountMessage.syncDone => l.accountSyncDone(arg ?? '0'),
    AccountMessage.serverSaved => l.accountServerSaved,
    AccountMessage.serverInvalid => l.accountServerInvalid,
    AccountMessage.errOffline => l.accountErrOffline,
    AccountMessage.errAuth => l.accountErrAuth,
    AccountMessage.errTaken => l.accountErrTaken,
    AccountMessage.errPassword => l.accountErrPassword,
    AccountMessage.errEmail => l.accountErrEmail,
    AccountMessage.errSession => l.accountErrSession,
    AccountMessage.errRateLimit => l.accountErrRateLimit,
    AccountMessage.errServer => l.accountErrServer(arg ?? '?'),
  };

  @override
  Widget build(BuildContext context) {
    final a = context.services.account;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAccount)),
      body: ListenableBuilder(
        listenable: a,
        builder: (context, _) {
          final m = a.message;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            key: const Key('accountList'),
            children: [
              SectionCard(children: [Text(l.accountOptional)]),
              SectionCard(
                title: l.accountServerUrl,
                children: [
                  TextField(
                    key: const Key('serverUrlField'),
                    controller: _url,
                    keyboardType: TextInputType.url,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.accountServerUrl),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton(
                      key: const Key('saveServerButton'),
                      onPressed: a.busy ? null : () => a.saveServer(_url.text),
                      child: Text(l.accountSaveServer),
                    ),
                  ),
                ],
              ),
              if (m != null)
                SectionCard(
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        messageText(l, m, a.messageArg),
                        key: const Key('accountMessage'),
                        style: TextStyle(color: a.isError ? scheme.error : scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              if (a.busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (a.signedIn)
                SectionCard(
                  children: [
                    Text(l.accountSignedInAs(a.email!), key: const Key('signedInAs')),
                    if (a.lastSync != null)
                      Text(l.accountLastSync(context.numLtr(_fmt(a.lastSync!))), key: const Key('lastSync')),
                    const SizedBox(height: DesignTokens.spaceMd),
                    Wrap(
                      spacing: DesignTokens.spaceSm,
                      runSpacing: DesignTokens.spaceSm,
                      children: [
                        FilledButton.icon(
                          key: const Key('syncNowButton'),
                          onPressed: a.busy ? null : a.syncNow,
                          icon: const Icon(Icons.sync),
                          label: Text(l.accountSyncNow),
                        ),
                        OutlinedButton(
                          key: const Key('logoutButton'),
                          onPressed: a.busy ? null : a.logout,
                          child: Text(l.accountLogout),
                        ),
                      ],
                    ),
                  ],
                )
              else
                SectionCard(
                  children: [
                    TextField(
                      key: const Key('emailField'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l.accountEmail),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    TextField(
                      key: const Key('passwordField'),
                      controller: _password,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: l.accountPassword),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    Wrap(
                      spacing: DesignTokens.spaceSm,
                      runSpacing: DesignTokens.spaceSm,
                      children: [
                        FilledButton(
                          key: const Key('loginButton'),
                          onPressed: a.busy ? null : () => a.login(_email.text, _password.text),
                          child: Text(l.accountLogin),
                        ),
                        OutlinedButton(
                          key: const Key('registerButton'),
                          onPressed: a.busy ? null : () => a.register(_email.text, _password.text),
                          child: Text(l.accountRegister),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
