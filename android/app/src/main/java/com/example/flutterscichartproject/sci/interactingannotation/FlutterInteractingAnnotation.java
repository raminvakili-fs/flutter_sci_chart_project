package com.example.flutterscichartproject.sci.interactingannotation;

import android.content.Context;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;

import com.example.flutterscichartproject.data.MarketDataService;
import com.example.flutterscichartproject.data.PriceSeries;
import com.scichart.charting.model.dataSeries.OhlcDataSeries;
import com.scichart.charting.modifiers.ZoomPanModifier;
import com.scichart.charting.visuals.SciChartSurface;
import com.scichart.charting.visuals.annotations.AnnotationCoordinateMode;
import com.scichart.charting.visuals.annotations.AnnotationSurfaceEnum;
import com.scichart.charting.visuals.annotations.HorizontalAnchorPoint;
import com.scichart.charting.visuals.annotations.VerticalAnchorPoint;
import com.scichart.drawing.utility.ColorUtil;
import com.scichart.extensions.builders.SciChartBuilder;

import java.util.Calendar;
import java.util.Collections;
import java.util.Date;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;

public class FlutterInteractingAnnotation implements PlatformView, MethodCallHandler  {
    private final MethodChannel methodChannel;

    public SciChartSurface surface;

    FlutterInteractingAnnotation(Context context, BinaryMessenger messenger, int id) {
        methodChannel = new MethodChannel(messenger, "plugins.com.example/interacting_annotation_" + id);
        methodChannel.setMethodCallHandler(this);

        surface = new SciChartSurface(context);

        initExample(context);
    }

    @Override
    public View getView() {
        return surface;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        switch (methodCall.method) {
            case "setText":
                setText(methodCall, result);
                break;
            default:
                result.notImplemented();
        }

    }

    private void setText(MethodCall methodCall, Result result) {
        String text = (String) methodCall.arguments;
        result.success(null);
    }

    @Override
    public void dispose() {}


    private void initExample(Context context){
        SciChartBuilder.init(context);
        final SciChartBuilder sciChartBuilder = SciChartBuilder.instance();
        final OhlcDataSeries<Date, Double> dataSeries = sciChartBuilder.newOhlcDataSeries(Date.class, Double.class).build();

        final MarketDataService marketDataService = new MarketDataService(Calendar.getInstance().getTime(), 2, 50);
        final PriceSeries data = marketDataService.getHistoricalData(200);

        dataSeries.append(data.getDateData(), data.getOpenData(), data.getHighData(), data.getLowData(), data.getCloseData());

        Collections.addAll(surface.getRenderableSeries(), sciChartBuilder.newCandlestickSeries().withDataSeries(dataSeries).build());
        Collections.addAll(surface.getXAxes(), sciChartBuilder.newCategoryDateAxis().build());
        Collections.addAll(surface.getYAxes(), sciChartBuilder.newNumericAxis().withVisibleRange(30d, 37d).build());
        Collections.addAll(surface.getChartModifiers(), new ZoomPanModifier());

        Collections.addAll(surface.getAnnotations(),
                sciChartBuilder.newTextAnnotation()
                        .withIsEditable(true)
                        .withText("Buy!")
                        .withX1(10)
                        .withY1(30.5d)
                        .withVerticalAnchorPoint(VerticalAnchorPoint.Bottom)
                        .withFontStyle(20, ColorUtil.White)
                        .withZIndex(1) // draw this annotation above other annotations
                        .build(),
                sciChartBuilder.newTextAnnotation()
                        .withIsEditable(true)
                        .withText("Sell!")
                        .withX1(50)
                        .withY1(34d)
                        .withFontStyle(20, ColorUtil.White)
                        .withPadding(8)
                        .withZIndex(1) // draw this annotation above other annotations
                        .build(),
                sciChartBuilder.newTextAnnotation()
                        .withX1(80d).withY1(37d)
                        .withIsEditable(true)
                        .withText("Rotated text")
                        .withFontStyle(20, ColorUtil.White)
                        .withRotationAngle(30)
                        .withZIndex(1) // draw this annotation above other annotations
                        .build(),
                sciChartBuilder.newBoxAnnotation()
                        .withIsEditable(true)
                        .withPosition(50, 35.5, 120, 32)
                        .build(),
                sciChartBuilder.newLineAnnotation()
                        .withIsEditable(true)
                        .withStroke(2f, 0xAAFF6600)
                        .withPosition(40, 30.5d, 60, 33.5d)
                        .build(),
                sciChartBuilder.newLineAnnotation()
                        .withIsEditable(true)
                        .withStroke(2f, 0xAAFF6600)
                        .withPosition(120, 30.5, 175, 36)
                        .build(),
                sciChartBuilder.newLineArrowAnnotation()
                        .withArrowHeadWidth(16f)
                        .withArrowHeadLength(8f)
                        .withIsEditable(true)
                        .withPosition(50, 35d, 80, 31.4d)
                        .build(),
                sciChartBuilder.newAxisMarkerAnnotation()
                        .withIsEditable(true)
                        .withY1(32.7d)
                        .build(),
                sciChartBuilder.newAxisMarkerAnnotation()
                        .withAnnotationSurface(AnnotationSurfaceEnum.XAxis)
                        .withFormattedValue("Horizontal")
                        .withIsEditable(true)
                        .withX1(100)
                        .build(),
                sciChartBuilder.newHorizontalLineAnnotation()
                        .withPosition(150d, 32.2d)
                        .withStroke(2, ColorUtil.Red)
                        .withHorizontalGravity(Gravity.RIGHT)
                        .withIsEditable(true)
                        .build(),
                sciChartBuilder.newHorizontalLineAnnotation()
                        .withX1(130).withX2(160).withY1(33.9d)
                        .withIsEditable(true)
                        .withStroke(2, ColorUtil.Blue)
                        .withHorizontalGravity(Gravity.CENTER_HORIZONTAL)
                        .build(),
                sciChartBuilder.newVerticalLineAnnotation()
                        .withX1(20).withY1(35d).withY2(33d)
                        .withIsEditable(true)
                        .withStroke(2, ColorUtil.DarkGreen)
                        .withVerticalGravity(Gravity.CENTER_VERTICAL)
                        .build(),
                sciChartBuilder.newVerticalLineAnnotation()
                        .withX1(40).withY1(34d)
                        .withIsEditable(true)
                        .withStroke(2, ColorUtil.Green)
                        .withVerticalGravity(Gravity.TOP)
                        .build(),
                sciChartBuilder.newTextAnnotation()
                        .withCoordinateMode(AnnotationCoordinateMode.Relative)
                        .withHorizontalAnchorPoint(HorizontalAnchorPoint.Center)
                        .withText("EUR.USD")
                        .withFontStyle(Typeface.DEFAULT_BOLD, 72, 0x77FFFFFF)
                        .withX1(0.5d)
                        .withY1(0.5d)
                        .withZIndex(-1) // draw this annotation below other annotations
                        .build()
        );
    }

}
