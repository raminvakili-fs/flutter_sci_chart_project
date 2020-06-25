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
    
    var barrier = 0.1
    
    var xAxis : SCICategoryDateAxis?
    var barrierLine : SCIHorizontalLineAnnotation?
    var _smaAxisMarker : SCIHorizontalLineAnnotation?
    var _ohlcAxisMarker : SCIHorizontalLineAnnotation?
    
    let sharedXRange = SCIDoubleRange()
    
    let mainSurface : SCIChartSurface
    let overviewSurface: SCIChartSurface
    let macdSurface : SCIChartSurface
    let rsiSurface : SCIChartSurface
    
    var macdPaneModel : MacdPaneModel?
    var rsiPaneModel : RsiPaneModel?
    
    let _ohlcDataSeries = SCIOhlcDataSeries(xType: .date, yType: .double)
    let _xyDataSeries = SCIXyDataSeries(xType: .date, yType: .double)
    
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
        
        createMainPriceChart()
    }

    func startRealtimeChart(prices: SCDPriceSeries) {
        SCIUpdateSuspender.usingWith(mainSurface) {
            if self.alreadyLoaded {
                self._xyDataSeries.clear()
                self._ohlcDataSeries.clear();

                self.rsiPaneModel?.updateData(prices: prices)
                self.macdPaneModel?.updateData(prices: prices)

                self._ohlcDataSeries.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
                self._xyDataSeries.append(x: prices.dateData, y: self.getSmaCurrentValues(prices: prices))
                
                // TODO: update overview chart
                
            } else {
                
                self._ohlcDataSeries.seriesName = "Price Series"
                self._xyDataSeries.seriesName = "50-Period SMA";

                self._lastPrice = prices.lastObject()
                
                self._ohlcDataSeries.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
                self._xyDataSeries.append(x: prices.dateData, y: self.getSmaCurrentValues(prices: prices))
                
                self.macdPaneModel = MacdPaneModel(prices: prices)
                self.rsiPaneModel = RsiPaneModel(prices: prices)

                self.initSurface(self.macdSurface, model: self.macdPaneModel!, isMainPane: false)
                self.initSurface(self.rsiSurface, model: self.rsiPaneModel!, isMainPane: false)
                
                let leftAreaAnnotation = SCIBoxAnnotation()
                let rightAreaAnnotation = SCIBoxAnnotation()
                self.createOverviewChartWith(leftAreaAnnotation, rightAreaAnnotation: rightAreaAnnotation)
                
                let axis = self.mainSurface.xAxes[0]
                axis.visibleRangeChangeListener = { (axis, oldRange, newRange, isAnimating) in
                    leftAreaAnnotation.set(x1: self.overviewSurface.xAxes[0].visibleRange.minAsDouble)
                    leftAreaAnnotation.set(x2: self.mainSurface.xAxes[0].visibleRange.minAsDouble)
                    rightAreaAnnotation.set(x1: self.mainSurface.xAxes[0].visibleRange.minAsDouble)
                    rightAreaAnnotation.set(x2: self.overviewSurface.xAxes[0].visibleRange.minAsDouble)
                }
                
                self.initHorizontalLines(prices: prices)
                
                self.mainSurface.annotations.add(items: self.barrierLine!, self._smaAxisMarker!, self._ohlcAxisMarker!)
                
                self.alreadyLoaded = true
            }
            
            for i in 0..<prices.count {
                if Int8.random(in: 1...100) > 99 {
                    self.addMarkerForDataPoint(prices.item(at: i))
                }
            }
        }
    }
    
    private func initHorizontalLines(prices: SCDPriceSeries) {
        let lastPrice = prices.lastObject()
        let lastPriceIndex = getDateIndex(lastPrice.date!)
        
        barrierLine = SCIHorizontalLineAnnotation()
        barrierLine?.set(x1: 0)
        barrierLine?.set(y1: lastPrice.close.doubleValue + barrier)
        barrierLine?.isEditable = true
        barrierLine?.horizontalAlignment = .right
        barrierLine?.stroke = SCISolidPenStyle(color: UIColor.red, thickness: 1)
        barrierLine?.annotationLabels.add(self.createLabelWith(text: nil, labelPlacement: .axis))
        
        _smaAxisMarker = SCIHorizontalLineAnnotation()
        _smaAxisMarker?.set(x1: lastPriceIndex)
        _smaAxisMarker?.set(y1: _sma50.current())
        _smaAxisMarker?.isEditable = false
        _smaAxisMarker?.horizontalAlignment = .right
        _smaAxisMarker?.stroke = SCISolidPenStyle(color: UIColor.yellow, thickness: 1)
        _smaAxisMarker?.annotationLabels.add(self.createLabelWith(text: nil, labelPlacement: .axis))
        
        _ohlcAxisMarker = SCIHorizontalLineAnnotation()
        _ohlcAxisMarker?.set(x1: lastPriceIndex)
        _ohlcAxisMarker?.set(y1: lastPrice.close.doubleValue)
        _ohlcAxisMarker?.isEditable = false
        _ohlcAxisMarker?.horizontalAlignment = .right
        _ohlcAxisMarker?.stroke = SCISolidPenStyle(color: UIColor.white, thickness: 1)
        _ohlcAxisMarker?.annotationLabels.add(self.createLabelWith(text: nil, labelPlacement: .axis))
        
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
        let index = getDateIndex(price.date)
        
        let marker = SCITextAnnotation()
        marker.set(x1: index)
        marker.set(y1: price.high.doubleValue)
        marker.isEditable = false
        marker.text = "Marker: \(price.high!)"
        marker.fontStyle = SCIFontStyle(fontSize: 10, andTextColor: .white)
        mainSurface.annotations.add(items: marker)
    }
    
    func onNewPrice(_ price: SCDPriceBar) {
        SCIUpdateSuspender.usingWith(mainSurface) {
            let smaLastValue: Double
            if (self._lastPrice!.date == price.date) {
                self._ohlcDataSeries.update(open: price.open.doubleValue, high: price.high.doubleValue, low: price.low.doubleValue, close: price.close.doubleValue, at: self._ohlcDataSeries.count - 1)
                
                smaLastValue = self._sma50.update(price.close.doubleValue).current()
                self._xyDataSeries.update(y: smaLastValue, at: self._xyDataSeries.count - 1)
            } else {
                self._ohlcDataSeries.append(x: price.date, open: price.open.doubleValue, high: price.high.doubleValue, low: price.low.doubleValue, close: price.close.doubleValue)

                smaLastValue = self._sma50.push(price.close.doubleValue).current()
                self._xyDataSeries.append(x: price.date, y: smaLastValue)
                
                let visibleRange = self.mainSurface.xAxes[0].visibleRange
                if (visibleRange.maxAsDouble > Double(self._ohlcDataSeries.count)) {
                    visibleRange.setDoubleMinTo(visibleRange.minAsDouble + 1, maxTo: visibleRange.maxAsDouble + 1)
                }
            }
            
            self.barrierLine?.set(y1: price.close.doubleValue + self.barrier)
            
            self._smaAxisMarker?.set(x1: self.getDateIndex(price.date))
            self._smaAxisMarker?.set(y1: smaLastValue)
            
            self._ohlcAxisMarker?.set(x1: self.getDateIndex(price.date))
            self._ohlcAxisMarker?.set(y1: price.close.doubleValue)
            
            self._lastPrice = price;
        }
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
    
    func scrollToCurrentTick() {
        if let lastPrice = _lastPrice {
            let labelProvider = xAxis?.labelProvider as! ISCICategoryLabelProvider
            let lastTickIndex = labelProvider.transformDataToIndex(lastPrice.date)
            xAxis?.animateVisibleRange(to: SCIIndexRange(min: Int32(max(lastTickIndex - 20 , 0)), max: Int32(lastTickIndex)), withDuration: 0.4)
        }
    }
    
    private func getDateIndex(_ date: Date) -> Int {
        let labelProvider = xAxis?.labelProvider as! ISCICategoryLabelProvider
        return labelProvider.transformDataToIndex(date)
    }
}
