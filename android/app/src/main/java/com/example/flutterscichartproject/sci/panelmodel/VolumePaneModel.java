package com.example.flutterscichartproject.sci.panelmodel;

import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.model.dataSeries.XyDataSeries;
import com.scichart.core.common.Func1;
import com.scichart.core.utility.ListUtil;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Collections;
import java.util.Date;

class VolumePaneModel extends BasePaneModel {
    private static final String VOLUME = "Volume";

    public VolumePaneModel(SciChartBuilder builder, PriceSeries prices) {
        super(builder, VOLUME, "###E+0", false);

        final XyDataSeries<Date, Double> volumePrices = builder.newXyDataSeries(Date.class, Double.class).withSeriesName("Volume").build();
        volumePrices.append(prices.getDateData(), ListUtil.select(prices.getVolumeData(), new Func1<Long, Double>() {
            @Override
            public Double func(Long arg) {
                return arg.doubleValue();
            }
        }));
        addRenderableSeries(builder.newColumnSeries().withDataSeries(volumePrices).withYAxisId(VOLUME).build());

        Collections.addAll(annotations,
                builder.newAxisMarkerAnnotation().withY1(volumePrices.getYValues().get(volumePrices.getCount() - 1)).withYAxisId(VOLUME).build());
    }
}
