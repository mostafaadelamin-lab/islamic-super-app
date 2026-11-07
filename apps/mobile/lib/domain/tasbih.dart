/// Tasbih counter state (pure). A round is [target] taps; [total] counts every
/// tap ever made until reset.
class TasbihState {
  const TasbihState({this.count = 0, this.total = 0, this.rounds = 0, this.target = 33});

  final int count;
  final int total;
  final int rounds;
  final int target;

  static const targets = [33, 99, 100, 1000];

  /// One tap. When [count] reaches [target] a round is completed and the
  /// counter starts again from zero.
  TasbihState tap() {
    final c = count + 1;
    if (c >= target) return TasbihState(count: 0, total: total + 1, rounds: rounds + 1, target: target);
    return TasbihState(count: c, total: total + 1, rounds: rounds, target: target);
  }

  /// True when the last tap completed a round (count wrapped to zero).
  bool completedRoundFrom(TasbihState before) => rounds > before.rounds;

  TasbihState withTarget(int t) => TasbihState(count: count >= t ? 0 : count, total: total, rounds: rounds, target: t);

  TasbihState reset() => TasbihState(target: target);

  Map<String, int> toJson() => {'count': count, 'total': total, 'rounds': rounds, 'target': target};

  factory TasbihState.fromJson(Map<String, dynamic> j) {
    final t = (j['target'] as num?)?.toInt() ?? 33;
    final target = t < 1 ? 33 : t;
    final c = (j['count'] as num?)?.toInt() ?? 0;
    return TasbihState(
      count: c < 0 || c >= target ? 0 : c,
      total: ((j['total'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31),
      rounds: ((j['rounds'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31),
      target: target,
    );
  }
}
