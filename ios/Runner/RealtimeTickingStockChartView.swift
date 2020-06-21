import Foundation
import UIKit
import WebKit
import SciChart


let DefaultPointCount = 20
let SmaSeriesColor: uint = 0xFFFFA500
let StrokeUpColor: uint = 0xFF00AA00
let StrokeDownColor: uint = 0xFFFF0000

class RealtimeTickingStockChartView {
    
    let chartLayout = UIView()
    
    var xAxis : SCICategoryDateAxis?
    
    let sharedXRange = SCIDoubleRange()
    
    let mainSurface : SCIChartSurface
    let overviewSurface: SCIChartSurface
    let macdSurface : SCIChartSurface
    let rsiSurface : SCIChartSurface
    
    var macdPaneModel : MacdPaneModel?
    var rsiPaneModel : RsiPaneModel?
    
    let _ohlcDataSeries = SCIOhlcDataSeries(xType: .date, yType: .double)
    let _xyDataSeries = SCIXyDataSeries(xType: .date, yType: .double)
    
    let _smaAxisMarker = SCIAxisMarkerAnnotation()
    let _ohlcAxisMarker = SCIAxisMarkerAnnotation()
    
    let _sma50 = SCDMovingAverage(length: 5)
    var _lastPrice: SCDPriceBar?
    
    var alreadyLoaded = false
    
    
    init() {
        mainSurface = SCIChartSurface()
        overviewSurface = SCIChartSurface()
        macdSurface = SCIChartSurface()
        rsiSurface = SCIChartSurface()
        
        chartLayout.addSubview(mainSurface)
        chartLayout.addSubview(overviewSurface)
        chartLayout.addSubview(macdSurface)
        chartLayout.addSubview(rsiSurface)
        
        addLayoutConstraints()
        
    }

    func startRealtimeChart(prices: SCDPriceSeries) {
        if alreadyLoaded {
            _xyDataSeries.clear()
            _ohlcDataSeries.clear();

            rsiPaneModel?.updateData(prices: prices)
            macdPaneModel?.updateData(prices: prices)

            _ohlcDataSeries.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
            _xyDataSeries.append(x: prices.dateData, y: getSmaCurrentValues(prices: prices))
            
            // TODO: update overview chart
            
        } else {
            initDataWithService(prices: prices)
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
            
            let horizontalLine1 = SCIHorizontalLineAnnotation()
            horizontalLine1.set(x1: 0)
            horizontalLine1.set(y1: prices.closeData.getValueAt(0))
            horizontalLine1.isEditable = true
            horizontalLine1.horizontalAlignment = .right
            horizontalLine1.stroke = SCISolidPenStyle(color: UIColor.red, thickness: 2)
            horizontalLine1.annotationLabels.add(createLabelWith(text: nil, labelPlacement: .axis))
            
            mainSurface.annotations.add(items: horizontalLine1)
            
            alreadyLoaded = true
        }
    }
    
    func initSurface(_ surface: SCIChartSurface, model: BasePaneModel, isMainPane: Bool) {
        let xAxis = SCICategoryDateAxis()
        xAxis.isVisible = isMainPane
        xAxis.visibleRange = sharedXRange
        xAxis.growBy = SCIDoubleRange(min: 0.0, max: 0.05)

        let xAxisDragModifier = SCIXAxisDragModifier()
        xAxisDragModifier.dragMode = .pan
        xAxisDragModifier.clipModeX = .stretchAtExtents

        let pinchZoomModifier = SCIPinchZoomModifier()
        pinchZoomModifier.direction = .xDirection

        let legendModifier = SCILegendModifier()
        legendModifier.showCheckBoxes = false

        SCIUpdateSuspender.usingWith(surface) {
            surface.xAxes.add(xAxis)
            surface.yAxes.add(model.yAxis)
            surface.renderableSeries = model.renderableSeries
            surface.annotations = model.annotations
            surface.chartModifiers.add(items: xAxisDragModifier, pinchZoomModifier, SCIZoomPanModifier(), SCIZoomExtentsModifier(), legendModifier)
        }
    }
    
    fileprivate func initDataWithService(prices: SCDPriceSeries) {
        _ohlcDataSeries.seriesName = "Price Series"
        _xyDataSeries.seriesName = "50-Period SMA";

        _lastPrice = prices.lastObject()
        
        _ohlcDataSeries.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
        _xyDataSeries.append(x: prices.dateData, y: getSmaCurrentValues(prices: prices))
        
        macdPaneModel = MacdPaneModel(prices: prices)
        rsiPaneModel = RsiPaneModel(prices: prices)

        initSurface(macdSurface, model: macdPaneModel!, isMainPane: false)
        initSurface(rsiSurface, model: rsiPaneModel!, isMainPane: false)
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
        xAxis = SCICategoryDateAxis()
        xAxis?.visibleRange = sharedXRange
        xAxis?.growBy = SCIDoubleRange(min: 0.0, max: 0.1)
        xAxis?.drawMajorGridLines = false
        
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
            self.mainSurface.xAxes.add(self.xAxis!)
            self.mainSurface.yAxes.add(yAxis)
            self.mainSurface.renderableSeries.add(ma50Series)
            self.mainSurface.renderableSeries.add(ohlcSeries)
            self.mainSurface.annotations.add(items: self._smaAxisMarker, self._ohlcAxisMarker)
            //self.mainSurface.chartModifiers.add(items: SCIXAxisDragModifier(), zoomPanModifier, SCIZoomExtentsModifier(), legendModifier)
            self.mainSurface.chartModifiers.add(items: xAxisDragModifier, pinchZoomModifier, SCIZoomPanModifier(), SCIZoomExtentsModifier(), legendModifier, SCICursorModifier())
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
    
    fileprivate func addMarkerForDataPoint(_ price: SCDPriceBar) {
        let calculator = xAxis!.currentCoordinateCalculator
        let labelProvider = xAxis?.labelProvider as! ISCICategoryLabelProvider
        let index = labelProvider.transformDataToIndex(price.date)
        let x = calculator.getCoordinate(Double(index))
        
        let textAnnotation2 = SCITextAnnotation()
        textAnnotation2.set(x1: x)
        textAnnotation2.set(y1: price.high.doubleValue)
        textAnnotation2.isEditable = true
        textAnnotation2.text = "Marker"
        textAnnotation2.fontStyle = SCIFontStyle(fontSize: 20, andTextColor: .white)
    }
    
    func onNewPrice(_ price: SCDPriceBar) {
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
            
            addMarkerForDataPoint(price)
        }
        
        let color = price.close.compare(price.open) == .orderedDescending ? StrokeUpColor : StrokeDownColor
        _ohlcAxisMarker.backgroundBrush = SCISolidBrushStyle(colorCode: color)
        _ohlcAxisMarker.set(y1: price.close.doubleValue)
        _smaAxisMarker.set(y1: smaLastValue)
        
        _lastPrice = price;
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
    
    private func addLayoutConstraints() -> Void {
        macdSurface.translatesAutoresizingMaskIntoConstraints = false
        chartLayout.addConstraint(NSLayoutConstraint(item: macdSurface, attribute: .bottom, relatedBy: .equal, toItem: chartLayout, attribute: .bottom, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: macdSurface, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        chartLayout.addConstraint(NSLayoutConstraint(item: macdSurface, attribute: .right, relatedBy: .equal, toItem: chartLayout, attribute: .right, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: macdSurface, attribute: .left, relatedBy: .equal, toItem: chartLayout, attribute: .left, multiplier: 1, constant: 0))

        rsiSurface.translatesAutoresizingMaskIntoConstraints = false
        chartLayout.addConstraint(NSLayoutConstraint(item: rsiSurface, attribute: .bottom, relatedBy: .equal, toItem: macdSurface, attribute: .top, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: rsiSurface, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        chartLayout.addConstraint(NSLayoutConstraint(item: rsiSurface, attribute: .right, relatedBy: .equal, toItem: chartLayout, attribute: .right, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: rsiSurface, attribute: .left, relatedBy: .equal, toItem: chartLayout, attribute: .left, multiplier: 1, constant: 0))
        
        overviewSurface.translatesAutoresizingMaskIntoConstraints = false
        chartLayout.addConstraint(NSLayoutConstraint(item: overviewSurface, attribute: .bottom, relatedBy: .equal, toItem: rsiSurface, attribute: .top, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: overviewSurface, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        chartLayout.addConstraint(NSLayoutConstraint(item: overviewSurface, attribute: .right, relatedBy: .equal, toItem: chartLayout, attribute: .right, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: overviewSurface, attribute: .left, relatedBy: .equal, toItem: chartLayout, attribute: .left, multiplier: 1, constant: 0))
        
        mainSurface.translatesAutoresizingMaskIntoConstraints = false
        chartLayout.addConstraint(NSLayoutConstraint(item: mainSurface, attribute: .top, relatedBy: .equal, toItem: chartLayout, attribute: .top, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: mainSurface, attribute: .bottom, relatedBy: .equal, toItem: overviewSurface, attribute: .top, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: mainSurface, attribute: .right, relatedBy: .equal, toItem: chartLayout, attribute: .right, multiplier: 1, constant: 0))
        chartLayout.addConstraint(NSLayoutConstraint(item: mainSurface, attribute: .left, relatedBy: .equal, toItem: chartLayout, attribute: .left, multiplier: 1, constant: 0))
        
    }
    
    fileprivate func createLabelWith(text: String?, labelPlacement: SCILabelPlacement) -> SCIAnnotationLabel {
        let annotationLabel = SCIAnnotationLabel()
        if (text != nil) {
            annotationLabel.text = text!
        }
        annotationLabel.labelPlacement = labelPlacement
        
        return annotationLabel
    }
}
