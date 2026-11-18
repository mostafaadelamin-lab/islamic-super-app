import Flutter
import UIKit

/// The phone screen. It shows the app's one engine (AppDelegate.engine), which may already be
/// running because CarPlay started the app first.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? AppDelegate {
      let controller = FlutterViewController(engine: app.engine, nibName: nil, bundle: nil)
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = controller
      self.window = window
      window.makeKeyAndVisible()
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
