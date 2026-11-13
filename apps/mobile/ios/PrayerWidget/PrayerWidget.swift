// Home-screen widget for iOS (WidgetKit): Hijri date, the time, the next prayer
// and a ring that fills from the previous prayer to the next one.
// Data: "rattil.widget" in the App Group group.org.rattil.app, written by
// lib/data/home_widget_sync.dart (seven days of prayer times).
// Setup in Xcode (one time, on a Mac): see README.md in this folder.
import SwiftUI
import WidgetKit

struct PrayerEntry: TimelineEntry {
  let date: Date
  let hijri: String
  let name: String
  let next: Date?
  let previous: Date?
  let arabic: Bool
}

private struct Payload: Decodable {
  struct Day: Decodable {
    let d: String
    let h: String
    let p: [[Value]]
  }
  enum Value: Decodable {
    case s(String), n(Double)
    init(from decoder: Decoder) throws {
      let c = try decoder.singleValueContainer()
      if let x = try? c.decode(Double.self) { self = .n(x) } else { self = .s(try c.decode(String.self)) }
    }
  }
  let lang: String
  let days: [Day]
}

struct Provider: TimelineProvider {
  private func load() -> Payload? {
    let defaults = UserDefaults(suiteName: "group.org.rattil.app")
    guard let raw = defaults?.string(forKey: "rattil.widget"), let data = raw.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(Payload.self, from: data)
  }

  /// Every prayer as (name, time, Hijri date of its day), in order.
  private func prayers(_ p: Payload) -> [(String, Date, String)] {
    var out: [(String, Date, String)] = []
    for d in p.days {
      for e in d.p where e.count == 3 {
        if case .s(let name) = e[1], case .n(let ms) = e[2] {
          out.append((name, Date(timeIntervalSince1970: ms / 1000), d.h))
        }
      }
    }
    return out
  }

  private func entry(at date: Date, _ p: Payload?) -> PrayerEntry {
    guard let p = p else {
      return PrayerEntry(date: date, hijri: "", name: "", next: nil, previous: nil, arabic: true)
    }
    let all = prayers(p)
    let idx = all.firstIndex { $0.1 > date }
    let next = idx.map { all[$0] }
    let prev = idx.flatMap { $0 > 0 ? all[$0 - 1].1 : nil }
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let today = fmt.string(from: date)
    let hijri = p.days.first { $0.d == today }?.h ?? next?.2 ?? ""
    return PrayerEntry(date: date, hijri: hijri, name: next?.0 ?? "", next: next?.1, previous: prev, arabic: p.lang != "en")
  }

  func placeholder(in context: Context) -> PrayerEntry { entry(at: Date(), nil) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(entry(at: Date(), load()))
  }

  /// One entry every 10 minutes for 6 hours (the ring moves), plus one at each prayer.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let p = load()
    let now = Date()
    var dates = (0..<36).map { now.addingTimeInterval(Double($0) * 600) }
    if let p = p {
      dates += prayers(p).map { $0.1 }.filter { $0 > now && $0 < now.addingTimeInterval(6 * 3600) }
    }
    let entries = dates.sorted().map { entry(at: $0, p) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct PrayerWidgetView: View {
  let entry: PrayerEntry

  private var fraction: Double {
    guard let next = entry.next else { return 0 }
    let start = entry.previous ?? next.addingTimeInterval(-6 * 3600)
    return min(max(entry.date.timeIntervalSince(start) / next.timeIntervalSince(start), 0), 1)
  }

  var body: some View {
    ZStack {
      Circle().fill(Color(red: 0.12, green: 0.14, blue: 0.19))
      Circle().stroke(Color.white.opacity(0.2), lineWidth: 6)
      Circle()
        .trim(from: 0, to: fraction)
        .stroke(Color(red: 0.95, green: 0.70, blue: 0.24), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .rotationEffect(.degrees(-90))
      VStack(spacing: 2) {
        Text(entry.hijri).font(.system(size: 11)).foregroundColor(.white.opacity(0.85)).lineLimit(1)
        Text(entry.date, style: .time).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
        Divider().background(Color.white.opacity(0.4)).padding(.horizontal, 8)
        Text(entry.name).font(.system(size: 11)).foregroundColor(.white.opacity(0.8))
        if let next = entry.next {
          Text(next, style: .timer).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            .multilineTextAlignment(.center)
        }
      }
      .padding(10)
      .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
    }
    .padding(4)
  }
}

@main
struct PrayerWidget: Widget {
  let kind = "PrayerWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        PrayerWidgetView(entry: entry).containerBackground(.clear, for: .widget)
      } else {
        PrayerWidgetView(entry: entry)
      }
    }
    .configurationDisplayName("رتّل وصلِّ")
    .description("Hijri date, time and the next prayer")
    .supportedFamilies([.systemSmall])
  }
}
