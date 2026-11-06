// Bookmark model and last-write-wins merge, per packages/api-contracts/API.md:
// Bookmark = {id, surah, ayah, note?, updatedAt (ms epoch), deleted}.

final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

class Bookmark {
  const Bookmark({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.updatedAt,
    this.note,
    this.deleted = false,
  });

  factory Bookmark.fromJson(Map<String, dynamic> j) {
    final b = Bookmark(
      id: j['id'] as String,
      surah: (j['surah'] as num).toInt(),
      ayah: (j['ayah'] as num).toInt(),
      note: j['note'] as String?,
      updatedAt: (j['updatedAt'] as num).toInt(),
      deleted: j['deleted'] as bool? ?? false,
    );
    if (!_idPattern.hasMatch(b.id)) throw FormatException('bad bookmark id ${b.id}');
    if (b.surah < 1 || b.surah > 114 || b.ayah < 1) {
      throw FormatException('bad bookmark position ${b.surah}:${b.ayah}');
    }
    if (b.note != null && b.note!.length > 500) {
      throw const FormatException('note longer than 500 characters');
    }
    return b;
  }

  /// Deterministic id so the same ayah maps to one bookmark on every device.
  static String idFor(int surah, int ayah) => 'b-$surah-$ayah';

  final String id;
  final int surah;
  final int ayah;
  final String? note;
  final int updatedAt;
  final bool deleted;

  Bookmark copyWith({int? updatedAt, bool? deleted, String? note}) => Bookmark(
    id: id,
    surah: surah,
    ayah: ayah,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'ayah': ayah,
    if (note != null) 'note': note,
    'updatedAt': updatedAt,
    'deleted': deleted,
  };

  @override
  bool operator ==(Object other) =>
      other is Bookmark &&
      other.id == id &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.note == note &&
      other.updatedAt == updatedAt &&
      other.deleted == deleted;

  @override
  int get hashCode => Object.hash(id, surah, ayah, note, updatedAt, deleted);

  @override
  String toString() => 'Bookmark($id $surah:$ayah t=$updatedAt deleted=$deleted)';
}

/// Last-write-wins: the copy with the greater updatedAt wins. On a tie the
/// local copy is kept (the server applies the same rule, so both converge).
Bookmark lastWriteWins(Bookmark? local, Bookmark remote) {
  if (local == null) return remote;
  return remote.updatedAt > local.updatedAt ? remote : local;
}

/// Merges [remote] items into [local] (by id) using [lastWriteWins].
/// Returns the merged map and the ids whose local value changed.
(Map<String, Bookmark>, Set<String>) mergeBookmarks(Map<String, Bookmark> local, Iterable<Bookmark> remote) {
  final out = Map<String, Bookmark>.of(local);
  final changed = <String>{};
  for (final r in remote) {
    final winner = lastWriteWins(out[r.id], r);
    if (winner != out[r.id]) {
      out[r.id] = winner;
      changed.add(r.id);
    }
  }
  return (out, changed);
}
