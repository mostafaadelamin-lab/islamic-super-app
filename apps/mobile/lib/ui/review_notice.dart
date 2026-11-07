import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Visible "pending religious review" notice for adhkar and the Hajj guide.
class ReviewNotice extends StatelessWidget {
  const ReviewNotice(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.secondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Style for adhkar / dua texts (IBM Plex Sans Arabic, generous line height).
TextStyle duaStyle(BuildContext context, {double size = 18}) => TextStyle(
  fontFamily: DesignTokens.fontUi,
  fontSize: size,
  height: 1.9,
  color: Theme.of(context).colorScheme.onSurface,
);
