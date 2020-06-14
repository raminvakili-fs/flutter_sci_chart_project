let VOLUME = "Volume";
let PRICES = "Prices";
let RSI = "RSI";
let MACD = "MACD";

class BasePaneModel {
    
    let renderableSeries = SCIRenderableSeriesCollection()
    let annotations = SCIAnnotationCollection()
    let yAxis = SCINumericAxis()
    let title: String

    init(title: String, yAxisTextFormatting: String?, isFirstPane: Bool) {
        self.title = title
        yAxis.axisId = title
        if (yAxisTextFormatting != nil) {
            yAxis.textFormatting = yAxisTextFormatting
        }
        yAxis.autoRange = .always
        yAxis.minorsPerMajor = isFirstPane ? 4 : 2
        yAxis.maxAutoTicks = isFirstPane ? 8 : 4

        let growBy = isFirstPane ? 0.05 : 0.0
        yAxis.growBy = SCIDoubleRange(min: growBy, max: growBy)
    }

    func addRenderableSeries(_ renderableSeries: SCIRenderableSeriesBase) {
        self.renderableSeries.add(renderableSeries)
    }

    func addAxisMarkerAnnotationWith(_ yAxisId: String, format: String, value: ISCIComparable, color: UIColor?) {
        let axisMarkerAnnotation = SCIAxisMarkerAnnotation()
        axisMarkerAnnotation.yAxisId = yAxisId
        axisMarkerAnnotation.set(y1: value.toDouble())
        axisMarkerAnnotation.coordinateMode = .absolute
        
        if let uiColor = color {
            axisMarkerAnnotation.backgroundBrush = SCISolidBrushStyle(color: uiColor)
        }
        axisMarkerAnnotation.fontStyle = SCIFontStyle(fontSize: 12, andTextColor: .white)
        axisMarkerAnnotation.formattedValue = String(format: format, value.toDouble())

        annotations.add(axisMarkerAnnotation)
    }
}

// MARK: - Price Pane

class PricePaneModel: BasePaneModel {
    
    init(prices: SCDPriceSeries) {
        super.init(title: PRICES, yAxisTextFormatting: "$0.0000", isFirstPane: true)

        // Add the main OHLC chart
        let stockPrices = SCIOhlcDataSeries(xType: .date, yType: .double)
        stockPrices.seriesName = "EUR/USD"
        stockPrices.append(x: prices.dateData, open: prices.openData, high: prices.highData, low: prices.lowData, close: prices.closeData)
        
        let candlestickSeries = SCIFastCandlestickRenderableSeries()
        candlestickSeries.dataSeries = stockPrices
        candlestickSeries.yAxisId = PRICES
        addRenderableSeries(candlestickSeries)

        let maLow = SCIXyDataSeries(xType: .date, yType: .double)
        maLow.seriesName = "Low Line"
        maLow.append(x: prices.dateData, y: SCDMovingAverage.movingAverage(prices.closeData, period: 50))
        
        let lineSeriesLow = SCIFastLineRenderableSeries()
        lineSeriesLow.dataSeries = maLow
        lineSeriesLow.yAxisId = PRICES
        lineSeriesLow.strokeStyle = SCISolidPenStyle(colorCode: 0xFFFF3333, thickness: 1)
        addRenderableSeries(lineSeriesLow)

        let maHigh = SCIXyDataSeries(xType: .date, yType: .double)
        maHigh.seriesName = "High Line"
        maHigh.append(x: prices.dateData, y: SCDMovingAverage.movingAverage(prices.closeData, period: 200))
        
        let lineSeriesHigh = SCIFastLineRenderableSeries()
        lineSeriesHigh.dataSeries = maHigh
        lineSeriesHigh.yAxisId = PRICES
        lineSeriesHigh.strokeStyle = SCISolidPenStyle(colorCode: 0xFF33DD33, thickness: 1)
        addRenderableSeries(lineSeriesHigh)

        addAxisMarkerAnnotationWith(PRICES, format: "$%.4f", value: stockPrices.yValues.value(at: stockPrices.count - 1), color: lineSeriesLow.strokeStyle!.color)
        addAxisMarkerAnnotationWith(PRICES, format: "$%.4f", value: stockPrices.yValues.value(at: maLow.count - 1), color: lineSeriesLow.strokeStyle!.color)
        addAxisMarkerAnnotationWith(PRICES, format: "$%.4f", value: stockPrices.yValues.value(at: maHigh.count - 1), color: lineSeriesHigh.strokeStyle!.color)
    }
}

// MARK: - Volume Pane

class VolumePaneModel: BasePaneModel {

    init(prices: SCDPriceSeries) {
        super.init(title: VOLUME, yAxisTextFormatting: "###E+0", isFirstPane: false)

        let volumePrices = SCIXyDataSeries(xType: .date, yType: .long)
        volumePrices.seriesName = "Volume"
        volumePrices.append(x: prices.dateData, y: prices.volumeData)

        let columnSeries = SCIFastColumnRenderableSeries()
        columnSeries.dataSeries = volumePrices
        columnSeries.yAxisId = VOLUME
        addRenderableSeries(columnSeries)

        addAxisMarkerAnnotationWith(VOLUME, format: "$%.g", value: volumePrices.yValues.value(at: volumePrices.count - 1), color: nil)
    }
}

// MARK: - RSI Pane

class RsiPaneModel: BasePaneModel {
    init(prices: SCDPriceSeries) {
        super.init(title: RSI, yAxisTextFormatting: "0.0", isFirstPane: false)

        let rsiDataSeries = SCIXyDataSeries(xType: .date, yType: .double)
        rsiDataSeries.seriesName = "RSI"
        rsiDataSeries.append(x: prices.dateData, y: SCDMovingAverage.rsi(prices, period: 14))

        let lineSeries = SCIFastLineRenderableSeries()
        lineSeries.dataSeries = rsiDataSeries
        lineSeries.yAxisId = RSI
        lineSeries.strokeStyle = SCISolidPenStyle(colorCode: 0xFFC6E6FF, thickness: 1)
        addRenderableSeries(lineSeries)

        addAxisMarkerAnnotationWith(RSI, format: "%.2f", value: rsiDataSeries.yValues.value(at: rsiDataSeries.count - 1), color: nil)
    }
}

// MARK: - MACD Pane

class MacdPaneModel: BasePaneModel {
    init(prices: SCDPriceSeries) {
        super.init(title: MACD, yAxisTextFormatting: "0.00", isFirstPane: false)

        let macdPoints = SCDMovingAverage.macd(prices.closeData, slow: 12, fast: 25, signal: 9)

        let histogramDataSeries = SCIXyDataSeries(xType: .date, yType: .double)
        histogramDataSeries.seriesName = "Histogram"
        histogramDataSeries.append(x: prices.dateData, y: macdPoints.divergenceValues)

        let columnSeries = SCIFastColumnRenderableSeries()
        columnSeries.dataSeries = histogramDataSeries
        columnSeries.yAxisId = MACD
        addRenderableSeries(columnSeries)

        let macdDataSeries = SCIXyyDataSeries(xType: .date, yType: .double)
        macdDataSeries.seriesName = "MACD"
        macdDataSeries.append(x: prices.dateData, y: macdPoints.macdValues, y1: macdPoints.signalValues)

        let bandSeries = SCIFastBandRenderableSeries()
        bandSeries.dataSeries = macdDataSeries
        bandSeries.yAxisId = MACD
        addRenderableSeries(bandSeries)

        addAxisMarkerAnnotationWith(MACD, format: "%.2f", value: histogramDataSeries.yValues.value(at: histogramDataSeries.count - 1), color: nil)
        addAxisMarkerAnnotationWith(MACD, format: "%.2f", value: macdDataSeries.yValues.value(at: macdDataSeries.count - 1), color: nil)
    }
}
