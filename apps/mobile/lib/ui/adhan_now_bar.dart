import 'package:flutter/material.dart';

import '../data/notifications.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'r_icon.dart';

/// iPhone: when the app is opened from a prayer-time alert, the rest of the adhan plays in the app; this bar
/// (on top of every screen) says so and stops it.
class AdhanNowBar extends StatelessWidget {
  const AdhanNowBar({super.key, required this.preview, required this.child});

  final AdhanPreview preview;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preview,
      builder: (context, _) {
        if (!preview.fromAlert) return child;
        final l = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        return Stack(
          children: [
            child,
            Positioned(
              left: DesignTokens.spaceMd,
              right: DesignTokens.spaceMd,
              bottom: MediaQuery.paddingOf(context).bottom + 88,
              child: Material(
                key: const Key('adhanNowBar'),
                color: scheme.primaryContainer,
                elevation: 6,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceXs),
                  child: Row(
                    children: [
                      RIcon(RIcons.prayer, color: scheme.onPrimaryContainer),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Text(
                          l.adhanNowPlaying,
                          style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('adhanNowStop'),
                        onPressed: preview.stop,
                        icon: const RIcon(RIcons.stop),
                        label: Text(l.adhanStop),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
