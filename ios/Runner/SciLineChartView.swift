
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
            
            let visibleRange = self.surface.xAxes[0].visibleRange
            
            visibleRange.setDoubleMinTo(visibleRange.minAsDouble + 1, maxTo: visibleRange.maxAsDouble + 1)
            

            // zoom series to fit viewport size into X-Axis direction
            // self.surface.zoomExtents()
        }
    }
    
    private func updateValue() -> Void {
        self.value = Bool.random() ? self.value + Double.random(in: 0...4) : self.value - Double.random(in: 0...4)
    }
    
    private func addLineAnnotation() -> Void {
        let horizontalLine = SCIHorizontalLineAnnotation()

        // Allow to interact with the annotation in run-time
        horizontalLine.isEditable = true

        // In a multi-axis scenario, specify the XAxisId and YAxisId
        horizontalLine.xAxisId = "TopAxisId"
        horizontalLine.yAxisId = "RightAxisId"

        // Specify a desired position by setting coordinates
        horizontalLine.coordinateMode = .absolute
        horizontalLine.set(y1: 50.0)

        // Specify the stroke color for the annotation
        horizontalLine.stroke = SCISolidPenStyle(colorCode: 0xFFFCFCFC, thickness: 4)

        // Add the annotation to the Annotations collection of the surface
        self.surface.annotations.add(horizontalLine)
    }
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel

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
            self.addLineAnnotation()
        }
        
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "loadUrl") {
                // let url = call.arguments as! String
                // Do something!
                print("LoadUrl in Line Chart")
            }
        })
    }
    
    
    public func view() -> UIView {
        return self.surface
    }
}
