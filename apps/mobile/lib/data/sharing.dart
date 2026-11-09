import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares a rendered image (prayer calendar, ayah or dhikr card) through the system share sheet.
abstract class ImageSharer {
  Future<void> sharePng(Uint8List png, {required String fileName, String? text});
  Future<void> shareText(String text);
}

class SystemImageSharer implements ImageSharer {
  const SystemImageSharer();

  @override
  Future<void> sharePng(Uint8List png, {required String fileName, String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        text: text,
      ),
    );
  }

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
