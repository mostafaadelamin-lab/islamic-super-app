/// Public links set by the owner (packages/shared-schemas/app-links.json); null = not set (button hidden).
class AppLinks {
  const AppLinks({this.contactEmail, this.website, this.playStore, this.appStore});

  factory AppLinks.fromJson(Map<String, dynamic> j) {
    String? s(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    return AppLinks(
      contactEmail: s(j['contactEmail']),
      website: s(j['website']),
      playStore: s(j['playStore']),
      appStore: s(j['appStore']),
    );
  }

  final String? contactEmail;
  final String? website;
  final String? playStore;
  final String? appStore;
}

/// Distinct days of use before the one-time "share Rattil" suggestion.
const sharePromptAfterDays = 5;

/// Records [today] among the days of use; `show` is true when the suggestion should appear now.
({List<String> days, bool show}) sharePromptVisit(List<String> days, bool done, String today) {
  if (done) return (days: days, show: false);
  final next = days.contains(today) ? days : [...days, today];
  final kept = next.length > sharePromptAfterDays ? next.sublist(next.length - sharePromptAfterDays) : next;
  return (days: kept, show: kept.length >= sharePromptAfterDays);
}
