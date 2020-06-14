package com.example.flutterscichartproject.sci.panelmodel;

import com.scichart.charting.model.AnnotationCollection;
import com.scichart.charting.model.RenderableSeriesCollection;
import com.scichart.charting.visuals.axes.AutoRange;
import com.scichart.charting.visuals.axes.NumericAxis;
import com.scichart.charting.visuals.renderableSeries.BaseRenderableSeries;
import com.scichart.data.model.DoubleRange;
import com.scichart.extensions.builders.SciChartBuilder;

public abstract class BasePaneModel {

    public final RenderableSeriesCollection renderableSeries;
    public final AnnotationCollection annotations;
    public final NumericAxis yAxis;

    BasePaneModel(SciChartBuilder builder, String title, String yAxisTextFormatting, boolean isFirstPane) {
        this.renderableSeries = new RenderableSeriesCollection();
        this.annotations = new AnnotationCollection();

        this.yAxis = builder.newNumericAxis()
                .withAxisId(title)
                .withTextFormatting(yAxisTextFormatting)
                .withAutoRangeMode(AutoRange.Always)
                .withDrawMinorGridLines(true)
                .withDrawMajorGridLines(true)
                .withMinorsPerMajor(isFirstPane ? 4 : 2)
                .withMaxAutoTicks(isFirstPane ? 8 : 4)
                .withGrowBy(isFirstPane ? new DoubleRange(0.05d, 0.05d) : new DoubleRange(0d, 0d))
                .build();
    }

    final void addRenderableSeries(BaseRenderableSeries renderableSeries) {
        renderableSeries.setClipToBounds(true);
        this.renderableSeries.add(renderableSeries);
    }
}
