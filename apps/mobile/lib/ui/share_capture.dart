import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// PNG bytes of the RepaintBoundary under [key] (at [pixelRatio]), or null when it is not painted yet.
Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 2}) async {
  final b = key.currentContext?.findRenderObject();
  if (b is! RenderRepaintBoundary) return null;
  final image = await b.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}
