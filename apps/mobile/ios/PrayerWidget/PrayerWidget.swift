// Widgets for iOS (WidgetKit):
// - small (home screen) and lock screen (owner 2026-11-22, no circle): three lines, the next
//   prayer, its time and the countdown;
// - medium (home screen, layout from the owner's screenshot 2026-11-22): the six times with
//   the next prayer in gold on one side, and a panel with the day name, the Hijri and
//   Gregorian dates, the next prayer and its countdown on the other.
// Colours: the user's colour style in the app ("pal": madinah by default, or emerald).
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
  var palette: String = "madinah"
  /// Between the adhan of [nextKey] and its iqama: [next] is the iqama (owner 2026-11-22).
  var iqama: Bool = false
}

private struct Payload: Decodable {
  struct Day: Decodable {
    let d: String
    let h: String
    let p: [[Value]]
    let sr: Double?
    /// Iqama instants (ms), same order as [p]; absent when the iqama alert is off.
    let iq: [Double]?
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
  let pal: String?
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

  /// Between an adhan and its iqama at [date]: (prayer name, iqama time, adhan time, key).
  private func iqamaWait(_ p: Payload, at date: Date) -> (String, Date, Date, String)? {
    for d in p.days {
      guard let iq = d.iq, iq.count == d.p.count else { continue }
      for (j, e) in d.p.enumerated() where e.count == 3 {
        if case .s(let key) = e[0], case .s(let name) = e[1], case .n(let ms) = e[2] {
          let adhan = Date(timeIntervalSince1970: ms / 1000)
          let at = Date(timeIntervalSince1970: iq[j] / 1000)
          if adhan <= date && date < at { return (name, at, adhan, key) }
        }
      }
    }
    return nil
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
    if let w = iqamaWait(p, at: date) {
      return PrayerEntry(
        date: date, hijri: hijri, name: (arabic ? "إقامة " : "Iqama ") + w.0, next: w.1, previous: w.2,
        arabic: arabic, nextKey: w.3, today: six(todayDay, arabic: arabic), clock12: p.c12 ?? true,
        palette: p.pal ?? "madinah", iqama: true)
    }
    return PrayerEntry(
      date: date, hijri: hijri, name: next?.0 ?? "", next: next?.1, previous: prev, arabic: arabic,
      nextKey: next?.3 ?? "", today: six(todayDay, arabic: arabic), clock12: p.c12 ?? true,
      palette: p.pal ?? "madinah")
  }

  func placeholder(in context: Context) -> PrayerEntry { entry(at: Date(), nil) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(entry(at: Date(), load()))
  }

  /// One entry now, one every hour for 6 hours (the date changes at midnight) and one at each
  /// prayer (the next prayer and the gold highlight move). The countdowns run by themselves.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let p = load()
    let now = Date()
    var dates = (0..<7).map { now.addingTimeInterval(Double($0) * 3600) }
    if let p = p {
      dates += prayers(p).map { $0.1 }.filter { $0 > now && $0 < now.addingTimeInterval(6 * 3600) }
      let iqamas = p.days.flatMap { $0.iq ?? [] }.map { Date(timeIntervalSince1970: $0 / 1000) }
      dates += iqamas.filter { $0 > now && $0 < now.addingTimeInterval(6 * 3600) }
    }
    let entries = dates.sorted().map { entry(at: $0, p) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

/// Small home-screen widget and the lock-screen widgets: the next prayer, its time and the countdown.
struct PrayerNextView: View {
  let entry: PrayerEntry
  /// Home screen: our colours; lock screen: the system tints the text, no background.
  var home: Bool = false

  var body: some View {
    let style = Style(entry.palette)
    VStack(spacing: home ? 2 : 0) {
      Text(entry.name).font(.system(size: home ? 16 : 13)).lineLimit(1).minimumScaleFactor(0.7)
        .opacity(home ? 0.9 : 1)
      if let next = entry.next {
        Text(clock(next, entry)).font(.system(size: home ? 24 : 16, weight: .bold)).lineLimit(1)
          .minimumScaleFactor(0.6)
        Text(next, style: .timer).font(.system(size: home ? 18 : 15)).monospacedDigit()
          .multilineTextAlignment(.center).lineLimit(1).minimumScaleFactor(0.6)
          .foregroundColor(home ? style.gold : nil)
      } else {
        Text(entry.arabic ? "افتح التطبيق" : "Open the app").font(.system(size: 12))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundColor(home ? Color.white : nil)
    .padding(home ? 8 : 0)
    .modifier(OldBackground(style: style, on: home))
  }
}

/// The colour style's two background colours (heroTop, heroDeep) and its gold, from design_tokens.dart.
private struct Style {
  let top: Color
  let deep: Color
  let gold: Color
  init(_ id: String) {
    if id == "emerald" {
      top = Color(red: 0x0F / 255, green: 0x6B / 255, blue: 0x50 / 255)
      deep = Color(red: 0x06 / 255, green: 0x2E / 255, blue: 0x23 / 255)
      gold = Color(red: 0xD4 / 255, green: 0xAF / 255, blue: 0x5A / 255)
    } else {
      top = Color(red: 0x1D / 255, green: 0x3A / 255, blue: 0x64 / 255)
      deep = Color(red: 0x0A / 255, green: 0x18 / 255, blue: 0x30 / 255)
      gold = Color(red: 0xD9 / 255, green: 0xB2 / 255, blue: 0x5E / 255)
    }
  }
  var background: LinearGradient {
    LinearGradient(colors: [top, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

/// "5:22 ص" / "5:22 AM" (12 h) or "05:22" (24 h), with Arabic digits in Arabic.
private func clock(_ d: Date, _ e: PrayerEntry, suffix: Bool = true) -> String {
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

/// Before iOS 17 the view draws its own background; from iOS 17 the widget's container background
/// does (see PrayerWidget below), so it fills the whole widget.
private struct OldBackground: ViewModifier {
  let style: Style
  let on: Bool
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content
    } else if on {
      content.background(style.background)
    } else {
      content
    }
  }
}

/// iOS 17+: the colour style on the home screen, nothing on the lock screen.
struct PrayerContainerBackground: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry
  var body: some View {
    switch family {
    case .systemSmall, .systemMedium:
      Style(entry.palette).background
    default:
      Color.clear
    }
  }
}

/// Wide home-screen widget: the six times (the next one in gold) and the day panel.
struct PrayerMediumView: View {
  let entry: PrayerEntry

  var body: some View {
    let style = Style(entry.palette)
    HStack(spacing: 8) {
      VStack(spacing: 0) {
        ForEach(Array(entry.today.enumerated()), id: \.offset) { _, t in
          let on = t.key == entry.nextKey
            && (entry.iqama || entry.next.map { abs($0.timeIntervalSince(t.at)) < 1 } == true)
          HStack {
            Text(t.name).lineLimit(1)
            Spacer(minLength: 4)
            Text(clock(t.at, entry)).lineLimit(1)
          }
          .font(.system(size: 14, weight: on ? .bold : .regular))
          .minimumScaleFactor(0.7)
          .foregroundColor(on ? style.gold : .white)
          .frame(maxHeight: .infinity)
        }
      }
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity)
      VStack(spacing: 2) {
        Text(dateText(entry.date, "EEEE", arabic: entry.arabic)).font(.system(size: 15, weight: .bold))
        Text(arabicDigits(entry.hijri, entry.arabic) + (entry.arabic ? " هـ" : " AH")).font(.system(size: 12))
          .opacity(0.85)
        Text(dateText(entry.date, "d MMMM yyyy", arabic: entry.arabic)).font(.system(size: 12)).opacity(0.85)
        if let next = entry.next {
          Text(entry.name).font(.system(size: 14, weight: .bold)).padding(.top, 8)
          Text(next, style: .timer).font(.system(size: 20, weight: .bold)).monospacedDigit()
            .foregroundColor(style.gold).multilineTextAlignment(.center)
        }
      }
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .padding(6)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.09)))
    }
    .foregroundColor(.white)
    .padding(10)
    .modifier(OldBackground(style: style, on: true))
    .environment(\.layoutDirection, entry.arabic ? .rightToLeft : .leftToRight)
    .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
  }
}

/// Lock-screen widgets (iOS 16+), owner 2026-11-22: plain text, no circle.
@available(iOS 16.0, *)
struct PrayerLockView: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry

  var body: some View {
    switch family {
    case .accessoryInline:
      Text("\(entry.name) \(entry.next.map { clock($0, entry) } ?? "")")
    default:
      PrayerNextView(entry: entry)
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
      PrayerNextView(entry: entry, home: true)
        .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
    default:
      if #available(iOS 16.0, *) {
        PrayerLockView(entry: entry)
          .environment(\.locale, Locale(identifier: entry.arabic ? "ar" : "en"))
          .environment(\.layoutDirection, entry.arabic ? .rightToLeft : .leftToRight)
      } else {
        PrayerNextView(entry: entry, home: true)
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
        PrayerWidgetEntryView(entry: entry).containerBackground(for: .widget) {
          PrayerContainerBackground(entry: entry)
        }
      } else {
        PrayerWidgetEntryView(entry: entry)
      }
    }
    .configurationDisplayName("رتّل وصلِّ")
    .description("مواعيد الصلاة والصلاة القادمة · Prayer times and the next prayer")
    .supportedFamilies(families)
  }
}
