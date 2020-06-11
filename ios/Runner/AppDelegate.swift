import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    let webviewFactory = WebviewFactory(controller: controller)

    registrar(forPlugin: "webview").register(webviewFactory, withId: "webview")

    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
