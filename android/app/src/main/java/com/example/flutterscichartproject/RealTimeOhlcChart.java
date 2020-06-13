package com.example.flutterscichartproject;

import android.content.Context;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;

import com.example.flutterscichartproject.data.IMarketDataService;
import com.example.flutterscichartproject.data.MarketDataService;
import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceBar;
import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.ClipMode;
import com.scichart.charting.Direction2D;
import com.scichart.charting.model.dataSeries.DataSeriesUpdate;
import com.scichart.charting.model.dataSeries.IDataSeries;
import com.scichart.charting.model.dataSeries.IDataSeriesCore;
import com.scichart.charting.model.dataSeries.IDataSeriesObserver;
import com.scichart.charting.model.dataSeries.IOhlcDataSeries;
import com.scichart.charting.model.dataSeries.IXyDataSeries;
import com.scichart.charting.modifiers.AxisDragModifierBase;
import com.scichart.charting.visuals.SciChartSurface;
import com.scichart.charting.visuals.annotations.AnnotationCoordinateMode;
import com.scichart.charting.visuals.annotations.AxisMarkerAnnotation;
import com.scichart.charting.visuals.annotations.BoxAnnotation;
import com.scichart.charting.visuals.annotations.VerticalLineAnnotation;
import com.scichart.charting.visuals.axes.AutoRange;
import com.scichart.charting.visuals.axes.CategoryDateAxis;
import com.scichart.charting.visuals.axes.IAxis;
import com.scichart.charting.visuals.axes.IAxisCore;
import com.scichart.charting.visuals.axes.NumericAxis;
import com.scichart.charting.visuals.axes.VisibleRangeChangeListener;
import com.scichart.charting.visuals.renderableSeries.FastLineRenderableSeries;
import com.scichart.charting.visuals.renderableSeries.FastMountainRenderableSeries;
import com.scichart.charting.visuals.renderableSeries.OhlcRenderableSeriesBase;
import com.scichart.core.common.Action1;
import com.scichart.core.framework.UpdateSuspender;
import com.scichart.data.model.DoubleRange;
import com.scichart.data.model.IRange;
import com.scichart.drawing.utility.ColorUtil;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class RealTimeOhlcChart {

    private final SciChartBuilder sciChartBuilder;
    private static final int SECONDS_IN_FIVE_MINUTES = 5 * 60;
    private static final int DEFAULT_POINT_COUNT = 150;
    private static final int SMA_SERIES_COLOR = 0xFFFFA500;
    private static final int STOKE_UP_COLOR = 0xFF00AA00;
    public static final int STROKE_DOWN_COLOR = 0xFFFF0000;
    public static final float STROKE_THICKNESS = 1.5f;

    private IOhlcDataSeries<Date, Double> ohlcDataSeries;
    private IXyDataSeries<Date, Double> xyDataSeries;

    private AxisMarkerAnnotation smaAxisMarker;
    private AxisMarkerAnnotation ohlcAxisMarker;

    private IMarketDataService marketDataService;
    private final MovingAverage sma50 = new MovingAverage(5);
    private PriceBar lastPrice;

    private OverviewPrototype overviewPrototype;

    private SciChartSurface surface;

    private SciChartSurface overviewSurface;
    private boolean isOHLC;
    
    private LinearLayout chartLayout;

    public OverviewPrototype getOverviewPrototype() {
        return overviewPrototype;
    }

    public SciChartSurface getOverviewSurface() {
        return overviewSurface;
    }

    public RealTimeOhlcChart(Context context, boolean isOHLC){
        this.isOHLC = isOHLC;
        SciChartBuilder.init(context);
        sciChartBuilder = SciChartBuilder.instance();
        initFields(context);
        this.marketDataService = new MarketDataService(new Date(2000, 8, 1, 12, 0, 0), 5, 500);
        initChart();
        
        setupChartLayout(context);
    }

    private void setupChartLayout(Context context) {
        chartLayout = new LinearLayout(context);
        chartLayout.setOrientation(LinearLayout.VERTICAL);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params.weight = 0.8f;
        surface.setLayoutParams(params);

        LinearLayout.LayoutParams params2 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params2.weight = 0.2f;
        overviewSurface.setLayoutParams(params2);

        chartLayout.addView(surface);
        chartLayout.addView(overviewSurface);
    }

    public LinearLayout getChartLayout() {
        return chartLayout;
    }

    private void initFields(Context context) {
        surface = new SciChartSurface(context);
        overviewSurface = new SciChartSurface(context);
        ohlcDataSeries = sciChartBuilder.newOhlcDataSeries(Date.class, Double.class).withSeriesName("Price Series").build();
        xyDataSeries = sciChartBuilder.newXyDataSeries(Date.class, Double.class).withSeriesName("50-Period SMA").build();

        smaAxisMarker = sciChartBuilder.newAxisMarkerAnnotation().withY1(0d).withBackgroundColor(SMA_SERIES_COLOR).build();
        ohlcAxisMarker = sciChartBuilder.newAxisMarkerAnnotation().withY1(0d).withBackgroundColor(STOKE_UP_COLOR).build();
    }

    public SciChartSurface getSurface() {
        return surface;
    }

    private void initChart() {
        initializeMainChart(surface);
        overviewPrototype = new OverviewPrototype(surface, overviewSurface);
    }

    public void startRealTimeChart(){
        UpdateSuspender.using(surface, new Runnable() {
            @Override
            public void run() {
                int count = DEFAULT_POINT_COUNT;
//                if (savedInstanceState != null) {
//                    count = savedInstanceState.getInt("count");
//
//                    double rangeMin = savedInstanceState.getDouble("rangeMin");
//                    double rangeMax = savedInstanceState.getDouble("rangeMax");
//
//                    surface.getXAxes().get(0).getVisibleRange().setMinMaxDouble(rangeMin, rangeMax);
//                }
                PriceSeries prices = marketDataService.getHistoricalData(count);

                ohlcDataSeries.append(prices.getDateData(), prices.getOpenData(), prices.getHighData(), prices.getLowData(), prices.getCloseData());
                xyDataSeries.append(prices.getDateData(), getSmaCurrentValues(prices));

                overviewPrototype.getOverviewDataSeries().append(prices.getDateData(), prices.getCloseData());

                marketDataService.subscribePriceUpdate(onNewPrice());
            }
        });
    }

    private List<Double> getSmaCurrentValues(PriceSeries prices) {
        List<Double> result = new ArrayList<>();
        List<Double> closeData = prices.getCloseData();

        for (int i = 0, size = closeData.size(); i < size; i++) {
            Double close = closeData.get(i);
            result.add(sma50.push(close).getCurrent());
        }

        return result;
    }

    private void initializeMainChart(final SciChartSurface surface) {
        final CategoryDateAxis xAxis = sciChartBuilder.newCategoryDateAxis()
                .withBarTimeFrame(SECONDS_IN_FIVE_MINUTES)
                .withDrawMinorGridLines(false)
                .withGrowBy(0, 0.1)
                .build();
        final NumericAxis yAxis = sciChartBuilder.newNumericAxis().withAutoRangeMode(AutoRange.Always).build();

        final OhlcRenderableSeriesBase chartSeries;

        if (isOHLC){
            chartSeries = sciChartBuilder.newOhlcSeries()
                    .withStrokeUp(STOKE_UP_COLOR, STROKE_THICKNESS)
                    .withStrokeDown(STROKE_DOWN_COLOR, STROKE_THICKNESS)
                    .withStrokeStyle(STOKE_UP_COLOR)
                    .withDataSeries(ohlcDataSeries)
                    .build();
        } else {
            chartSeries = sciChartBuilder.newCandlestickSeries()
                    .withStrokeUp(0xFF00AA00)
                    .withFillUpColor(0x8800AA00)
                    .withStrokeDown(0xFFFF0000)
                    .withFillDownColor(0x88FF0000)
                    .withDataSeries(ohlcDataSeries)
                    .build();
        }



        final FastLineRenderableSeries line = sciChartBuilder.newLineSeries().withStrokeStyle(SMA_SERIES_COLOR, STROKE_THICKNESS).withDataSeries(xyDataSeries).build();

        UpdateSuspender.using(surface, new Runnable() {
            @Override
            public synchronized void run() {
                Collections.addAll(surface.getXAxes(), xAxis);
                Collections.addAll(surface.getYAxes(), yAxis);
                Collections.addAll(surface.getRenderableSeries(), chartSeries, line);
                Collections.addAll(surface.getAnnotations(), smaAxisMarker, ohlcAxisMarker);
                Collections.addAll(surface.getChartModifiers(), sciChartBuilder.newModifierGroup()
                        .withXAxisDragModifier().build()
                        .withZoomPanModifier().withReceiveHandledEvents(true).withXyDirection(Direction2D.XDirection).build()
                        .withZoomExtentsModifier().build()

                        .withPinchZoomModifier().build()

                        .withZoomPanModifier().withReceiveHandledEvents(true).build()

                        .withZoomExtentsModifier().withReceiveHandledEvents(true).build()

                        .withXAxisDragModifier().withReceiveHandledEvents(true).withDragMode(AxisDragModifierBase.AxisDragMode.Scale).withClipModeX(ClipMode.None).build()

                        .withYAxisDragModifier().withReceiveHandledEvents(true).withDragMode(AxisDragModifierBase.AxisDragMode.Pan).build()

                        //.withLegendModifier().withOrientation(Orientation.HORIZONTAL).withPosition(Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM, 20).withReceiveHandledEvents(true).build()
                        .build());
            }
        });
    }

    private synchronized Action1<PriceBar> onNewPrice() {
        return new Action1<PriceBar>() {
            @Override
            public void execute(final PriceBar price) {
                // Update the last price, or append?
                double smaLastValue;
                final IXyDataSeries<Date, Double> overviewDataSeries = overviewPrototype.getOverviewDataSeries();

                if (lastPrice != null && lastPrice.getDate() == price.getDate()) {
                    ohlcDataSeries.update(ohlcDataSeries.getCount() - 1, price.getOpen(), price.getHigh(), price.getLow(), price.getClose());

                    smaLastValue = sma50.update(price.getClose()).getCurrent();
                    xyDataSeries.updateYAt(xyDataSeries.getCount() - 1, smaLastValue);

                    overviewDataSeries.updateYAt(overviewDataSeries.getCount() - 1, price.getClose());
                } else {
                    ohlcDataSeries.append(price.getDate(), price.getOpen(), price.getHigh(), price.getLow(), price.getClose());

                    smaLastValue = sma50.push(price.getClose()).getCurrent();
                    xyDataSeries.append(price.getDate(), smaLastValue);

                    overviewDataSeries.append(price.getDate(), price.getClose());

                    // If the latest appending point is inside the viewport (i.e. not off the edge of the screen)
                    // then scroll the viewport 1 bar, to keep the latest bar at the same place
                    final IRange visibleRange = surface.getXAxes().get(0).getVisibleRange();
                    if (visibleRange.getMaxAsDouble() > ohlcDataSeries.getCount()) {
                        visibleRange.setMinMaxDouble(visibleRange.getMinAsDouble() + 1, visibleRange.getMaxAsDouble() + 1);
                    }
                }

//                getActivity().runOnUiThread(new Runnable() {
//                    @Override
//                    public void run() {
//                        ohlcAxisMarker.setBackgroundColor(price.getClose() >= price.getOpen() ? STOKE_UP_COLOR : STROKE_DOWN_COLOR);
//                    }
//                });

                smaAxisMarker.setY1(smaLastValue);
                ohlcAxisMarker.setY1(price.getClose());

                lastPrice = price;
            }
        };
    }

    public void changeChartType(String type) {

    }


    private static class OverviewPrototype {
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


}
