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
    let webviewFactory = SciLineChartFactory(controller: controller)

    registrar(forPlugin: "SciLineChart").register(webviewFactory, withId: "SciLineChart")

    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
