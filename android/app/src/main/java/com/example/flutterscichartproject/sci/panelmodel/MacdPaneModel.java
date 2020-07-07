package com.example.flutterscichartproject.sci.panelmodel;

import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceBar;
import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.model.dataSeries.XyDataSeries;
import com.scichart.charting.model.dataSeries.XyyDataSeries;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Collections;
import java.util.Date;

public class MacdPaneModel extends BasePaneModel {
    private static final String MACD = "MACD";
    private XyDataSeries<Date, Double> histogramDataSeries;
    private XyyDataSeries<Date, Double> macdDataSeries;
    public MacdPaneModel(SciChartBuilder builder, PriceSeries prices) {
        super(builder, MACD, "0.00", false);

        final MovingAverage.MacdPoints macdPoints = MovingAverage.macd(prices.getCloseData(), 7, 20, 4);

        histogramDataSeries = builder.newXyDataSeries(Date.class, Double.class).withSeriesName("Histogram").build();
        histogramDataSeries.append(prices.getDateData(), macdPoints.divergenceValues);
        addRenderableSeries(builder.newColumnSeries().withDataSeries(histogramDataSeries).withYAxisId(MACD).build());

        macdDataSeries = builder.newXyyDataSeries(Date.class, Double.class).withSeriesName("MACD").build();
        macdDataSeries.append(prices.getDateData(), macdPoints.macdValues, macdPoints.signalValues);
        addRenderableSeries(builder.newBandSeries().withDataSeries(macdDataSeries).withYAxisId(MACD).build());

        Collections.addAll(annotations,
                builder.newAxisMarkerAnnotation().withY1(histogramDataSeries.getYValues().get(histogramDataSeries.getCount() - 1)).withYAxisId(MACD).build(),
                builder.newAxisMarkerAnnotation().withY1(macdDataSeries.getYValues().get(macdDataSeries.getCount() - 1)).withYAxisId(MACD).build());
    }

    public void reloadData(PriceSeries prices) {
        update(prices);
    }

    public void update(PriceSeries prices) {
        histogramDataSeries.clear();
        final MovingAverage.MacdPoints macdPoints = MovingAverage.macd(prices.getCloseData(), 7, 20, 4);
        histogramDataSeries.append(prices.getDateData(), macdPoints.divergenceValues);

        macdDataSeries.clear();
        macdDataSeries.append(prices.getDateData(), macdPoints.macdValues, macdPoints.signalValues);

    }
}