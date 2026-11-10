/// Recitations and Quran radios from mp3quran.net's public API (v3), read on the device.
/// The owner chose this source on 2026-11-10; its site notice allows any visitor or developer
/// to use its material and links. Only https addresses are kept.
library;

class Mp3Moshaf {
  const Mp3Moshaf({
    required this.id,
    required this.name,
    required this.rewayaId,
    required this.server,
    required this.surahs,
  });

  final int id;
  final String name;
  final int rewayaId;

  /// Folder of the MP3 files, ending in "/" (e.g. https://cdn.mp3quran.net/audio/RECITER/r1/).
  final String server;

  /// Surah numbers this recording has, in order.
  final List<int> surahs;

  /// Address of one surah's recording ("001.mp3" … "114.mp3").
  String url(int surah) => '$server${surah.toString().padLeft(3, '0')}.mp3';
}

class Mp3Reciter {
  const Mp3Reciter({required this.id, required this.name, required this.moshafs});
  final int id;
  final String name;
  final List<Mp3Moshaf> moshafs;

  bool hasRewaya(int id) => moshafs.any((m) => m.rewayaId == id);
}

class Mp3Rewaya {
  const Mp3Rewaya(this.id, this.name);
  final int id;
  final String name;
}

class Mp3Radio {
  const Mp3Radio({required this.id, required this.name, required this.url});
  final int id;
  final String name;
  final String url;
}

/// Everything the library screen shows, for one language.
class Mp3Library {
  const Mp3Library({required this.reciters, required this.riwayat, required this.radios});

  static const empty = Mp3Library(reciters: [], riwayat: [], radios: []);

  final List<Mp3Reciter> reciters;
  final List<Mp3Rewaya> riwayat;
  final List<Mp3Radio> radios;

  /// Builds the library from the three API answers, dropping anything malformed or not https.
  factory Mp3Library.fromApi({required Object? reciters, required Object? riwayat, required Object? radios}) {
    List<dynamic> list(Object? j, String key) =>
        j is Map<String, dynamic> && j[key] is List<dynamic> ? j[key] as List<dynamic> : const [];
    final rs = <Mp3Reciter>[];
    for (final r in list(reciters, 'reciters')) {
      if (r is! Map<String, dynamic> || r['id'] is! int || r['name'] is! String) continue;
      final ms = <Mp3Moshaf>[];
      for (final m in r['moshaf'] is List<dynamic> ? r['moshaf'] as List<dynamic> : const []) {
        if (m is! Map<String, dynamic>) continue;
        final server = m['server'];
        if (server is! String || !isHttps(server) || m['id'] is! int || m['name'] is! String) continue;
        final surahs = parseSurahList(m['surah_list']);
        if (surahs.isEmpty) continue;
        ms.add(
          Mp3Moshaf(
            id: m['id'] as int,
            name: (m['name'] as String).trim(),
            rewayaId: m['rewaya_id'] is int ? m['rewaya_id'] as int : 0,
            server: server.endsWith('/') ? server : '$server/',
            surahs: surahs,
          ),
        );
      }
      if (ms.isNotEmpty) rs.add(Mp3Reciter(id: r['id'] as int, name: (r['name'] as String).trim(), moshafs: ms));
    }
    rs.sort((a, b) => a.name.compareTo(b.name));
    final rw = [
      for (final w in list(riwayat, 'riwayat'))
        if (w is Map<String, dynamic> && w['id'] is int && w['name'] is String)
          Mp3Rewaya(w['id'] as int, (w['name'] as String).trim()),
    ];
    final rd = [
      for (final r in list(radios, 'radios'))
        if (r is Map<String, dynamic> && r['id'] is int && r['name'] is String && r['url'] is String)
          if (isHttps(r['url'] as String))
            Mp3Radio(id: r['id'] as int, name: (r['name'] as String).trim(), url: r['url'] as String),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return Mp3Library(reciters: rs, riwayat: rw, radios: rd);
  }

  /// Reciters matching [query] (diacritics ignored by [normalize]) and, if given, a rewaya.
  List<Mp3Reciter> filterReciters(String query, int? rewaya, String Function(String) normalize) {
    final q = normalize(query);
    return [
      for (final r in reciters)
        if ((rewaya == null || r.hasRewaya(rewaya)) && (q.isEmpty || normalize(r.name).contains(q))) r,
    ];
  }

  List<Mp3Radio> filterRadios(String query, String Function(String) normalize) {
    final q = normalize(query);
    return [
      for (final r in radios)
        if (q.isEmpty || normalize(r.name).contains(q)) r,
    ];
  }
}

bool isHttps(String url) {
  final u = Uri.tryParse(url);
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}

/// "1,2,114" → [1, 2, 114] (only 1..114, no repeats, in order).
List<int> parseSurahList(Object? raw) {
  if (raw is! String) return const [];
  final seen = <int>{};
  for (final p in raw.split(',')) {
    final n = int.tryParse(p.trim());
    if (n != null && n >= 1 && n <= 114) seen.add(n);
  }
  return seen.toList()..sort();
}
