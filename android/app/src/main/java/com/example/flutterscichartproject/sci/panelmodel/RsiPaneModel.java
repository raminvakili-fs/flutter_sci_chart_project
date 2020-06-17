package com.example.flutterscichartproject.sci.panelmodel;

import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.model.dataSeries.XyDataSeries;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Collections;
import java.util.Date;

public class RsiPaneModel extends BasePaneModel {
    private static final String RSI = "RSI";
    private XyDataSeries<Date, Double> rsiSeries;

    public RsiPaneModel(SciChartBuilder builder, PriceSeries prices) {
        super(builder, RSI, "0.0", false);

        rsiSeries = builder.newXyDataSeries(Date.class, Double.class).withSeriesName("RSI").build();
        rsiSeries.append(prices.getDateData(), MovingAverage.rsi(prices, 14));
        addRenderableSeries(builder.newLineSeries().withDataSeries(rsiSeries).withStrokeStyle(0xFFC6E6FF, 1f).withYAxisId(RSI).build());

        Collections.addAll(annotations,
                builder.newAxisMarkerAnnotation().withY1(rsiSeries.getYValues().get(rsiSeries.getCount() - 1)).withYAxisId(RSI).build());
    }

    public void reloadData(PriceSeries prices) {
        rsiSeries.clear();
        rsiSeries.append(prices.getDateData(), MovingAverage.rsi(prices, 14));
    }

}
