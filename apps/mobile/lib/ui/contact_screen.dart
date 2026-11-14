import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_services.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'widgets.dart';

/// Sends a contact message. The owner's inbox address lives only in the form
/// service address (app-links.json "contactForm"); it is never shown in the app.
typedef ContactSender = Future<bool> Function(Uri endpoint, Map<String, String> fields);

Future<bool> postContactForm(Uri endpoint, Map<String, String> fields) async {
  try {
    final r = await http
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 20));
    return r.statusCode >= 200 && r.statusCode < 300;
  } catch (_) {
    return false;
  }
}

/// "Contact us" (owner, 2026-11-11): a form; the message is emailed to the team.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, this.sender = postContactForm});
  final ContactSender sender;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _title.dispose();
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l = context.l10n;
    final endpoint = context.services.content.links.contactForm;
    final messenger = ScaffoldMessenger.of(context);
    if (endpoint == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.contactFailed)));
      return;
    }
    setState(() => _sending = true);
    String v(TextEditingController c) => c.text.trim().isEmpty ? '-' : c.text.trim();
    final ok = await widget.sender(Uri.parse(endpoint), {
      'title': _title.text.trim(),
      'name': v(_name),
      'phone': v(_phone),
      'whatsapp': v(_whatsapp),
      'message': _message.text.trim(),
      'source': 'app',
      '_subject': 'Rattil wa Salli app: ${_title.text.trim()}',
      '_template': 'table',
      '_captcha': 'false',
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.contactFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.helpContact)),
      body: ReadableWidth(
        child: _sent
            ? Center(
                key: const Key('contactSent'),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RIcon(RIcons.checkCircle, size: 56, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Text(
                        l.contactThanks,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [
                    SectionCard(
                      children: [
                        Text(l.contactIntro),
                        const SizedBox(height: DesignTokens.spaceMd),
                        TextFormField(
                          key: const Key('contactTitle'),
                          controller: _title,
                          decoration: InputDecoration(labelText: l.contactTitle, border: const OutlineInputBorder()),
                          validator: (v) => (v ?? '').trim().isEmpty ? l.contactTitleRequired : null,
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        TextFormField(
                          key: const Key('contactName'),
                          controller: _name,
                          decoration: InputDecoration(labelText: l.contactName, border: const OutlineInputBorder()),
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        TextFormField(
                          key: const Key('contactPhone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: l.contactPhone, border: const OutlineInputBorder()),
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        TextFormField(
                          key: const Key('contactWhatsapp'),
                          controller: _whatsapp,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: l.contactWhatsapp, border: const OutlineInputBorder()),
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        TextFormField(
                          key: const Key('contactMessage'),
                          controller: _message,
                          minLines: 5,
                          maxLines: 10,
                          decoration: InputDecoration(labelText: l.contactMessage, border: const OutlineInputBorder()),
                          validator: (v) => (v ?? '').trim().length < 3 ? l.contactMessageRequired : null,
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        FilledButton.icon(
                          key: const Key('contactSend'),
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const RIcon(RIcons.mail),
                          label: Text(l.contactSend),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
