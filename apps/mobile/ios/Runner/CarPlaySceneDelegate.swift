import CarPlay
import Flutter
import UIKit

/// CarPlay (entitlement com.apple.developer.carplay-audio): a list «أذكار الصباح / أذكار المساء».
/// Picking one starts driving mode in Dart (lib/data/carplay.dart) and opens the car's
/// Now Playing screen, which shows the dhikr and its live count (from audio_service's
/// MPNowPlayingInfoCenter) with play / pause / next / previous.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interface: CPInterfaceController?
  private var list: CPListTemplate?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    interface = interfaceController
    // Starts the engine when CarPlay opens the app before the phone screen.
    _ = (UIApplication.shared.delegate as? AppDelegate)?.engine
    CarPlayChannel.shared.onChange = { [weak self] in self?.render() }
    render()
    CarPlayChannel.shared.ready()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    CarPlayChannel.shared.onChange = nil
    interface = nil
    list = nil
  }

  private func render() {
    guard let interface else { return }
    let channel = CarPlayChannel.shared
    let items: [CPListItem] = channel.items.map { item in
      let row = CPListItem(text: item.title, detailText: item.detail, image: UIImage(systemName: item.icon))
      row.handler = { [weak self] _, completion in
        channel.play(item.id) { message in
          if let message {
            self?.showAlert(message)
          } else {
            self?.showNowPlaying()
          }
          completion()
        }
      }
      return row
    }
    let sections = [CPListSection(items: items)]
    if let list, list.title == channel.title {
      list.updateSections(sections)
    } else {
      let template = CPListTemplate(title: channel.title, sections: sections)
      template.emptyViewTitleVariants = [channel.title]
      list = template
      interface.setRootTemplate(template, animated: false, completion: nil)
    }
  }

  private func showNowPlaying() {
    guard let interface else { return }
    let nowPlaying = CPNowPlayingTemplate.shared
    if interface.topTemplate === nowPlaying { return }
    interface.pushTemplate(nowPlaying, animated: true, completion: nil)
  }

  private func showAlert(_ message: String) {
    guard let interface else { return }
    let ok = CPAlertAction(title: "OK", style: .cancel) { _ in
      interface.dismissTemplate(animated: true, completion: nil)
    }
    interface.presentTemplate(CPAlertTemplate(titleVariants: [message], actions: [ok]), animated: true, completion: nil)
  }
}

/// The method channel to Dart (lib/data/carplay.dart). Dart sends the list whenever it changes;
/// it is kept here so a car that connects later shows it at once.
final class CarPlayChannel {
  static let shared = CarPlayChannel()

  struct Item {
    let id: String
    let title: String
    let detail: String
    let icon: String
  }

  private(set) var title = "رتّل وصلِّ"
  private(set) var items: [Item] = []
  var onChange: (() -> Void)?
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "org.rattil.app/carplay", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "items", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let title = args["title"] as? String { self.title = title }
      self.items = (args["items"] as? [[String: Any]] ?? []).compactMap { e in
        guard let id = e["id"] as? String, let title = e["title"] as? String else { return nil }
        return Item(
          id: id, title: title, detail: e["detail"] as? String ?? "", icon: e["icon"] as? String ?? "car")
      }
      self.onChange?()
      result(nil)
    }
    self.channel = channel
  }

  /// Asks Dart for the list again (it may have been sent before the car connected; harmless twice).
  func ready() {
    channel?.invokeMethod("ready", arguments: nil)
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
}
