
import Foundation
import UIKit
import WebKit
import SciChart

public class MyWebview: NSObject, FlutterPlatformView, WKScriptMessageHandler, WKNavigationDelegate {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        //
        
    }
    
    let frame: CGRect
    let viewId: Int64
    let channel: FlutterMethodChannel
    let webview: WKWebView
    
    var surface: SCIChartSurface
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
        
        let config = WKWebViewConfiguration()
        let webview = WKWebView(frame: frame, configuration: config)

        self.webview = webview
        
        SCIChartSurface.setRuntimeLicenseKey(licenseKey)

        self.surface = SCIChartSurface()
        
        super.init()
        
        
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "loadUrl") {
                let url = call.arguments as! String
                webview.load(URLRequest(url: URL(string: url)!))
            }
        })
    }
    
    
    public func view() -> UIView {
        self.surface.xAxes.add(items: SCINumericAxis())
        self.surface.yAxes.add(items: SCINumericAxis())
        return self.surface
    }
}
