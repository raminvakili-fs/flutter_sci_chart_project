import Foundation
import UIKit
import WebKit
import SciChart


let DefaultPointCount = 20
let SmaSeriesColor: uint = 0xFFFFA500
let StrokeUpColor: uint = 0xFF00AA00
let StrokeDownColor: uint = 0xFFFF0000

class RealtimeTickingStockChartView {
    
    let mainSurface : SCIChartSurface
    let overviewSurface: SCIChartSurface
    
    let _ohlcDataSeries = SCIOhlcDataSeries(xType: .date, yType: .double)
    let _xyDataSeries = SCIXyDataSeries(xType: .date, yType: .double)
    
    let _smaAxisMarker = SCIAxisMarkerAnnotation()
    let _ohlcAxisMarker = SCIAxisMarkerAnnotation()
    
    let _marketDataService = SCDMarketDataService(start: NSDate(year: 2000, month: 8, day: 01, hour: 12, minute: 0, second: 0) as Date, timeFrameMinutes: 5, tickTimerIntervals: 1)
    let _sma50 = SCDMovingAverage(length: 5)
    var _lastPrice: SCDPriceBar?
    
    var onNewPriceBlock : PriceUpdateCallback!
    
    init(surface: SCIChartSurface) {
        self.mainSurface = surface
        self.overviewSurface = SCIChartSurface()
        
        self.initExample()
        self.commonInit()
    }
    
    func commonInit() {
//        continueTickingTouched = { [weak self] in self?.subscribePriceUpdate() }
//        pauseTickingTouched = { [weak self] in self?.clearSubscribtions() }
//        seriesTypeTouched = { [weak self] in self?.changeSeriesType() }
    }

    func initExample() {
        onNewPriceBlock = { [weak self] (price) in self?.onNewPrice(price) }
        
        initDataWithService(_marketDataService)
        createMainPriceChart()
        
        let leftAreaAnnotation = SCIBoxAnnotation()
        let rightAreaAnnotation = SCIBoxAnnotation()
        createOverviewChartWith(leftAreaAnnotation, rightAreaAnnotation: rightAreaAnnotation)
        
        let axis = mainSurface.xAxes[0]
        axis.visibleRangeChangeListener = { (axis, oldRange, newRange, isAnimating) in
            print("isAnimating \(isAnimating)")
            leftAreaAnnotation.set(x1: self.overviewSurface.xAxes[0].visibleRange.minAsDouble)
            leftAreaAnnotation.set(x2: self.mainSurface.xAxes[0].visibleRange.minAsDouble)
            rightAreaAnnotation.set(x1: self.mainSurface.xAxes[0].visibleRange.minAsDouble)
            rightAreaAnnotation.set(x2: self.overviewSurface.xAxes[0].visibleRange.minAsDouble)
        }
    }
    
    fileprivate func initDataWithService(_ SCDMarketDataService: SCDMarketDataService) {
        _ohlcDataSeries.seriesName = "Price Series"
        _xyDataSeries.seriesName = "50-Period SMA";

        let prices = SCDMarketDataService.getHistoricalData(DefaultPointCount)
        _lastPrice = prices.lastObject()
        
        _ohlcDataSeries.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
        _xyDataSeries.append(x: prices.dateData, y: getSmaCurrentValues(prices: prices))
        
        subscribePriceUpdate()
    }
    
    fileprivate func getSmaCurrentValues(prices: SCDPriceSeries) -> SCIDoubleValues {
        let count = Int(prices.count)
        let result = SCIDoubleValues(capacity: count)
        for i in 0..<count {
            let close = prices.closeData.getValueAt(i)
            result.add(_sma50.push(close).current())
        }
        
        return result;
    }

    fileprivate func createMainPriceChart() {
        let xAxis = SCICategoryDateAxis()
        xAxis.growBy = SCIDoubleRange(min: 0.0, max: 0.1)
        xAxis.drawMajorGridLines = false
        
        let yAxis = SCINumericAxis()
        yAxis.autoRange = .always
        
        let ohlcSeries = SCIFastOhlcRenderableSeries()
        ohlcSeries.dataSeries = _ohlcDataSeries
        
        let ma50Series = SCIFastLineRenderableSeries()
        ma50Series.dataSeries = _xyDataSeries
        ma50Series.strokeStyle = SCISolidPenStyle(colorCode: 0xFFFF6600, thickness: 1)
        
        _smaAxisMarker.set(y1: 0)
        _smaAxisMarker.backgroundBrush = SCISolidBrushStyle(colorCode: SmaSeriesColor)
        
        _ohlcAxisMarker.set(y1: 0)
        _ohlcAxisMarker.backgroundBrush = SCISolidBrushStyle(colorCode: StrokeUpColor)
        
        let xAxisDragModifier = SCIXAxisDragModifier()
        xAxisDragModifier.dragMode = .pan
        xAxisDragModifier.clipModeX = .stretchAtExtents
        
        let pinchZoomModifier = SCIPinchZoomModifier()
        pinchZoomModifier.direction = .xDirection
        
        let legendModifier = SCILegendModifier()
        legendModifier.orientation = .horizontal
        legendModifier.position = [.centerHorizontal, .bottom]
        legendModifier.margins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        SCIUpdateSuspender.usingWith(mainSurface) {
            self.mainSurface.xAxes.add(xAxis)
            self.mainSurface.yAxes.add(yAxis)
            self.mainSurface.renderableSeries.add(ma50Series)
            self.mainSurface.renderableSeries.add(ohlcSeries)
            self.mainSurface.annotations.add(items: self._smaAxisMarker, self._ohlcAxisMarker)
            //self.mainSurface.chartModifiers.add(items: SCIXAxisDragModifier(), zoomPanModifier, SCIZoomExtentsModifier(), legendModifier)
            self.mainSurface.chartModifiers.add(items: xAxisDragModifier, pinchZoomModifier, SCIZoomPanModifier(), SCIZoomExtentsModifier(), legendModifier)
        }
    }
    
    fileprivate func createOverviewChartWith(_ leftAreaAnnotation: SCIBoxAnnotation, rightAreaAnnotation: SCIBoxAnnotation) {
        let xAxis = SCICategoryDateAxis()
        xAxis.autoRange = .always
        
        let yAxis = SCINumericAxis()
        yAxis.growBy = SCIDoubleRange(min: 0.1, max: 0.1)
        yAxis.autoRange = .always
        
        let mountainSeries = SCIFastMountainRenderableSeries()
        mountainSeries.dataSeries = _ohlcDataSeries
        mountainSeries.areaStyle = SCILinearGradientBrushStyle(start: CGPoint(x: 0.5, y: 0), end: CGPoint(x: 0.5, y: 1), startColorCode: 0x883a668f, endColorCode: 0xff20384f)
        
        leftAreaAnnotation.coordinateMode = .relativeY
        leftAreaAnnotation.set(y1: 0)
        leftAreaAnnotation.set(y2: 1)
        leftAreaAnnotation.fillBrush = SCISolidBrushStyle(colorCode: 0x33FFFFFF)
        
        rightAreaAnnotation.coordinateMode = .relativeY
        rightAreaAnnotation.set(y1: 0)
        rightAreaAnnotation.set(y2: 1)
        rightAreaAnnotation.fillBrush = SCISolidBrushStyle(colorCode: 0x33FFFFFF)
        
        SCIUpdateSuspender.usingWith(overviewSurface) {
            self.overviewSurface.xAxes.add(xAxis)
            self.overviewSurface.yAxes.add(yAxis)
            self.overviewSurface.renderableSeries.add(mountainSeries)
            self.overviewSurface.annotations.add(items: leftAreaAnnotation, rightAreaAnnotation)
        }
    }
    
    fileprivate func onNewPrice(_ price: SCDPriceBar) {
        let smaLastValue: Double
        if (_lastPrice!.date == price.date) {
            _ohlcDataSeries.update(open: price.open.doubleValue, high: price.high.doubleValue, low: price.low.doubleValue, close: price.close.doubleValue, at: _ohlcDataSeries.count - 1)
            
            smaLastValue = _sma50.update(price.close.doubleValue).current()
            _xyDataSeries.update(y: smaLastValue, at: _xyDataSeries.count - 1)
        } else {
            _ohlcDataSeries.append(x: price.date, open: price.open.doubleValue, high: price.high.doubleValue, low: price.low.doubleValue, close: price.close.doubleValue)

            smaLastValue = _sma50.push(price.close.doubleValue).current()
            _xyDataSeries.append(x: price.date, y: smaLastValue)
            
            let visibleRange = mainSurface.xAxes[0].visibleRange
            if (visibleRange.maxAsDouble > Double(_ohlcDataSeries.count)) {
                visibleRange.setDoubleMinTo(visibleRange.minAsDouble + 1, maxTo: visibleRange.maxAsDouble + 1)
            }
        }
        
        let color = price.close.compare(price.open) == .orderedDescending ? StrokeUpColor : StrokeDownColor
        _ohlcAxisMarker.backgroundBrush = SCISolidBrushStyle(colorCode: color)
        _ohlcAxisMarker.set(y1: price.close.doubleValue)
        _smaAxisMarker.set(y1: smaLastValue)
        
        _lastPrice = price;
    }
    
    // To play realtime chart
    fileprivate func subscribePriceUpdate() {
        _marketDataService.subscribePriceUpdate(onNewPriceBlock)
    }
    
    // To stop
    fileprivate func clearSubscribtions() {
        _marketDataService.clearSubscriptions()
    }
    
    // To change chart type
    func changeSeriesType(_ type: String) {
        switch type {
            case "candle":
                self.changeSeries(SCIFastCandlestickRenderableSeries())
            case "ohlc":
                self.changeSeries(SCIFastOhlcRenderableSeries())
            default:
                self.changeSeries(SCIFastMountainRenderableSeries())
        }
    }
    
    fileprivate func changeSeries(_ rSeries: SCIRenderableSeriesBase) {
        rSeries.dataSeries = _ohlcDataSeries
        
        SCIUpdateSuspender.usingWith(mainSurface) {
            self.mainSurface.renderableSeries.remove(at: 1)
            self.mainSurface.renderableSeries.add(rSeries)
        }
    }
    
//    override func willMove(toWindow newWindow: UIWindow?) {
//        super.willMove(toWindow: newWindow);
//        if newWindow == nil {
//            _marketDataService.clearSubscriptions()
//        }
//    }
}
