package com.example.flutterscichartproject.sci;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.example.flutterscichartproject.RealTimeOhlcChart;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;

public class FlutterCandleStick implements PlatformView, MethodCallHandler  {
    private RealTimeOhlcChart realTimeOhlcChart;

    FlutterCandleStick(Context context, BinaryMessenger messenger, int id) {
        MethodChannel methodChannel = new MethodChannel(messenger, "SciCandleChart" + id);
        methodChannel.setMethodCallHandler(this);
        realTimeOhlcChart = new RealTimeOhlcChart(context, false);
        Log.i("TAG2", "inited RealTimeOhlcChart: " + realTimeOhlcChart);
        realTimeOhlcChart.startRealTimeChart();
    }

    @Override
    public View getView() {
        Log.i("TAG2", "get surface: " + realTimeOhlcChart);
        return realTimeOhlcChart.getChartLayout();
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        if ("changeChartType".equals(methodCall.method)) {
            setText(methodCall, result);
        } else {
            result.notImplemented();
        }

    }

    private void setText(MethodCall methodCall, Result result) {
        String type = (String) methodCall.arguments;
        realTimeOhlcChart.changeChartType(type);
        result.success(null);
    }

    @Override
    public void dispose() {}

}
