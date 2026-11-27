import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/printed_mushaf.dart';

/// Owner 2026-11-26: the Madina font downloads once for the whole Mushaf; a page font already on the device is
/// never downloaded again (old plain .ttf saves count too).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('download all saves every page once, skips saved pages, and resumes after a cut', () async {
    final dir = await Directory.systemTemp.createTemp('qcf');
    final asked = <int>[];
    var cut = true;
    final pm = PrintedMushaf.instance;
    pm.configure(
      root: () async => dir,
      client: MockClient((req) async {
        final page = int.parse(RegExp(r'p(\d+)\.ttf').firstMatch(req.url.path)!.group(1)!);
        if (cut && page == 300) return http.Response('', 503);
        asked.add(page);
        return http.Response.bytes(List.filled(64, page % 256), 200);
      }),
    );
    // A page saved by an older build (plain .ttf) is kept as it is.
    File('${dir.path}/qcf2/p7.ttf')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    expect(await pm.savedCount(refresh: true), 1);

    await pm.downloadAll();
    expect(pm.bulkFailed, isTrue);
    expect(pm.allSaved, isFalse);
    expect(asked, isNot(contains(7)));

    cut = false;
    final before = asked.length;
    await pm.downloadAll();
    expect(pm.bulkFailed, isFalse);
    expect(pm.allSaved, isTrue);
    expect(await pm.savedCount(refresh: true), PrintedMushaf.pages);
    // The second run only fetched what was missing: every page exactly once overall, page 7 never.
    expect(asked.toSet().length, asked.length);
    expect(asked.length, PrintedMushaf.pages - 1);
    expect(asked.length - before, lessThan(PrintedMushaf.pages - 1));
    expect(File('${dir.path}/qcf2/p300.ttf.gz').existsSync(), isTrue);
    expect(GZipCodec().decode(File('${dir.path}/qcf2/p300.ttf.gz').readAsBytesSync()), List.filled(64, 300 % 256));

    // Everything is saved: tapping again downloads nothing.
    await pm.downloadAll();
    expect(asked.length, PrintedMushaf.pages - 1);
    pm.debugSetProgress();
    await dir.delete(recursive: true);
  });
}
