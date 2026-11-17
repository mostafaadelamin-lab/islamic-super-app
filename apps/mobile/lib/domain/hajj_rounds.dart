/// Round counters of the Hajj & Umrah guide (same as the website's lib/rounds.ts): seven rounds of tawaf,
/// seven of sa'i, seven pebbles at a jamrah. Only counts taps; no religious text here.
enum RoundTool { tawaf, sai, jamarat }

const roundsTarget = 7;

/// The counters each guide step gets (same table as the website's STEP_TOOLS in HajjGuide.tsx).
const stepRoundTools = <String, List<RoundTool>>{
  'tawaf-first': [RoundTool.tawaf],
  'ifadah': [RoundTool.tawaf],
  'ifadah-tamattu': [RoundTool.tawaf, RoundTool.sai],
  'farewell': [RoundTool.tawaf],
  'sai': [RoundTool.sai],
  'sai-qudum': [RoundTool.sai],
  'aqaba': [RoundTool.jamarat],
  'tashriq-rami': [RoundTool.jamarat],
};

/// Reads the saved counts ({"tawaf": 3, ...}); anything odd counts as 0, nothing goes past 7.
Map<RoundTool, int> sanitizeRounds(Object? raw) {
  final m = raw is Map ? raw : const {};
  int one(Object? v) => v is int && v >= 0 ? (v > roundsTarget ? roundsTarget : v) : 0;
  return {for (final t in RoundTool.values) t: one(m[t.name])};
}

/// One more (or one less) round, kept between 0 and 7.
Map<RoundTool, int> addRound(Map<RoundTool, int> r, RoundTool tool, int delta) {
  final n = (r[tool] ?? 0) + delta;
  return {...r, tool: n < 0 ? 0 : (n > roundsTarget ? roundsTarget : n)};
}

Map<String, int> roundsToJson(Map<RoundTool, int> r) => {for (final e in r.entries) e.key.name: e.value};
