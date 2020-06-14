package com.example.flutterscichartproject.sci.panelmodel;

import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.model.dataSeries.OhlcDataSeries;
import com.scichart.charting.model.dataSeries.XyDataSeries;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Collections;
import java.util.Date;

class PricePaneModel extends BasePaneModel {
    private static final String PRICES = "Prices";

    public PricePaneModel(SciChartBuilder builder, PriceSeries prices) {
        super(builder, PRICES, "$0.0000", true);

        // Add the main OHLC chart
        final OhlcDataSeries<Date, Double> stockPrices = builder.newOhlcDataSeries(Date.class, Double.class).withSeriesName("EUR/USD").build();
        stockPrices.append(prices.getDateData(), prices.getOpenData(), prices.getHighData(), prices.getLowData(), prices.getCloseData());
        addRenderableSeries(builder.newCandlestickSeries().withDataSeries(stockPrices).withYAxisId(PRICES).build());

        final XyDataSeries<Date, Double> maLow = builder.newXyDataSeries(Date.class, Double.class).withSeriesName("Low Line").build();
        maLow.append(prices.getDateData(), MovingAverage.movingAverage(prices.getCloseData(), 50));
        addRenderableSeries(builder.newLineSeries().withDataSeries(maLow).withStrokeStyle(0xFFFF3333, 1f).withYAxisId(PRICES).build());

        final XyDataSeries<Date, Double> maHigh = builder.newXyDataSeries(Date.class, Double.class).withSeriesName("High Line").build();
        maHigh.append(prices.getDateData(), MovingAverage.movingAverage(prices.getCloseData(), 200));
        addRenderableSeries(builder.newLineSeries().withDataSeries(maHigh).withStrokeStyle(0xFF33DD33, 1f).withYAxisId(PRICES).build());

        Collections.addAll(annotations,
                builder.newAxisMarkerAnnotation().withY1(stockPrices.getYValues().get(stockPrices.getCount() - 1)).withBackgroundColor(0xFFFF3333).withYAxisId(PRICES).build(),
                builder.newAxisMarkerAnnotation().withY1(maLow.getYValues().get(maLow.getCount() - 1)).withBackgroundColor(0xFFFF3333).withYAxisId(PRICES).build(),
                builder.newAxisMarkerAnnotation().withY1(maHigh.getYValues().get(maHigh.getCount() - 1)).withBackgroundColor(0xFF33DD33).withYAxisId(PRICES).build());
    }
}
