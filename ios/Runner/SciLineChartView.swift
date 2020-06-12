
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
    
    private let initialPoints = 50
    
    private var value : Double = 50
    private var timer: Timer!

    private let lineValues = SCIDoubleValues()
    private lazy var lineDataSeries: SCIXyDataSeries = {
        let lineDataSeries = SCIXyDataSeries(xType: .int, yType: .double)
        lineDataSeries.seriesName = "Line Series"
        return lineDataSeries
    }()
    
    private let xAxis = SCINumericAxis()
    
    
    @objc fileprivate func updateData(_ timer: Timer) {
        let x = lineDataSeries.count
        SCIUpdateSuspender.usingWith(surface) {
            self.updateValue()
            self.lineDataSeries.append(x: x, y: self.value)

            // zoom series to fit viewport size into X-Axis direction
            self.surface.animateZoomExtents(withDuration: 0.5)
        }
    }
    
    private func updateValue() -> Void {
        self.value = Bool.random() ? self.value + Double.random(in: 0...4) : self.value - Double.random(in: 0...4)
    }
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
    
        
        SCIChartSurface.setRuntimeLicenseKey(licenseKey)

        self.surface = SCIChartSurface()
        
        super.init()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        
        // Adding Axes to the surface
        // xAxis.visibleRange = SCIIntegerRange(min: 0, max: Int32(initialPoints))
        
        self.surface.xAxes.add(items: xAxis)
        self.surface.yAxes.add(items: SCINumericAxis())
        
        // Using [SCIValues] for better performance according to SciChart documentation
        let xValues = SCIIntegerValues()
        for i in 0 ..< initialPoints {
            xValues.add(Int32(i))
            self.updateValue()
            lineValues.add(self.value)
        }
        lineDataSeries.append(x: xValues, y: lineValues)
        
        
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
