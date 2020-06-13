import Foundation
import UIKit
import WebKit
import SciChart

public class SciCandleChartView: NSObject, FlutterPlatformView, WKScriptMessageHandler, WKNavigationDelegate {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){}
    
    let frame: CGRect
    let viewId: Int64
    let channel: FlutterMethodChannel
    let stockChartView: RealtimeTickingStockChartView
    
    var surface: SCIChartSurface
    
    
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
    
        
        SCIChartSurface.setRuntimeLicenseKey(licenseKey)

        self.surface = SCIChartSurface()
        self.stockChartView = RealtimeTickingStockChartView(surface: self.surface)
        
        super.init()
        
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "loadUrl") {
                // let url = call.arguments as! String
                // Do something!
                self.stockChartView.changeSeriesType(call.arguments as! String)
            }
        })
    }
    
    
    public func view() -> UIView {
        return self.surface
    }
}
