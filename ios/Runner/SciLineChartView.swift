
import Foundation
import UIKit
import WebKit
import SciChart

public class SciLineChartView: NSObject, FlutterPlatformView, WKScriptMessageHandler, WKNavigationDelegate {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){}
    
    let frame: CGRect
    let viewId: Int64
    let channel: FlutterMethodChannel
    
    var surface: SCIChartSurface
    
    private let pointsCount = 200
    private var timer: Timer!

    private let lineData = SCIDoubleValues()
    private lazy var lineDataSeries: SCIXyDataSeries = {
        let lineDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        lineDataSeries.seriesName = "Line Series"
        return lineDataSeries
    }()
    private let scatterData = SCIDoubleValues()
    private lazy var scatterDataSeries: SCIXyDataSeries = {
        let scatterDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        scatterDataSeries.seriesName = "Scatter Series"
        return scatterDataSeries
    }()
    
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
        
        
        SCIChartSurface.setRuntimeLicenseKey(licenseKey)

        self.surface = SCIChartSurface()
        
        super.init()
        
        // Adding Axes to the surface
        self.surface.xAxes.add(items: SCINumericAxis())
        self.surface.yAxes.add(items: SCINumericAxis())
        
        // Creating data series and filling them with mock values
        let lineDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        
        for i in 0 ..< 20 {
            lineDataSeries.append(x: i, y: Double.random(in: 1...100))
        }
        
        // Creating renderable series and give them data series
        let lineSeries = SCIFastLineRenderableSeries()
        lineSeries.dataSeries = lineDataSeries
        
        // Adding chart modifiers to surface
        self.surface.chartModifiers.add(items: SCIPinchZoomModifier(), SCIZoomPanModifier(), SCIZoomExtentsModifier())
        
        SCIUpdateSuspender.usingWith(self.surface) {
            self.surface.renderableSeries.add(items: lineSeries)
        }
        
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "loadUrl") {
                // let url = call.arguments as! String
                // Do something!
            }
        })
    }
    
    
    public func view() -> UIView {
        return self.surface
    }
}
