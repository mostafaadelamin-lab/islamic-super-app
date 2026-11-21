import AVFoundation
import CoreLocation
import Flutter
import UIKit
import UserNotifications
#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var heading: HeadingStreamHandler?

  /// One Flutter engine for the phone screen and CarPlay. CarPlay can start the app with the
  /// phone locked and no phone screen at all, so the engine runs on its own (headless) and the
  /// phone screen, when it opens, shows the same engine (SceneDelegate). Driving mode then keeps
  /// playing and counting whichever screen started it.
  lazy var engine: FlutterEngine = {
    let engine = FlutterEngine(name: "rattil", project: nil, allowHeadlessExecution: true)
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)
    // Qibla compass heading channel (HeadingStreamHandler below).
    if let registrar = engine.registrar(forPlugin: "RattilHeading") {
      heading = HeadingStreamHandler.register(with: registrar.messenger())
    }
    // CarPlay list (CarPlaySceneDelegate.swift).
    CarPlayChannel.shared.attach(engine.binaryMessenger)
    // Full adhan on iPhone: the recording cut into notification sounds, and iOS 26 alarms (AdhanNative below).
    AdhanNative.attach(engine.binaryMessenger)
    return engine
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets adhan notifications (flutter_local_notifications) show while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    _ = engine
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


/// Qibla compass: streams the iPhone's heading (degrees clockwise from MAGNETIC north) from
/// CLLocationManager, which is calibrated and fused by iOS. Magnetic heading needs no location
/// permission; the Dart side adds the magnetic declination (WMM2025) to get true north.
final class HeadingStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  static func register(with messenger: FlutterBinaryMessenger) -> HeadingStreamHandler {
    let handler = HeadingStreamHandler()
    FlutterEventChannel(name: "org.rattil.app/heading", binaryMessenger: messenger).setStreamHandler(handler)
    return handler
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      return FlutterError(code: "no_sensor", message: "Heading not available", details: nil)
    }
    sink = events
    manager.delegate = self
    manager.headingFilter = 1
    manager.headingOrientation = .portrait
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    // Negative accuracy means the reading is invalid (interference / not calibrated).
    if newHeading.headingAccuracy < 0 {
      sink?(["cal": 0])
      return
    }
    sink?(["acc": newHeading.headingAccuracy])
    sink?(newHeading.magneticHeading)
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}


/// Full adhan on iPhone (lib/data/notifications.dart, AdhanRing). iOS plays at most 30 s of a notification
/// sound (a longer file plays the default sound instead), so the muezzin's recording is cut into parts of at
/// most 29 s, each ending at a pause between the adhan's phrases, and saved as Library/Sounds/
/// rattil_adhan_<voice>_<k>.caf; Dart rings them as notifications back to back. The whole recording is also
/// saved (rattil_adhan_<voice>_full.caf) for the iOS 26 alarm (AlarmKit), which rings it even on silent.
enum AdhanNative {
  static let channelName = "org.rattil.app/adhan"
  /// Raise when the cutting changes, so old parts are made again.
  static let version = 1
  static let maxPart = 29.0
  static let minPart = 15.0
  static let maxParts = 12
  private static let queue = DispatchQueue(label: "org.rattil.adhan.parts", qos: .utility)

  static func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "prepareParts":
        guard let voice = args["voice"] as? String, let url = sourceURL(args) else {
          result([Int]())
          return
        }
        queue.async {
          let parts = (try? prepare(source: url, voice: voice)) ?? []
          DispatchQueue.main.async { result(parts) }
        }
      case "cancelAll":
        AdhanAlarms.cancelAll { result(nil) }
      case "alarmState":
        AdhanAlarms.state { result($0) }
      case "alarmRequest":
        AdhanAlarms.request { result($0) }
      case "alarmSchedule":
        AdhanAlarms.schedule(args) { result($0) }
      case "takeAlarmTap":
        let d = UserDefaults.standard
        let tap = d.string(forKey: AdhanAlarms.tapKey)
        d.removeObject(forKey: AdhanAlarms.tapKey)
        result(tap)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// A bundled Flutter asset ("asset") or a downloaded file ("path").
  private static func sourceURL(_ args: [String: Any]) -> URL? {
    if let asset = args["asset"] as? String {
      let key = FlutterDartProject.lookupKey(forAsset: asset)
      guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return nil }
      return URL(fileURLWithPath: path)
    }
    if let path = args["path"] as? String, FileManager.default.fileExists(atPath: path) {
      return URL(fileURLWithPath: path)
    }
    return nil
  }

  static var soundsDir: URL {
    FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Sounds", isDirectory: true)
  }

  static func partURL(_ voice: String, _ k: Int) -> URL {
    soundsDir.appendingPathComponent("rattil_adhan_\(voice)_\(k).caf")
  }

  static func fullURL(_ voice: String) -> URL {
    soundsDir.appendingPathComponent("rattil_adhan_\(voice)_full.caf")
  }

  /// Cuts [source] into parts (once; a small JSON next to them remembers the lengths) and returns the
  /// length of each part in whole seconds.
  static func prepare(source: URL, voice: String) throws -> [Int] {
    let fm = FileManager.default
    try fm.createDirectory(at: soundsDir, withIntermediateDirectories: true)
    let manifest = soundsDir.appendingPathComponent("rattil_adhan_\(voice).json")
    let size = ((try? fm.attributesOfItem(atPath: source.path))?[.size] as? NSNumber)?.intValue ?? 0
    if let data = try? Data(contentsOf: manifest),
       let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       m["v"] as? Int == version, m["size"] as? Int == size,
       let parts = m["parts"] as? [Int], !parts.isEmpty,
       parts.indices.allSatisfy({ fm.fileExists(atPath: partURL(voice, $0).path) }),
       fm.fileExists(atPath: fullURL(voice).path) {
      return parts
    }

    // Decode to mono floats (about 22 kHz is plenty for a voice and keeps the files small).
    let input = try AVAudioFile(forReading: source)
    let fmt = input.processingFormat
    let channels = Int(fmt.channelCount)
    let step = fmt.sampleRate >= 32000 ? 2 : 1
    let rate = fmt.sampleRate / Double(step)
    var mono = [Float]()
    mono.reserveCapacity(Int(input.length) / step + 1)
    let chunk: AVAudioFrameCount = 1 << 16
    guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: chunk) else { return [] }
    var carry: Float = 0
    var carried = 0
    while input.framePosition < input.length {
      try input.read(into: buf, frameCount: chunk)
      let n = Int(buf.frameLength)
      if n == 0 { break }
      guard let data = buf.floatChannelData else { return [] }
      for i in 0..<n {
        var v: Float = 0
        for c in 0..<channels { v += data[c][i] }
        carry += v / Float(channels)
        carried += 1
        if carried == step {
          mono.append(carry / Float(step))
          carry = 0
          carried = 0
        }
      }
    }
    if mono.isEmpty { return [] }

    // Loudness of every 50 ms, to cut where the muezzin pauses.
    let win = max(1, Int(rate * 0.05))
    var energy = [Float]()
    var i = 0
    while i < mono.count {
      let end = min(mono.count, i + win)
      var e: Float = 0
      for j in i..<end { e += mono[j] * mono[j] }
      energy.append(e / Float(end - i))
      i = end
    }
    func quiet(at second: Double) -> Float {
      // Mean loudness of the half second around [second].
      let c = Int(second / 0.05)
      let lo = max(0, c - 5), hi = min(energy.count - 1, c + 5)
      if lo > hi { return 0 }
      var e: Float = 0
      for k in lo...hi { e += energy[k] }
      return e / Float(hi - lo + 1)
    }

    let total = Double(mono.count) / rate
    var cuts = [Int]()  // whole seconds where each part starts
    var start = 0
    while true {
      cuts.append(start)
      let left = total - Double(start)
      if left <= maxPart || cuts.count == maxParts { break }
      var best = start + Int(maxPart)
      var bestE = Float.greatestFiniteMagnitude
      var s = start + Int(minPart)
      while s <= start + Int(maxPart) {
        let e = quiet(at: Double(s))
        if e < bestE {
          bestE = e
          best = s
        }
        s += 1
      }
      start = best
    }

    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatAppleIMA4,
      AVSampleRateKey: rate,
      AVNumberOfChannelsKey: 1,
    ]
    func write(_ url: URL, from: Int, to: Int) throws {
      try? fm.removeItem(at: url)
      guard let outFmt = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1),
            let out = AVAudioPCMBuffer(pcmFormat: outFmt, frameCapacity: AVAudioFrameCount(max(1, to - from))),
            let dst = out.floatChannelData?[0] else { return }
      let n = to - from
      let fade = min(n / 2, Int(rate * 0.04))
      for j in 0..<n {
        var v = mono[from + j]
        if j < fade { v *= Float(j) / Float(fade) }
        if j >= n - fade { v *= Float(n - 1 - j) / Float(fade) }
        dst[j] = v
      }
      out.frameLength = AVAudioFrameCount(n)
      let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
      try file.write(from: out)
    }

    var parts = [Int]()
    for (k, c) in cuts.enumerated() {
      let from = Int(Double(c) * rate)
      let isLast = k == cuts.count - 1
      let endSec = isLast ? min(total, Double(c) + maxPart) : Double(cuts[k + 1])
      let to = min(mono.count, Int(endSec * rate))
      if to <= from { break }
      try write(partURL(voice, k), from: from, to: to)
      parts.append(isLast ? Int(ceil(endSec - Double(c))) : cuts[k + 1] - c)
    }
    try write(fullURL(voice), from: 0, to: mono.count)
    let info: [String: Any] = ["v": version, "size": size, "parts": parts]
    if let data = try? JSONSerialization.data(withJSONObject: info) { try? data.write(to: manifest) }
    return parts
  }
}

/// iOS 26+ (AlarmKit): the adhan rings as a system alarm with the whole recording, even on silent, with a
/// stop button and a button that opens the app to continue the adhan there. Older iOS answers "unavailable".
enum AdhanAlarms {
  static let tapKey = "rattil.adhanAlarmTap"
  static let idsKey = "rattil.adhanAlarmIds"
  static let payloadsKey = "rattil.adhanAlarmPayloads"

  static func uuid(_ id: Int) -> UUID {
    UUID(uuidString: String(format: "52415454-494c-4144-4841-%012ld", id % 1_000_000_000_000)) ?? UUID()
  }

  static func state(_ done: @escaping (String) -> Void) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      Task { @MainActor in
        let st = await AlarmManager.shared.authorizationState
        done(st == .authorized ? "authorized" : st == .notDetermined ? "notDetermined" : "denied")
      }
      return
    }
    #endif
    done("unavailable")
  }

  static func request(_ done: @escaping (String) -> Void) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      Task { @MainActor in
        do {
          let st = try await AlarmManager.shared.requestAuthorization()
          done(st == .authorized ? "authorized" : st == .notDetermined ? "notDetermined" : "denied")
        } catch {
          done("denied")
        }
      }
      return
    }
    #endif
    done("unavailable")
  }

  static func cancelAll(_ done: @escaping () -> Void) {
    let d = UserDefaults.standard
    let ids = d.array(forKey: idsKey) as? [String] ?? []
    d.removeObject(forKey: idsKey)
    d.removeObject(forKey: payloadsKey)
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *), !ids.isEmpty {
      Task { @MainActor in
        for s in ids {
          if let id = UUID(uuidString: s) { try? await AlarmManager.shared.cancel(id: id) }
        }
        done()
      }
      return
    }
    #endif
    done()
  }

  static func schedule(_ args: [String: Any], _ done: @escaping (Any?) -> Void) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      guard let id = args["id"] as? Int, let at = args["atMillis"] as? NSNumber else {
        done(FlutterError(code: "args", message: "id/atMillis missing", details: nil))
        return
      }
      let title = args["title"] as? String ?? ""
      let sound = args["sound"] as? String ?? ""
      let stopLabel = args["stopLabel"] as? String ?? "Stop"
      let openLabel = args["openLabel"] as? String ?? "Open"
      let payload = args["payload"] as? String ?? ""
      let alarmId = uuid(id)
      let date = Date(timeIntervalSince1970: at.doubleValue / 1000)
      Task { @MainActor in
        do {
          let stop = AlarmButton(text: LocalizedStringResource(stringLiteral: stopLabel), textColor: .white, systemImageName: "stop.fill")
          let open = AlarmButton(text: LocalizedStringResource(stringLiteral: openLabel), textColor: .white, systemImageName: "speaker.wave.2.fill")
          let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stop,
            secondaryButton: open,
            secondaryButtonBehavior: .custom
          )
          let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: AdhanAlarmMetadata(),
            tintColor: Color(red: 0.55, green: 0.4, blue: 0.2)
          )
          let config = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: .fixed(date),
            attributes: attributes,
            secondaryIntent: ContinueAdhanIntent(alarmId: alarmId.uuidString),
            sound: sound.isEmpty ? .default : .named(sound)
          )
          _ = try await AlarmManager.shared.schedule(id: alarmId, configuration: config)
          let d = UserDefaults.standard
          var ids = d.array(forKey: idsKey) as? [String] ?? []
          ids.append(alarmId.uuidString)
          d.set(ids, forKey: idsKey)
          var payloads = d.dictionary(forKey: payloadsKey) as? [String: String] ?? [:]
          payloads[alarmId.uuidString] = payload
          d.set(payloads, forKey: payloadsKey)
          done(nil)
        } catch {
          done(FlutterError(code: "alarm", message: "\(error)", details: nil))
        }
      }
      return
    }
    #endif
    done(FlutterError(code: "unavailable", message: "AlarmKit needs iOS 26", details: nil))
  }

}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct AdhanAlarmMetadata: AlarmMetadata {
  init() {}
}

/// The alarm's "continue in app" button: opens the app, which plays the rest of the adhan
/// (Dart asks for the tap with "takeAlarmTap").
@available(iOS 26.0, *)
struct ContinueAdhanIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Continue the adhan"
  static let openAppWhenRun: Bool = true

  @Parameter(title: "Alarm")
  var alarmId: String

  init() {}

  init(alarmId: String) {
    self.alarmId = alarmId
  }

  func perform() async throws -> some IntentResult {
    let d = UserDefaults.standard
    let payloads = d.dictionary(forKey: AdhanAlarms.payloadsKey) as? [String: String] ?? [:]
    if let p = payloads[alarmId] { d.set(p, forKey: AdhanAlarms.tapKey) }
    return .result()
  }
}
#endif
