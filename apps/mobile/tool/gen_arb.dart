// Generates lib/l10n/app_ar.arb and lib/l10n/app_en.arb from
//   packages/shared-schemas/i18n/{ar,en}.json   (shared with web/API)
//   apps/mobile/tool/i18n/mobile.{ar,en}.json   (mobile-only strings)
// then `flutter gen-l10n` (see l10n.yaml) turns the ARB files into Dart.
//
// Usage (from apps/mobile):  dart run tool/gen_arb.dart [--check]
// Dotted keys are converted to lowerCamelCase ("nav.home" -> "navHome") and
// every {placeholder} becomes a String placeholder.
import 'dart:convert';
import 'dart:io';

const locales = ['ar', 'en'];

String camel(String key) {
  final parts = key.split(RegExp(r'[._-]'));
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

Map<String, String> readStrings(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('_')) e.key: e.value as String,
  };
}

void main(List<String> args) {
  final check = args.contains('--check');
  final appDir = File.fromUri(Platform.script).parent.parent.path;
  final root = Directory('$appDir/../..').absolute.path;
  final merged = <String, Map<String, String>>{};
  for (final loc in locales) {
    final shared = readStrings('$root/packages/shared-schemas/i18n/$loc.json');
    final mobile = readStrings('$appDir/tool/i18n/mobile.$loc.json');
    final clash = shared.keys.toSet().intersection(mobile.keys.toSet());
    if (clash.isNotEmpty) {
      stderr.writeln('mobile keys collide with shared keys: $clash');
      exit(1);
    }
    merged[loc] = {...shared, ...mobile};
  }
  final keysAr = merged['ar']!.keys.toSet();
  final keysEn = merged['en']!.keys.toSet();
  if (keysAr.length != keysEn.length || !keysAr.containsAll(keysEn)) {
    stderr.writeln('ar/en keys differ: ${keysAr.difference(keysEn)} ${keysEn.difference(keysAr)}');
    exit(1);
  }
  final placeholder = RegExp(r'\{(\w+)\}');
  var stale = false;
  for (final loc in locales) {
    final out = <String, Object>{'@@locale': loc};
    for (final key in merged[loc]!.keys.toList()..sort()) {
      final value = merged[loc]![key]!;
      final id = camel(key);
      out[id] = value;
      final names = placeholder.allMatches(value).map((m) => m[1]!).toSet();
      final otherNames = placeholder.allMatches(merged[loc == 'ar' ? 'en' : 'ar']![key]!).map((m) => m[1]!).toSet();
      if (names.length != otherNames.length || !names.containsAll(otherNames)) {
        stderr.writeln('placeholder mismatch for "$key": $names vs $otherNames');
        exit(1);
      }
      if (loc == 'en') {
        out['@$id'] = {
          'description': 'shared key "$key"',
          if (names.isNotEmpty)
            'placeholders': {
              for (final n in names) n: {'type': 'String'},
            },
        };
      }
    }
    final text = '${const JsonEncoder.withIndent('  ').convert(out)}\n';
    final file = File('$appDir/lib/l10n/app_$loc.arb');
    if (check) {
      if (!file.existsSync() || file.readAsStringSync() != text) {
        stderr.writeln('stale: ${file.path}');
        stale = true;
      }
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(text);
      stdout.writeln('wrote ${file.path} (${merged[loc]!.length} strings)');
    }
  }
  if (stale) exit(1);
}
