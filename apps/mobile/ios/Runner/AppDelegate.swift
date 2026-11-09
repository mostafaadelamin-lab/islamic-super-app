import CoreLocation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var heading: HeadingStreamHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets adhan notifications (flutter_local_notifications) show while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Qibla compass heading channel (HeadingStreamHandler.swift).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RattilHeading") {
      heading = HeadingStreamHandler.register(with: registrar.messenger())
    }
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
    if newHeading.headingAccuracy < 0 { return }
    sink?(newHeading.magneticHeading)
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
