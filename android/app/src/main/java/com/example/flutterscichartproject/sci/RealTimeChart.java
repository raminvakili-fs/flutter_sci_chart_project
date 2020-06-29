package com.example.flutterscichartproject.sci;

import android.animation.TypeEvaluator;
import android.animation.ValueAnimator;
import android.content.Context;
import android.util.Log;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.animation.DecelerateInterpolator;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.example.flutterscichartproject.R;
import com.example.flutterscichartproject.data.MovingAverage;
import com.example.flutterscichartproject.data.PriceBar;
import com.example.flutterscichartproject.data.PriceSeries;
import com.example.flutterscichartproject.sci.panelmodel.BasePaneModel;
import com.example.flutterscichartproject.sci.panelmodel.MacdPaneModel;
import com.example.flutterscichartproject.sci.panelmodel.RsiPaneModel;
import com.example.flutterscichartproject.sci.views.Marker;
import com.scichart.charting.ClipMode;
import com.scichart.charting.Direction2D;
import com.scichart.charting.model.dataSeries.IOhlcDataSeries;
import com.scichart.charting.model.dataSeries.IXyDataSeries;
import com.scichart.charting.modifiers.AxisDragModifierBase;
import com.scichart.charting.numerics.labelProviders.ICategoryLabelProvider;
import com.scichart.charting.visuals.SciChartSurface;
import com.scichart.charting.visuals.annotations.AxisMarkerAnnotation;
import com.scichart.charting.visuals.annotations.CustomAnnotation;
import com.scichart.charting.visuals.annotations.HorizontalLineAnnotation;
import com.scichart.charting.visuals.annotations.IAnnotation;
import com.scichart.charting.visuals.annotations.LabelPlacement;
import com.scichart.charting.visuals.annotations.OnAnnotationDragListener;
import com.scichart.charting.visuals.axes.AutoRange;
import com.scichart.charting.visuals.axes.CategoryDateAxis;
import com.scichart.charting.visuals.axes.NumericAxis;
import com.scichart.charting.visuals.renderableSeries.BaseRenderableSeries;
import com.scichart.charting.visuals.renderableSeries.FastLineRenderableSeries;
import com.scichart.core.annotations.Orientation;
import com.scichart.core.framework.UpdateSuspender;
import com.scichart.data.model.DoubleRange;
import com.scichart.data.model.IRange;
import com.scichart.data.model.IndexRange;
import com.scichart.drawing.utility.ColorUtil;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Random;

public class RealTimeChart {

    private Random random = new Random();
    private Context mContext;

    private final SciChartBuilder sciChartBuilder;
    static final int SECONDS_IN_FIVE_MINUTES = 5 * 60;
    private static final int SMA_SERIES_COLOR = 0xFFFFA500;
    private static final int STOKE_UP_COLOR = 0xFF00AA00;
    private static final int STROKE_DOWN_COLOR = 0xFFFF0000;
    private static final float STROKE_THICKNESS = 1.5f;

    private IOhlcDataSeries<Date, Double> ohlcDataSeries;
    private IXyDataSeries<Date, Double> xyDataSeries;

    private HorizontalLineAnnotation smaAxisMarker;
    private HorizontalLineAnnotation ohlcAxisMarker;

    private CategoryDateAxis xAxis;
    private NumericAxis yAxis;

    private final MovingAverage sma50 = new MovingAverage(5);
    private PriceBar lastPrice;

    private OverviewPrototype overviewPrototype;

    private HorizontalLineAnnotation barrierLine;

    private double barrier = -0.1;

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
        mContext = context;
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
        params.weight = 0.7f;
        surface.setLayoutParams(params);

        LinearLayout.LayoutParams params2 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params2.weight = 0.1f;
        overviewSurface.setLayoutParams(params2);

        LinearLayout.LayoutParams params3 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params3.weight = 0.1f;
        rsiSurface.setLayoutParams(params3);

        LinearLayout.LayoutParams params4 = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0);
        params4.weight = 0.1f;
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
    }

    private PriceSeries prices;

    public void startRealTimeChart(PriceSeries prices) {
        this.prices = prices;
        UpdateSuspender.using(surface, () -> {
            if (alreadyLoaded) {
                xyDataSeries.clear();
                ohlcDataSeries.clear();

                rsiPaneModel.reloadData(prices);
                macdPaneModel.reloadData(prices);

                if (barrierLine != null) {
                    barrierLine.setY1(getBarrierLineHeight(prices.get(prices.size() - 1)));
                }
                overviewPrototype.getOverviewDataSeries().clear();
            } else {
                rsiPaneModel = new RsiPaneModel(sciChartBuilder, prices);
                macdPaneModel = new MacdPaneModel(sciChartBuilder, prices);
                initChart(rsiSurface, rsiPaneModel);
                initChart(macdSurface, macdPaneModel);

                initHorizontalLines(prices);

                surface.getAnnotations().add(barrierLine);
                surface.getAnnotations().add(ohlcAxisMarker);
                surface.getAnnotations().add(smaAxisMarker);

                alreadyLoaded = true;
            }

            ohlcDataSeries.append(prices.getDateData(), prices.getOpenData(), prices.getHighData(), prices.getLowData(), prices.getCloseData());
            xyDataSeries.append(prices.getDateData(), getSmaCurrentValues(prices));
            overviewPrototype.getOverviewDataSeries().append(prices.getDateData(), prices.getCloseData());
        });
    }

    private void initHorizontalLines(PriceSeries prices) {
        ICategoryLabelProvider categoryLabelProvider = (ICategoryLabelProvider) xAxis.getLabelProvider();
        int lastPriceIndex = categoryLabelProvider.transformDataToIndex(prices.getDateData().get(prices.size() - 1));

        ohlcAxisMarker = sciChartBuilder.newHorizontalLineAnnotation()
                .withPosition(lastPriceIndex, getBarrierLineHeight(prices.get(prices.size() - 1)))
                .withStroke(0, ColorUtil.White)
                .withHorizontalGravity(Gravity.END)
                .withIsEditable(false)
                .withAnnotationLabel(LabelPlacement.Axis)
                .build();

        smaAxisMarker = sciChartBuilder.newHorizontalLineAnnotation()
                .withPosition(lastPriceIndex, getBarrierLineHeight(prices.get(prices.size() - 1)))
                .withStroke(0, SMA_SERIES_COLOR)
                .withHorizontalGravity(Gravity.END)
                .withIsEditable(false)
                .withAnnotationLabel(LabelPlacement.Axis)
                .build();

        barrierLine = sciChartBuilder.newHorizontalLineAnnotation()
                .withPosition(0, getBarrierLineHeight(prices.get(prices.size() - 1)))
                .withStroke(0, ColorUtil.Red)
                .withHorizontalGravity(Gravity.END)
                .withIsEditable(true)
                .withAnnotationLabel(LabelPlacement.Axis)
                .build();


        barrierLine.setOnAnnotationDragListener(new OnAnnotationDragListener() {
            @Override
            public void onDragStarted(IAnnotation iAnnotation) {
            }

            @Override
            public void onDragEnded(IAnnotation iAnnotation) {
            }

            @Override
            public void onDragDelta(IAnnotation iAnnotation, float v, float v1) {
                Log.i("DRAG", "" + v + " " + v1);
                barrier += v1;
            }
        });
    }

    private double getBarrierLineHeight(PriceBar price) {
        return price.getClose() + barrier;
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
        xAxis = sciChartBuilder.newCategoryDateAxis()
                .withBarTimeFrame(SECONDS_IN_FIVE_MINUTES)
                .withVisibleRange(sharedXRange)
                .withDrawMinorGridLines(false)
                .withGrowBy(0, 0.1)
                .build();
        yAxis = sciChartBuilder.newNumericAxis().withAutoRangeMode(AutoRange.Always).build();

        BaseRenderableSeries chartSeries = sciChartBuilder.newCandlestickSeries()
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
                Collections.addAll(surface.getRenderableSeries(), line, chartSeries);
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
                        .build(), sciChartBuilder.newModifierGroup()
                        .withCursorModifier().withShowTooltip(true).withShowAxisLabels(true).build()
                        .build());
            }
        });
    }

    public void onNewPrice(PriceBar price) {
        // Update the last price, or append?
        double smaLastValue;
        final IXyDataSeries<Date, Double> overviewDataSeries = overviewPrototype.getOverviewDataSeries();
        if (lastPrice != null && lastPrice.getDate().equals(price.getDate())) {
            smaLastValue = sma50.update(price.getClose()).getCurrent();
            xyDataSeries.updateYAt(xyDataSeries.getCount() - 1, smaLastValue);

            ValueAnimator animator = new ValueAnimator();
            animator.setInterpolator(new DecelerateInterpolator());
            animator.setObjectValues(ohlcDataSeries.getCloseValues().get(ohlcDataSeries.getCount() - 1), price.getClose()); //double value
            animator.addUpdateListener(animation -> UpdateSuspender.using(surface, () -> {
                ohlcAxisMarker.setY1((double) animation.getAnimatedValue());
                barrierLine.setY1(((double) animation.getAnimatedValue() + barrier));
                ohlcDataSeries.update(ohlcDataSeries.getCount() - 1, price.getOpen(), price.getHigh(), price.getLow(), (double) animation.getAnimatedValue());
            }));
            animator.setEvaluator((TypeEvaluator<Double>) (fraction, startValue, endValue) -> (startValue + ((endValue - startValue) * fraction)));
            animator.setDuration(400);
            animator.start();

            overviewDataSeries.updateYAt(overviewDataSeries.getCount() - 1, price.getClose());
        } else {
            prices.add(price);
            macdPaneModel.update(prices);
            rsiPaneModel.update(prices);

            ohlcDataSeries.append(price.getDate(), price.getOpen(), price.getHigh(), price.getLow(), price.getClose());

            smaLastValue = sma50.push(price.getClose()).getCurrent();
            xyDataSeries.append(price.getDate(), smaLastValue);

            overviewDataSeries.append(price.getDate(), price.getClose());

            ohlcAxisMarker.setY1(price.getClose());
            ohlcAxisMarker.setX1(getDatesIndex(price.getDate()));
            barrierLine.setY1((price.getClose() + barrier));
            // If the latest appending point is inside the viewport (i.e. not off the edge of the screen)
            // then scroll the viewport 1 bar, to keep the latest bar at the same place
            final IRange visibleRange = surface.getXAxes().get(0).getVisibleRange();
            if (visibleRange.getMaxAsDouble() > ohlcDataSeries.getCount()) {
                visibleRange.setMinMaxDouble(visibleRange.getMinAsDouble() + 1, visibleRange.getMaxAsDouble() + 1);
            }

        }

        smaAxisMarker.setY1(smaLastValue);
        smaAxisMarker.setX1(getDatesIndex(price.getDate()));

        lastPrice = price;
    }

    private int getDatesIndex(Date date) {
        ICategoryLabelProvider categoryLabelProvider = (ICategoryLabelProvider) xAxis.getLabelProvider();
        return categoryLabelProvider.transformDataToIndex(date);
    }

    private void addMarkerForDataPoint(Date date, double value) {
        final int index = getDatesIndex(date);

        Marker marker = new Marker(mContext);
        marker.setText("" + value);

        surface.getAnnotations().add(sciChartBuilder.newCustomAnnotation()
                .withPosition(index, value + marker.getHeight())
                .withContent(marker)
                .withIsEditable(false)
                .withZIndex(1)
                .build());
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
                break;
            case "ohlc":
                changeSeries(sciChartBuilder.newOhlcSeries()
                        .withStrokeUp(STOKE_UP_COLOR, STROKE_THICKNESS)
                        .withStrokeDown(STROKE_DOWN_COLOR, STROKE_THICKNESS)
                        .withStrokeStyle(STOKE_UP_COLOR)
                        .withDataSeries(ohlcDataSeries)
                        .build());
                break;
            default:
                changeSeries(sciChartBuilder.newMountainSeries()
                        .withAreaFillColor(0x33FFF9)
                        .withAreaFillLinearGradientColors(0x2233FFF9, 0x33FFF9)
                        .withOpacity(0.8f)
                        .withDataSeries(ohlcDataSeries)
                        .build());
                break;
        }

    }

    private void changeSeries(BaseRenderableSeries rSeries) {
        rSeries.setDataSeries(ohlcDataSeries);
        UpdateSuspender.using(surface, () -> {
            surface.getRenderableSeries().remove(1);
            surface.getRenderableSeries().add(rSeries);
        });
    }

    private void initChart(SciChartSurface surface, BasePaneModel model) {
        final CategoryDateAxis xAxis = sciChartBuilder.newCategoryDateAxis()
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

    public void scrollToCurrentTick() {
        if (lastPrice != null) {
            ICategoryLabelProvider categoryLabelProvider = (ICategoryLabelProvider) xAxis.getLabelProvider();
            int lastTickIndex = categoryLabelProvider.transformDataToIndex(lastPrice.getDate());
            xAxis.animateVisibleRangeTo(new IndexRange(Math.max(lastTickIndex - 20, 0), lastTickIndex), 400);
        }
    }

    public void addMarker() {
        addMarkerForDataPoint(lastPrice.getDate(), lastPrice.getHigh());
    }
}
