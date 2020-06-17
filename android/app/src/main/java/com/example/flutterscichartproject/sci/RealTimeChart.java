package com.example.flutterscichartproject.sci;

import android.content.Context;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceBar;
import com.example.flutterscichartproject.data.PriceSeries;
import com.example.flutterscichartproject.sci.panelmodel.BasePaneModel;
import com.example.flutterscichartproject.sci.panelmodel.MacdPaneModel;
import com.example.flutterscichartproject.sci.panelmodel.RsiPaneModel;
import com.scichart.charting.ClipMode;
import com.scichart.charting.Direction2D;
import com.scichart.charting.model.dataSeries.IOhlcDataSeries;
import com.scichart.charting.model.dataSeries.IXyDataSeries;
import com.scichart.charting.modifiers.AxisDragModifierBase;
import com.scichart.charting.visuals.SciChartSurface;
import com.scichart.charting.visuals.annotations.AxisMarkerAnnotation;
import com.scichart.charting.visuals.axes.AutoRange;
import com.scichart.charting.visuals.axes.CategoryDateAxis;
import com.scichart.charting.visuals.axes.NumericAxis;
import com.scichart.charting.visuals.renderableSeries.FastLineRenderableSeries;
import com.scichart.charting.visuals.renderableSeries.OhlcRenderableSeriesBase;
import com.scichart.core.annotations.Orientation;
import com.scichart.core.framework.UpdateSuspender;
import com.scichart.data.model.DoubleRange;
import com.scichart.data.model.IRange;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class RealTimeChart {

    private final SciChartBuilder sciChartBuilder;
    static final int SECONDS_IN_FIVE_MINUTES = 5 * 60;
    private static final int SMA_SERIES_COLOR = 0xFFFFA500;
    private static final int STOKE_UP_COLOR = 0xFF00AA00;
    private static final int STROKE_DOWN_COLOR = 0xFFFF0000;
    private static final float STROKE_THICKNESS = 1.5f;

    private IOhlcDataSeries<Date, Double> ohlcDataSeries;
    private IXyDataSeries<Date, Double> xyDataSeries;

    private AxisMarkerAnnotation smaAxisMarker;
    private AxisMarkerAnnotation ohlcAxisMarker;

    private final MovingAverage sma50 = new MovingAverage(5);
    private PriceBar lastPrice;

    private OverviewPrototype overviewPrototype;

    private SciChartSurface surface;
    private SciChartSurface rsiSurface;
    private SciChartSurface macdSurface;

    private RsiPaneModel rsiPaneModel;
    private MacdPaneModel macdPaneModel;

    private SciChartSurface overviewSurface;

    private LinearLayout chartLayout;

    private final DoubleRange sharedXRange = new DoubleRange();

    private boolean alreadyLoaded = false;

    public RealTimeChart(Context context) {
        SciChartBuilder.init(context);
        sciChartBuilder = SciChartBuilder.instance();
        initFields(context);
        setupChartLayout(context);
        initializeMainChart(surface);
        overviewPrototype = new OverviewPrototype(surface, overviewSurface);
    }

    private void setupChartLayout(Context context) {
        chartLayout = new LinearLayout(context);
        chartLayout.setOrientation(LinearLayout.VERTICAL);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params.weight = 0.55f;
        surface.setLayoutParams(params);

        LinearLayout.LayoutParams params2 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params2.weight = 0.15f;
        overviewSurface.setLayoutParams(params2);

        LinearLayout.LayoutParams params3 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params3.weight = 0.15f;
        rsiSurface.setLayoutParams(params3);

        LinearLayout.LayoutParams params4 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params4.weight = 0.15f;
        macdSurface.setLayoutParams(params4);

        chartLayout.addView(surface);
        chartLayout.addView(overviewSurface);
        chartLayout.addView(rsiSurface);
        chartLayout.addView(macdSurface);
    }

    public ViewGroup getChartLayout() {
        return chartLayout;
    }

    private void initFields(Context context) {
        surface = new SciChartSurface(context);
        overviewSurface = new SciChartSurface(context);
        rsiSurface = new SciChartSurface(context);
        macdSurface = new SciChartSurface(context);

        ohlcDataSeries = sciChartBuilder.newOhlcDataSeries(Date.class, Double.class).withSeriesName("Price Series").build();
        xyDataSeries = sciChartBuilder.newXyDataSeries(Date.class, Double.class).withSeriesName("50-Period SMA").build();

        smaAxisMarker = sciChartBuilder.newAxisMarkerAnnotation().withY1(0d).withBackgroundColor(SMA_SERIES_COLOR).build();
        ohlcAxisMarker = sciChartBuilder.newAxisMarkerAnnotation().withY1(0d).withBackgroundColor(STOKE_UP_COLOR).build();
    }

    public void startRealTimeChart(PriceSeries prices) {
        if (alreadyLoaded) {
            UpdateSuspender.using(surface, () -> {
                xyDataSeries.clear();
                ohlcDataSeries.clear();

                rsiPaneModel.reloadData(prices);
                macdPaneModel.reloadData(prices);

                ohlcDataSeries.append(prices.getDateData(), prices.getOpenData(), prices.getHighData(), prices.getLowData(), prices.getCloseData());
                xyDataSeries.append(prices.getDateData(), getSmaCurrentValues(prices));
                overviewPrototype.getOverviewDataSeries().clear();
                overviewPrototype.getOverviewDataSeries().append(prices.getDateData(), prices.getCloseData());
            });
        } else {
            UpdateSuspender.using(surface, () -> {

                rsiPaneModel = new RsiPaneModel(sciChartBuilder, prices);
                macdPaneModel = new MacdPaneModel(sciChartBuilder, prices);
                initChart(rsiSurface, rsiPaneModel);
                initChart(macdSurface, macdPaneModel);

                ohlcDataSeries.append(prices.getDateData(), prices.getOpenData(), prices.getHighData(), prices.getLowData(), prices.getCloseData());
                xyDataSeries.append(prices.getDateData(), getSmaCurrentValues(prices));

                overviewPrototype.getOverviewDataSeries().append(prices.getDateData(), prices.getCloseData());
                alreadyLoaded = true;
            });
        }
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
                .withVisibleRange(sharedXRange)
                .withDrawMinorGridLines(false)
                .withGrowBy(0, 0.1)
                .build();
        final NumericAxis yAxis = sciChartBuilder.newNumericAxis().withAutoRangeMode(AutoRange.Always).build();

        final OhlcRenderableSeriesBase chartSeries;

        chartSeries = sciChartBuilder.newCandlestickSeries()
                .withStrokeUp(0xFF00AA00)
                .withFillUpColor(0x8800AA00)
                .withStrokeDown(0xFFFF0000)
                .withFillDownColor(0x88FF0000)
                .withDataSeries(ohlcDataSeries)
                .build();


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
                        .withLegendModifier().withOrientation(Orientation.HORIZONTAL).withPosition(Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM, 20).withReceiveHandledEvents(true).build()
                        .build());
            }
        });
    }

    public void onNewPrice(PriceBar price) {
        // Update the last price, or append?
        double smaLastValue;
        final IXyDataSeries<Date, Double> overviewDataSeries = overviewPrototype.getOverviewDataSeries();

        if (lastPrice != null && lastPrice.getDate().equals(price.getDate())) {
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
        ohlcAxisMarker.setBackgroundColor(price.getClose() >= price.getOpen() ? STOKE_UP_COLOR : STROKE_DOWN_COLOR);

        smaAxisMarker.setY1(smaLastValue);
        ohlcAxisMarker.setY1(price.getClose());

        lastPrice = price;
    }

    public void changeChartType(String type) {
        switch (type) {
            case "candle":
                changeSeries(sciChartBuilder.newCandlestickSeries()
                        .withStrokeUp(0xFF00AA00)
                        .withFillUpColor(0x8800AA00)
                        .withStrokeDown(0xFFFF0000)
                        .withFillDownColor(0x88FF0000)
                        .withDataSeries(ohlcDataSeries)
                        .build());
            case "ohlc":
                changeSeries(sciChartBuilder.newOhlcSeries()
                        .withStrokeUp(STOKE_UP_COLOR, STROKE_THICKNESS)
                        .withStrokeDown(STROKE_DOWN_COLOR, STROKE_THICKNESS)
                        .withStrokeStyle(STOKE_UP_COLOR)
                        .withDataSeries(ohlcDataSeries)
                        .build());
//            default:
//                changeSeries(sciChartBuilder.newMountainSeries()
//                        .withAreaFillColor(0x33FFF9)
//                        .withOpacity(0.5f)
//                        .withDataSeries(ohlcDataSeries)
//                        .build());
        }

    }

    private void changeSeries(OhlcRenderableSeriesBase rSeries) {
        rSeries.setDataSeries(ohlcDataSeries);

        UpdateSuspender.using(surface, () -> {
            surface.getRenderableSeries().remove(0);
            surface.getRenderableSeries().add(rSeries);
        });
    }

    private void initChart(SciChartSurface surface, BasePaneModel model) {
        final CategoryDateAxis xAxis = sciChartBuilder.newCategoryDateAxis()
                //.withVisibility(isMainPane ? View.VISIBLE : View.GONE)
                .withVisibleRange(sharedXRange)
                .withGrowBy(0, 0.05)
                .build();

        surface.getXAxes().add(xAxis);
        surface.getYAxes().add(model.yAxis);

        surface.getRenderableSeries().addAll(model.renderableSeries);

        surface.getChartModifiers().add(sciChartBuilder
                .newModifierGroup()
                .withXAxisDragModifier().withReceiveHandledEvents(true).withDragMode(AxisDragModifierBase.AxisDragMode.Pan).withClipModeX(ClipMode.StretchAtExtents).build()
                .withPinchZoomModifier().withReceiveHandledEvents(true).withXyDirection(Direction2D.XDirection).build()
                .withZoomPanModifier().withReceiveHandledEvents(true).build()
                .withZoomExtentsModifier().withReceiveHandledEvents(true).build()
                .withLegendModifier().withShowCheckBoxes(false).build()
                .build());

        surface.setAnnotations(model.annotations);
    }

}
