import 'package:flutter/material.dart';

import '../domain/dua_segments.dart';
import '../theme/app_theme.dart';

/// A Hajj / Umrah step's text with every dua in it shaded (owner 2026-11-15); the words are shown as given.
class DuaText extends StatelessWidget {
  const DuaText(this.text, {super.key, this.style, this.textKey});
  final String text;
  final TextStyle? style;

  /// Key of the inner [Text] (tests find the step text by it).
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final shade = AppTheme.of(context, 'verseHighlight');
    return Text.rich(
      key: textKey,
      TextSpan(
        children: [
          for (final p in duaParts(text))
            TextSpan(
              text: p.text,
              style: p.dua ? TextStyle(backgroundColor: shade, fontWeight: FontWeight.w600) : null,
            ),
        ],
      ),
      style: style,
    );
  }
}
