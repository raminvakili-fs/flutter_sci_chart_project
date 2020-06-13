package com.example.flutterscichartproject.sci;

import android.content.Context;
import android.view.View;
import android.widget.TextView;


import com.example.flutterscichartproject.RealTimeOhlcChart;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;

public class FlutterOHLC implements PlatformView, MethodCallHandler  {
    private final TextView textView;
    private final MethodChannel methodChannel;
    RealTimeOhlcChart realTimeOhlcChart;

    FlutterOHLC(Context context, BinaryMessenger messenger, int id) {
        textView = new TextView(context);
        methodChannel = new MethodChannel(messenger, "plugins.com.example/ohlc_" + id);
        methodChannel.setMethodCallHandler(this);
        realTimeOhlcChart = new RealTimeOhlcChart(context, true);
        realTimeOhlcChart.startRealTimeChart();
    }

    @Override
    public View getView() {
        return realTimeOhlcChart.getChartLayout();
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
        textView.setText(text);
        result.success(null);
    }

    @Override
    public void dispose() {}
}
