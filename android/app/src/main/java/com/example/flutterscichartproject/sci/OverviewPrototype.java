package com.example.flutterscichartproject.sci;

import android.view.Gravity;
import android.view.View;

import com.scichart.charting.model.dataSeries.IDataSeriesCore;
import com.scichart.charting.model.dataSeries.IDataSeriesObserver;
import com.scichart.charting.model.dataSeries.IXyDataSeries;
import com.scichart.charting.visuals.SciChartSurface;
import com.scichart.charting.visuals.annotations.AnnotationCoordinateMode;
import com.scichart.charting.visuals.annotations.BoxAnnotation;
import com.scichart.charting.visuals.annotations.VerticalLineAnnotation;
import com.scichart.charting.visuals.axes.AutoRange;
import com.scichart.charting.visuals.axes.CategoryDateAxis;
import com.scichart.charting.visuals.axes.IAxis;
import com.scichart.charting.visuals.axes.IAxisCore;
import com.scichart.charting.visuals.axes.NumericAxis;
import com.scichart.charting.visuals.axes.VisibleRangeChangeListener;
import com.scichart.charting.visuals.renderableSeries.FastMountainRenderableSeries;
import com.scichart.core.framework.UpdateSuspender;
import com.scichart.data.model.DoubleRange;
import com.scichart.data.model.IRange;
import com.scichart.drawing.utility.ColorUtil;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Collections;
import java.util.Date;

import static com.example.flutterscichartproject.sci.RealTimeChart.SECONDS_IN_FIVE_MINUTES;

class OverviewPrototype {
    private final SciChartBuilder builder = SciChartBuilder.instance();

    private final VisibleRangeChangeListener parentAxisVisibleRangeChangeListener = new VisibleRangeChangeListener() {
        @Override
        public void onVisibleRangeChanged(IAxisCore axis, IRange oldRange, IRange newRange, boolean isAnimating) {
            final double newMin = newRange.getMinAsDouble();
            final double newMax = newRange.getMaxAsDouble();

            if (!overviewXAxisVisibleRange.equals(new DoubleRange(0d, 10d))) {
                parentXAxisVisibleRange.setMinMaxWithLimit(newMin, newMax, overviewXAxisVisibleRange);
            } else {
                parentXAxisVisibleRange.setMinMax(newMin, newMax);
            }

            boxAnnotation.setX1(parentXAxisVisibleRange.getMin());
            boxAnnotation.setX2(parentXAxisVisibleRange.getMax());

            leftLineGrip.setX1(parentXAxisVisibleRange.getMin());
            leftBox.setX1(overviewXAxisVisibleRange.getMin());
            leftBox.setX2(parentXAxisVisibleRange.getMin());

            rightLineGrip.setX1(parentXAxisVisibleRange.getMax());
            rightBox.setX1(parentXAxisVisibleRange.getMax());
            rightBox.setX2(overviewXAxisVisibleRange.getMax());
        }
    };

    private final BoxAnnotation leftBox = generateBoxAnnotation(0);
    private final BoxAnnotation rightBox = generateBoxAnnotation(0);
    private final BoxAnnotation boxAnnotation = generateBoxAnnotation(0);
    private final VerticalLineAnnotation leftLineGrip = generateVerticalLine();
    private final VerticalLineAnnotation rightLineGrip = generateVerticalLine();

    private final IRange<Double> parentXAxisVisibleRange;
    private IRange<Double> overviewXAxisVisibleRange;

    private final IXyDataSeries<Date, Double> overviewDataSeries = builder.newXyDataSeries(Date.class, Double.class).withAcceptsUnsortedData().build();

    @SuppressWarnings("unchecked")
    OverviewPrototype(SciChartSurface parentSurface, SciChartSurface fakeOverviewSurface) {
        final IAxis parentXAxis = parentSurface.getXAxes().get(0);
        parentXAxis.setVisibleRangeChangeListener(parentAxisVisibleRangeChangeListener);

        parentXAxisVisibleRange = parentXAxis.getVisibleRange();

        initializeOverview(fakeOverviewSurface);

        overviewDataSeries.addObserver(new IDataSeriesObserver() {
            @Override
            public void onDataSeriesChanged(IDataSeriesCore iDataSeriesCore, int i) {
                rightBox.setX1(parentXAxisVisibleRange.getMax());
                rightBox.setX2(overviewXAxisVisibleRange.getMax());
            }
        });

    }

    IXyDataSeries<Date, Double> getOverviewDataSeries() {
        return overviewDataSeries;
    }

    private void initializeOverview(final SciChartSurface surface) {
        surface.setRenderableSeriesAreaBorderStyle(null);

        final CategoryDateAxis xAxis = builder.newCategoryDateAxis()
                .withBarTimeFrame(SECONDS_IN_FIVE_MINUTES)
                .withAutoRangeMode(AutoRange.Always)
                .withDrawMinorGridLines(false)
                .withVisibility(View.GONE)
                .withGrowBy(0, 0.1)
                .build();
        overviewXAxisVisibleRange = xAxis.getVisibleRange();

        final NumericAxis yAxis = builder.newNumericAxis().withAutoRangeMode(AutoRange.Always).withVisibility(View.INVISIBLE).build();
        removeAxisGridLines(xAxis, yAxis);

        final FastMountainRenderableSeries mountain = builder.newMountainSeries().withDataSeries(overviewDataSeries).build();

        UpdateSuspender.using(surface, new Runnable() {
            @Override
            public synchronized void run() {
                Collections.addAll(surface.getXAxes(), xAxis);
                Collections.addAll(surface.getYAxes(), yAxis);
                Collections.addAll(surface.getRenderableSeries(), mountain);
                Collections.addAll(surface.getAnnotations(), boxAnnotation, leftBox, rightBox, leftLineGrip, rightLineGrip);
            }
        });
    }

    private BoxAnnotation generateBoxAnnotation( int backgroundDrawable) {
        return builder.newBoxAnnotation()
                .withBackgroundDrawableId(backgroundDrawable)
                .withCoordinateMode(AnnotationCoordinateMode.RelativeY)
                .withIsEditable(false)
                .withY1(0).withY2(1)
                .build();
    }

    private VerticalLineAnnotation generateVerticalLine() {
        return builder.newVerticalLineAnnotation().withCoordinateMode(AnnotationCoordinateMode.RelativeY)
                .withVerticalGravity(Gravity.CENTER_VERTICAL)
                .withStroke(5, ColorUtil.Grey)
                .withIsEditable(false)
                .withY1(0.3).withY2(0.7)
                .withX1(0)
                .build();
    }

    private void removeAxisGridLines(IAxis... axes) {
        for (IAxis axis : axes) {
            axis.setDrawMajorGridLines(false);
            axis.setDrawMajorTicks(false);
            axis.setDrawMajorBands(false);
            axis.setDrawMinorGridLines(false);
            axis.setDrawMinorTicks(false);
        }
    }
}