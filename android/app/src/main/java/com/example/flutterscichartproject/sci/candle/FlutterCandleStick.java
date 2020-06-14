package com.example.flutterscichartproject.sci.candle;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.example.flutterscichartproject.sci.RealTimeChart;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;

public class FlutterCandleStick implements PlatformView, MethodCallHandler  {
    private RealTimeChart realTimeChart;

    FlutterCandleStick(Context context, BinaryMessenger messenger, int id) {
        MethodChannel methodChannel = new MethodChannel(messenger, "SciCandleChart" + id);
        methodChannel.setMethodCallHandler(this);
        realTimeChart = new RealTimeChart(context, false);
        Log.i("TAG2", "init RealTimeOhlcChart: " + realTimeChart);
        realTimeChart.startRealTimeChart();
    }

    @Override
    public View getView() {
        Log.i("TAG2", "get surface: " + realTimeChart);
        return realTimeChart.getChartLayout();
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        if ("changeChartType".equals(methodCall.method)) {
            changeChartType(methodCall, result);
        } else {
            result.notImplemented();
        }

    }

    private void changeChartType(MethodCall methodCall, Result result) {
        String type = (String) methodCall.arguments;
        realTimeChart.changeChartType(type);
        result.success(null);
    }

    @Override
    public void dispose() {}

}
