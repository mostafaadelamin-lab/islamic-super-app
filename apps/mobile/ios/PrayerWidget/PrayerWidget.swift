// Widgets for iOS (WidgetKit):
// - small (home screen): Hijri date, the time, the next prayer and a ring that fills
//   from the previous prayer to the next one;
// - medium (home screen, owner 2026-11-20): day name, Hijri and Gregorian dates, the six
//   times with the next prayer highlighted, and the countdown;
// - lock screen (iOS 16+, owner 2026-11-20): the next prayer, its time and the countdown.
// Data: "rattil.widget" in the App Group group.org.rattil.app, written by
// lib/data/home_widget_sync.dart (seven days of prayer times).
// Setup in Xcode (one time, on a Mac): see README.md in this folder.
import SwiftUI
import WidgetKit

struct PrayerTime {
  let key: String
  let name: String
  let at: Date
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let hijri: String
  let name: String
  let next: Date?
  let previous: Date?
  let arabic: Bool
  var nextKey: String = ""
  /// Today's six times (Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha) for the medium widget.
  var today: [PrayerTime] = []
  var clock12: Bool = true
}

private struct Payload: Decodable {
  struct Day: Decodable {
    let d: String
    let h: String
    let p: [[Value]]
    let sr: Double?
  }
  enum Value: Decodable {
    case s(String), n(Double)
    init(from decoder: Decoder) throws {
      let c = try decoder.singleValueContainer()
      if let x = try? c.decode(Double.self) { self = .n(x) } else { self = .s(try c.decode(String.self)) }
    }
  }
  let lang: String
  let c12: Bool?
  let days: [Day]
}

struct Provider: TimelineProvider {
  private func load() -> Payload? {
    let defaults = UserDefaults(suiteName: "group.org.rattil.app")
    guard let raw = defaults?.string(forKey: "rattil.widget"), let data = raw.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(Payload.self, from: data)
  }

  /// Every prayer as (name, time, Hijri date of its day, key), in order.
  private func prayers(_ p: Payload) -> [(String, Date, String, String)] {
    var out: [(String, Date, String, String)] = []
    for d in p.days {
      for e in d.p where e.count == 3 {
        if case .s(let key) = e[0], case .s(let name) = e[1], case .n(let ms) = e[2] {
          out.append((name, Date(timeIntervalSince1970: ms / 1000), d.h, key))
        }
      }
    }
    return out
  }

  /// The six times of [day] (sunrise after Fajr).
  private func six(_ day: Payload.Day?, arabic: Bool) -> [PrayerTime] {
    guard let day = day else { return [] }
    var out: [PrayerTime] = []
    for e in day.p where e.count == 3 {
      if case .s(let key) = e[0], case .s(let name) = e[1], case .n(let ms) = e[2] {
        out.append(PrayerTime(key: key, name: name, at: Date(timeIntervalSince1970: ms / 1000)))
        if key == "fajr", let sr = day.sr {
          out.append(PrayerTime(key: "sunrise", name: arabic ? "الشروق" : "Sunrise", at: Date(timeIntervalSince1970: sr / 1000)))
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
    let todayDay = p.days.first { $0.d == today }
    let hijri = todayDay?.h ?? next?.2 ?? ""
    let arabic = p.lang != "en"
    return PrayerEntry(
      date: date, hijri: hijri, name: next?.0 ?? "", next: next?.1, previous: prev, arabic: arabic,
      nextKey: next?.3 ?? "", today: six(todayDay, arabic: arabic), clock12: p.c12 ?? true)
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

private let gold = Color(red: 0.95, green: 0.70, blue: 0.24)
private let ink = Color(red: 0.12, green: 0.14, blue: 0.19)

/// "4:48" (12 h, no AM/PM in the small cells) or "04:48" (24 h), with Arabic digits in Arabic.
private func clock(_ d: Date, _ e: PrayerEntry, suffix: Bool = false) -> String {
  let f = DateFormatter()
  f.locale = Locale(identifier: e.arabic ? "ar" : "en_US_POSIX")
  f.dateFormat = e.clock12 ? (suffix ? "h:mm a" : "h:mm") : "HH:mm"
  return f.string(from: d)
}

private func dateText(_ d: Date, _ format: String, arabic: Bool) -> String {
  let f = DateFormatter()
  f.locale = Locale(identifier: arabic ? "ar" : "en_US")
  f.calendar = Calendar(identifier: .gregorian)
  f.dateFormat = format
  return f.string(from: d)
}

private func arabicDigits(_ s: String, _ arabic: Bool) -> String {
  guard arabic else { return s }
  return String(s.map { c in
    if let v = c.wholeNumberValue, c.isASCII { return Character(UnicodeScalar(0x0660 + v)!) }
    return c
  })
}

/// Medium home-screen widget: day, dates, countdown, the six times (the next one in gold).
struct PrayerMediumView: View {
  let entry: PrayerEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 1) {
          Text(dateText(entry.date, "EEEE", arabic: entry.arabic)).font(.system(size: 16, weight: .bold))
          Text(arabicDigits(entry.hijri, entry.arabic) + (entry.arabic ? " هـ" : " AH")).font(.system(size: 12))
            .foregroundColor(.white.opacity(0.8))
          Text(dateText(entry.date, "d MMMM yyyy", arabic: entry.arabic)).font(.system(size: 12))
            .foregroundColor(.white.opacity(0.8))
        }
        Spacer()
        if let next = entry.next {
          VStack(alignment: .trailing, spacing: 1) {
            Text(entry.arabic ? "\(entry.name) بعد" : "\(entry.name) in").font(.system(size: 12))
              .foregroundColor(.white.opacity(0.8))
            Text(next, style: .timer).font(.system(size: 20, weight: .bold)).foregroundColor(gold)
              .multilineTextAlignment(.trailing)
          }
        }
      }
      HStack(spacing: 4) {
        ForEach(Array(entry.today.enumerated()), id: \.offset) { _, t in
          let on = t.key == entry.nextKey && entry.next.map { abs($0.timeIntervalSince(t.at)) < 1 } == true
          VStack(spacing: 2) {
            Text(t.name).font(.system(size: 11)).lineLimit(1).minimumScaleFactor(0.7)
            Text(clock(t.at, entry)).font(.system(size: 13, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
          }
          .foregroundColor(on ? ink : .white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .background(RoundedRectangle(cornerRadius: 12).fill(on ? gold : Color.white.opacity(0.07)))
        }
      }
    }
    .foregroundColor(.white)
    .padding(14)
    .background(ink)
    .environment(\.layoutDirection, entry.arabic ? .rightToLeft : .leftToRight)
    .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
  }
}

/// Lock-screen widgets (iOS 16+): the next prayer, its time and the countdown.
@available(iOS 16.0, *)
struct PrayerLockView: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry

  var body: some View {
    let time = entry.next.map { clock($0, entry, suffix: true) } ?? ""
    switch family {
    case .accessoryInline:
      Text("\(entry.name) \(time)")
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: 0) {
          Text(entry.name).font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
          if let next = entry.next {
            Text(next, style: .timer).font(.system(size: 11)).multilineTextAlignment(.center)
              .lineLimit(1).minimumScaleFactor(0.6)
          }
        }
        .padding(4)
      }
    default:
      VStack(alignment: .leading, spacing: 1) {
        Text("\(entry.name) \(time)").font(.system(size: 17, weight: .bold)).lineLimit(1)
          .minimumScaleFactor(0.7)
        if let next = entry.next {
          HStack(spacing: 4) {
            Text(entry.arabic ? "باقي" : "in").font(.system(size: 14))
            Text(next, style: .timer).font(.system(size: 14, weight: .semibold))
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

/// Picks the view for the widget size the user placed.
struct PrayerWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry

  var body: some View {
    switch family {
    case .systemMedium:
      PrayerMediumView(entry: entry)
    case .systemSmall:
      PrayerWidgetView(entry: entry)
    default:
      if #available(iOS 16.0, *) {
        PrayerLockView(entry: entry)
          .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
          .environment(\.layoutDirection, entry.arabic ? .rightToLeft : .leftToRight)
      } else {
        PrayerWidgetView(entry: entry)
      }
    }
  }
}

private var families: [WidgetFamily] {
  var f: [WidgetFamily] = [.systemSmall, .systemMedium]
  if #available(iOS 16.0, *) {
    f += [.accessoryRectangular, .accessoryCircular, .accessoryInline]
  }
  return f
}

@main
struct PrayerWidget: Widget {
  let kind = "PrayerWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        PrayerWidgetEntryView(entry: entry).containerBackground(.clear, for: .widget)
      } else {
        PrayerWidgetEntryView(entry: entry)
      }
    }
    .configurationDisplayName("رتّل وصلِّ")
    .description("مواعيد الصلاة والصلاة القادمة · Prayer times and the next prayer")
    .supportedFamilies(families)
  }
}
