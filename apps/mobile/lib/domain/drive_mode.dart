// Driving mode for the morning / evening adhkar (1.2.2): the app recites every
// dhikr out loud as many times as Hisn al-Muslim says, and counts for the driver.
//
// The voice is Sheikh Mishary Alafasy's morning / evening recording (the same file
// the "listen" card plays). That recording reads each dhikr once or a few times and
// then its virtue and narrator; for driving the app plays ONE reading of the dhikr
// (a clip of the recording, timestamps in assets/content/adhkar-drive.v1.json, made by
// tools/adhkar_drive_clips.py) and repeats it itself the stated number of times.
// The counts are never in that file: they come from adhkarMeta (Hisn al-Muslim).

import 'adhkar.dart';

/// One reading of a dhikr inside a recording.
class DriveClip {
  const DriveClip(this.start, this.end, {this.file});
  final Duration start;
  final Duration end;

  /// The recording, when it is not the session's own (a dhikr the evening recording
  /// does not read is taken from the morning one).
  final String? file;
  Duration get length => end - start;
}

/// Clips for one session: which recording, and the clip of each dhikr (by adhkar.v1.json index).
class DriveSessionClips {
  const DriveSessionClips({required this.file, required this.clips});
  final String file;
  final Map<int, DriveClip> clips;
}

/// assets/content/adhkar-drive.v1.json.
class DriveClips {
  const DriveClips(this.sessions);

  factory DriveClips.fromJson(Map<String, dynamic> j) {
    DriveSessionClips one(Map<String, dynamic> s) => DriveSessionClips(
      file: s['file'] as String,
      clips: {
        for (final e in (s['clips'] as Map<String, dynamic>).entries)
          int.parse(e.key): DriveClip(
            Duration(milliseconds: ((e.value as List<dynamic>)[0] as num).round()),
            Duration(milliseconds: ((e.value as List<dynamic>)[1] as num).round()),
            file: (e.value as List<dynamic>).length > 2 ? (e.value as List<dynamic>)[2] as String : null,
          ),
      },
    );
    return DriveClips({
      for (final s in AdhkarSession.values)
        if (j[s.name] case final Map<String, dynamic> m) s: one(m),
    });
  }

  static const asset = 'assets/content/adhkar-drive.v1.json';

  final Map<AdhkarSession, DriveSessionClips> sessions;
}

/// One dhikr of the drive: its text (Hisn al-Muslim, unchanged), how many times, and its clip.
class DriveItem {
  const DriveItem({required this.dhikr, required this.clip});
  final Dhikr dhikr;
  final DriveClip clip;
  int get count => dhikr.meta.count;
}

/// The adhkar of [session] in the app's order, each with its clip. Items the recording
/// does not read (no clip) are left out, so the drive never goes silent.
List<DriveItem> drivePlan(AdhkarContent content, DriveClips clips, AdhkarSession session) {
  final s = clips.sessions[session];
  if (s == null) return const [];
  return [
    for (final d in content.forSession(session))
      if (s.clips[d.index] case final c?) DriveItem(dhikr: d, clip: c),
  ];
}

final _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
final _openers = [
  RegExp(r'^\s*أعوذ بالله من الشيطان الرجيم\s*'),
  RegExp(r'^\s*بسم الله الرحمن الرحيم\s*'),
];

/// A short name for the car screen / lock screen: the first words of the dhikr's own
/// text (the isti'adha / basmala before a Quran passage skipped), without diacritics so it
/// stays readable on car displays. Nothing is added to the text.
String driveTitle(String text, {int words = 5}) {
  var t = text.replaceAll(_marks, '');
  t = t.replaceAll(RegExp('[ٱ]'), 'ا');
  for (final o in _openers) {
    t = t.replaceFirst(o, '');
  }
  t = t.replaceAll(RegExp(r'[﴿﴾«»()\[\]*.:،,؛]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final w = t.split(' ');
  return w.length <= words ? t : '${w.take(words).join(' ')}…';
}

/// When to say the count out loud: every [every] repetitions (0 = never), never on the last
/// one (the end sound says that), and only for adhkar said at least [every] times.
bool isMilestone(int done, int count, int every) => every > 0 && done < count && done % every == 0;
