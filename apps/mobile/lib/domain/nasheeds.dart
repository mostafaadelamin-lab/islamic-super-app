/// Nasheeds (audio, streamed or downloaded for offline listening) and the
/// adhkar recordings played from Sheikh Alafasy's official channel.
/// Nasheed list: assets/content/nasheeds.v2.json, built by tools/nasheeds_build.py
/// (sources: docs/CONTENT_SOURCES.md, never shown in the app).
library;

import 'dart:convert';

class MediaItem {
  const MediaItem(this.videoId, this.titleAr, [this.titleEn]);
  final String videoId;
  final String titleAr;
  final String? titleEn;

  static final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
}

class Nasheed {
  const Nasheed({required this.id, required this.title, required this.url, this.bytes});
  final int id;
  final String title;
  final String url;
  final int? bytes;
}

class Munshid {
  const Munshid({required this.id, required this.name, required this.items});
  final int id;
  final String name;
  final List<Nasheed> items;

  static List<Munshid> parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final s in j['singers'] as List)
        Munshid(
          id: s['id'] as int,
          name: s['name'] as String,
          items: [
            for (final i in s['items'] as List)
              Nasheed(
                id: i['id'] as int,
                title: i['title'] as String,
                url: i['url'] as String,
                bytes: i['bytes'] as int?,
              ),
          ],
        ),
    ];
  }
}

enum AdhkarAudio { morning, evening, afterPrayer, sleep }

const alafasyAdhkarChannel = 'UCmMcOjsVehVlEOteyrhjI2Q';

const adhkarAudioVideo = <AdhkarAudio, String>{
  AdhkarAudio.morning: 'V2Brp_esIVI',
  AdhkarAudio.evening: 'TGtdZmxsM5Q',
  AdhkarAudio.afterPrayer: 'BQxnb6DzyzI',
  AdhkarAudio.sleep: '5HmvokzY3Jg',
};
