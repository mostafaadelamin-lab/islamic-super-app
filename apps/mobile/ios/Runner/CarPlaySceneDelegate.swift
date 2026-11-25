import CarPlay
import Flutter
import UIKit

/// CarPlay (entitlement com.apple.developer.carplay-audio): the app's lists on the car screen.
/// The first list has «أذكار الصباح / أذكار المساء» (driving mode) and the listening sections
/// (radio, recitation library, al-Sha'rawi, «افهم دينك», «علّم طفلك», nasheeds; owner 2026-11-23/25).
/// A section opens its own list (asked from Dart: lib/data/carplay.dart); picking an item plays
/// it in Dart and opens the car's Now Playing screen, which shows the title / artist the lock
/// screen shows (audio_service's MPNowPlayingInfoCenter) with play / pause / next / previous.
/// In driving mode the Now Playing screen also has a «نص الذكر» button: the whole dhikr in lines.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPNowPlayingTemplateObserver {
  private var interface: CPInterfaceController?
  private var root: CPListTemplate?
  private var observing = false

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    interface = interfaceController
    // Starts the engine when CarPlay opens the app before the phone screen.
    _ = (UIApplication.shared.delegate as? AppDelegate)?.engine
    CarPlayChannel.shared.onChange = { [weak self] in self?.render() }
    CarPlayChannel.shared.onTextButton = { [weak self] in self?.updateTextButton() }
    if !observing {
      CPNowPlayingTemplate.shared.add(self)
      observing = true
    }
    updateTextButton()
    render()
    CarPlayChannel.shared.ready()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    CarPlayChannel.shared.onChange = nil
    CarPlayChannel.shared.onTextButton = nil
    if observing {
      CPNowPlayingTemplate.shared.remove(self)
      observing = false
    }
    interface = nil
    root = nil
  }

  // MARK: Lists

  private func render() {
    guard let interface else { return }
    let channel = CarPlayChannel.shared
    let sections = makeSections(channel.items)
    if let root, root.title == channel.title {
      root.updateSections(sections)
    } else {
      let template = CPListTemplate(title: channel.title, sections: sections)
      template.emptyViewTitleVariants = [channel.title]
      root = template
      interface.setRootTemplate(template, animated: false, completion: nil)
    }
  }

  /// Rows grouped by their 'section' (a long list, e.g. the reciters, gets an index on the side),
  /// within the number of rows the car allows.
  private func makeSections(_ items: [CarPlayChannel.Item]) -> [CPListSection] {
    let rows = Array(items.prefix(Int(CPListTemplate.maximumItemCount)))
    var groups: [(String?, [CPListItem])] = []
    for item in rows {
      let row = makeRow(item)
      if let last = groups.last, last.0 == item.section {
        groups[groups.count - 1].1.append(row)
      } else {
        groups.append((item.section, [row]))
      }
    }
    let sections = groups.prefix(Int(CPListTemplate.maximumSectionCount)).map { group -> CPListSection in
      if let title = group.0 {
        // A letter (the reciters) also goes in the index on the side; a longer title is only a header.
        return CPListSection(items: group.1, header: title, sectionIndexTitle: title.count <= 2 ? title : nil)
      }
      return CPListSection(items: group.1)
    }
    return sections.isEmpty ? [CPListSection(items: [])] : sections
  }

  private func makeRow(_ item: CarPlayChannel.Item) -> CPListItem {
    let row = CPListItem(
      text: item.title, detailText: item.detail.isEmpty ? nil : item.detail,
      image: UIImage(systemName: item.icon) ?? UIImage(systemName: "play.circle"))
    if item.browsable {
      row.accessoryType = .disclosureIndicator
      row.handler = { [weak self] _, completion in
        CarPlayChannel.shared.children(item.id) { title, items in
          self?.pushList(title: title.isEmpty ? item.title : title, items: items)
          completion()
        }
      }
    } else {
      row.handler = { [weak self] _, completion in
        CarPlayChannel.shared.play(item.id) { message in
          if let message {
            self?.showAlert(message)
          } else {
            self?.showNowPlaying()
          }
          completion()
        }
      }
    }
    return row
  }

  private func pushList(title: String, items: [CarPlayChannel.Item]) {
    guard let interface else { return }
    let template = CPListTemplate(title: title, sections: makeSections(items))
    template.emptyViewTitleVariants = [title]
    interface.pushTemplate(template, animated: true, completion: nil)
  }

  // MARK: Now Playing and the dhikr text

  private func showNowPlaying() {
    guard let interface else { return }
    let nowPlaying = CPNowPlayingTemplate.shared
    if interface.topTemplate === nowPlaying { return }
    interface.pushTemplate(nowPlaying, animated: true, completion: nil)
  }

  private func updateTextButton() {
    let channel = CarPlayChannel.shared
    let nowPlaying = CPNowPlayingTemplate.shared
    nowPlaying.upNextTitle = channel.textTitle
    nowPlaying.isUpNextButtonEnabled = channel.textOn
  }

  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    CarPlayChannel.shared.text { [weak self] title, lines in
      guard let self, let interface = self.interface, !lines.isEmpty else { return }
      // The whole dhikr, one short line per row (a car shows every row on one line).
      let rows = lines.prefix(Int(CPListTemplate.maximumItemCount)).map { line -> CPListItem in
        CPListItem(text: line, detailText: nil)
      }
      let template = CPListTemplate(title: title, sections: [CPListSection(items: Array(rows))])
      interface.pushTemplate(template, animated: true, completion: nil)
    }
  }

  func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}

  private func showAlert(_ message: String) {
    guard let interface else { return }
    let ok = CPAlertAction(title: "OK", style: .cancel) { _ in
      interface.dismissTemplate(animated: true, completion: nil)
    }
    interface.presentTemplate(CPAlertTemplate(titleVariants: [message], actions: [ok]), animated: true, completion: nil)
  }
}

/// The method channel to Dart (lib/data/carplay.dart). Dart sends the first list whenever it
/// changes; it is kept here so a car that connects later shows it at once. Other lists are asked
/// for when a section is opened.
final class CarPlayChannel {
  static let shared = CarPlayChannel()

  struct Item {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let browsable: Bool
    let section: String?
  }

  private(set) var title = "رتّل وصلِّ"
  private(set) var items: [Item] = []
  private(set) var textTitle = "نص الذكر"
  private(set) var textOn = false
  var onChange: (() -> Void)?
  var onTextButton: (() -> Void)?
  private var channel: FlutterMethodChannel?

  static func parse(_ list: Any?) -> [Item] {
    return (list as? [[String: Any]] ?? []).compactMap { e in
      guard let id = e["id"] as? String, let title = e["title"] as? String else { return nil }
      return Item(
        id: id, title: title, detail: e["detail"] as? String ?? "", icon: e["icon"] as? String ?? "play.circle",
        browsable: e["browsable"] as? Bool ?? false, section: e["section"] as? String)
    }
  }

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "org.rattil.app/carplay", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "items":
        if let title = args["title"] as? String { self.title = title }
        self.items = CarPlayChannel.parse(args["items"])
        self.onChange?()
      case "textButton":
        if let title = args["title"] as? String { self.textTitle = title }
        self.textOn = args["on"] as? Bool ?? false
        self.onTextButton?()
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
    }
    self.channel = channel
  }

  /// Asks Dart for the first list again (it may have been sent before the car connected).
  func ready() {
    channel?.invokeMethod("ready", arguments: nil)
  }

  /// The list under [id] (a section, a reciter, a surah of al-Sha'rawi...).
  func children(_ id: String, done: @escaping (String, [Item]) -> Void) {
    guard let channel else {
      done("", [])
      return
    }
    channel.invokeMethod("children", arguments: id) { reply in
      let map = reply as? [String: Any] ?? [:]
      let title = map["title"] as? String ?? ""
      let items = CarPlayChannel.parse(map["items"])
      DispatchQueue.main.async { done(title, items) }
    }
  }

  /// Starts [id] in Dart. [done] gets nil when it plays, or the message to show.
  func play(_ id: String, done: @escaping (String?) -> Void) {
    guard let channel else {
      done(nil)
      return
    }
    channel.invokeMethod("play", arguments: id) { reply in
      // A String is the message to show; nil (or an error from the Dart side) means playing.
      DispatchQueue.main.async { done(reply as? String) }
    }
  }

  /// The current dhikr's whole text in short lines (driving mode).
  func text(done: @escaping (String, [String]) -> Void) {
    guard let channel else { return }
    channel.invokeMethod("text", arguments: nil) { reply in
      let map = reply as? [String: Any] ?? [:]
      let title = map["title"] as? String ?? self.textTitle
      let lines = map["lines"] as? [String] ?? []
      DispatchQueue.main.async { done(title, lines) }
    }
  }
}
