import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'contact_screen.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// «لاحظت خطأ في هذه الصفحة؟ بلّغ عن خطأ» at the end of content pages (owner 2026-11-24:
/// adhkar, hadith, tafsir, lessons; never on the home, Adhan or sections pages). Opens the
/// contact form with its title filled in; the message goes to the team's email.
class ReportErrorLink extends StatelessWidget {
  const ReportErrorLink({super.key, required this.page});

  /// The page's name, put in the form's title ("خطأ في: كتب التفسير").
  final String page;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l.reportPrompt, style: theme.textTheme.bodySmall),
          TextButton.icon(
            key: const Key('reportError'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => ContactScreen(initialTitle: l.reportTitle(page)))),
            icon: const RIcon(RIcons.flag, size: 18),
            label: Text(l.reportAction),
          ),
        ],
      ),
    );
  }
}
