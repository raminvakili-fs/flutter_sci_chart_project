
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
        
        self.surface.xAxes.add(items: SCINumericAxis())
        self.surface.yAxes.add(items: SCINumericAxis())
        
        let lineDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        let scatterDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        for i in 0 ..< 200 {
            lineDataSeries.append(x: i, y: sin(Double(i) * 0.1))
            scatterDataSeries.append(x: i, y: cos(Double(i) * 0.1))
        }
        
        let lineSeries = SCIFastLineRenderableSeries()
        lineSeries.dataSeries = lineDataSeries

        let pointMarker = SCIEllipsePointMarker()
        pointMarker.fillStyle = SCISolidBrushStyle(colorCode: 0xFF32CD32)
        pointMarker.size = CGSize(width: 10, height: 10)

        let scatterSeries = SCIXyScatterRenderableSeries()
        scatterSeries.dataSeries = scatterDataSeries
        scatterSeries.pointMarker = pointMarker
        
        SCIUpdateSuspender.usingWith(self.surface) {
//            self.surface.xAxes.add(items: SCINumericAxis())
//            self.surface.yAxes.add(items: SCINumericAxis())
            self.surface.renderableSeries.add(items: lineSeries, scatterSeries)
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
