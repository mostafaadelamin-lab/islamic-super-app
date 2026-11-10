import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Large-screen layout (iPad, Android tablets, foldables, landscape).
///
/// Width classes follow the Material window-size classes: compact < 600,
/// medium 600–839, expanded ≥ 840.
abstract final class Adaptive {
  static const medium = 600.0;
  static const expanded = 840.0;

  /// Widest a column of text or list rows gets, so lines stay easy to read.
  static const readableWidth = 720.0;

  /// Widest the home and section tabs get beside the navigation rail.
  static const tabWidth = 960.0;

  /// Width of a Mushaf page relative to its height (Madina print proportions).
  static const mushafAspect = 0.68;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// True from tablet width up: the navigation rail replaces the bottom bar.
  static bool isWide(BuildContext context) => width(context) >= medium;

  /// True on wide screens: the rail shows its labels beside the icons.
  static bool isExpanded(BuildContext context) => width(context) >= expanded;
}

/// Centres [child] and caps its width at [maxWidth]; on a phone it changes nothing.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = Adaptive.readableWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // The same widget tree at every width, so rotating keeps scroll positions and state.
    builder: (context, c) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: math.min(c.maxWidth, maxWidth),
        height: c.maxHeight.isFinite ? c.maxHeight : null,
        child: child,
      ),
    ),
  );
}

/// A Mushaf page on a tablet: as wide as a printed page is for the height it has,
/// centred on the reader background. Phones (and landscape phones, which are too
/// short for a whole page) keep the full width.
class TabletPage extends StatelessWidget {
  const TabletPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).shortestSide >= Adaptive.medium;
    return LayoutBuilder(
      builder: (context, c) {
        final width = tablet ? math.min(c.maxWidth, c.maxHeight * Adaptive.mushafAspect) : c.maxWidth;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(width: width, height: c.maxHeight, child: child),
          ),
        );
      },
    );
  }
}
