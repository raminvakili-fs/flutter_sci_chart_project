import Foundation
import UIKit
import WebKit
import SciChart

public class SciCandleChartView: NSObject, FlutterPlatformView, WKScriptMessageHandler, WKNavigationDelegate {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){}
    
    let frame: CGRect
    let viewId: Int64
    let channel: FlutterMethodChannel
    let realTimeChart: RealtimeTickingStockChartView
    
    
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
    

        self.realTimeChart = RealtimeTickingStockChartView()
        
        super.init()
        
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            
            switch call.method {
            case "changeChartType":
                self.realTimeChart.changeSeriesType(call.arguments as! String)
                break
            case "loadHistoryCandles":
                self.loadHistoryCandles(argMap: call.arguments as! [String: Any])
                break
            case "addOHLC":
                self.addOHLC(argMap: call.arguments as! [String: Any])
                break
            case "scrollToCurrentTick":
                self.realTimeChart.scrollToCurrentTick()
                break
            default:
                print("Not implemented")
            }
        })
    }
    
    private func loadHistoryCandles(argMap: [String: Any]) -> Void {
        let candlesList = argMap["candles"] as! [[String: Any]]
        
        let priceSeries = SCDPriceSeries()
        
        for candleMap in candlesList {
            priceSeries.add(SCDPriceBar(date: Date.init(timeIntervalSince1970: TimeInterval(candleMap["epoch"] as! Int64) / 1000), open: candleMap["open"] as? NSNumber, high: candleMap["high"] as? NSNumber, low: candleMap["low"] as? NSNumber, close: candleMap["close"] as? NSNumber, volume: 0))
        }
        realTimeChart.startRealtimeChart(prices: priceSeries)
    }
    
    private func addOHLC(argMap: [String: Any]) -> Void {
        let newOHLC = SCDPriceBar(date: Date.init(timeIntervalSince1970: TimeInterval(argMap["open_time"] as! Int64) / 1000), open: argMap["open"] as? NSNumber, high: argMap["high"] as? NSNumber, low: argMap["low"] as? NSNumber, close: argMap["close"] as? NSNumber, volume: 0)
        
        realTimeChart.onNewPrice(newOHLC!)
    }
    
    public func view() -> UIView {
        return realTimeChart.chartLayout
    }
}
