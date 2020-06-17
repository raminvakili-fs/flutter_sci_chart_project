package com.example.flutterscichartproject.sci.candle;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.example.flutterscichartproject.data.PriceBar;
import com.example.flutterscichartproject.data.PriceSeries;
import com.example.flutterscichartproject.sci.RealTimeChart;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import static io.flutter.plugin.common.MethodChannel.Result;

public class FlutterCandleStick implements PlatformView, MethodCallHandler {
    private RealTimeChart realTimeChart;

    FlutterCandleStick(Context context, BinaryMessenger messenger, int id) {
        MethodChannel methodChannel = new MethodChannel(messenger, "SciCandleChart" + id);
        methodChannel.setMethodCallHandler(this);
        realTimeChart = new RealTimeChart(context, false);
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
        } else if ("loadHistoryCandles".equals(methodCall.method)) {
            loadHistoryCandles(methodCall, result);
        } else if ("addOHLC".equals(methodCall.method)) {
            addOHLC(methodCall, result);
        } else {
            result.notImplemented();
        }

    }

    private void changeChartType(MethodCall methodCall, Result result) {
        String type = (String) methodCall.arguments;
        realTimeChart.changeChartType(type);
        result.success(null);
    }

    private void loadHistoryCandles(MethodCall methodCall, Result result) {
        final HashMap argMap = (HashMap) methodCall.arguments;
        final ArrayList<HashMap> candlesList = (ArrayList<HashMap>) argMap.get("candles");
        PriceSeries prices = new PriceSeries();
        for (HashMap candleMap: candlesList) {
            prices.add(new PriceBar(new Date((long) candleMap.get("epoch")), (double) candleMap.get("open"),
                    (double) candleMap.get("high"), (double) candleMap.get("low"),(double) candleMap.get("close"), 0L));
        }
        realTimeChart.startRealTimeChart(prices);
        result.success(null);
    }

    private void addOHLC(MethodCall methodCall, Result result) {
        final HashMap argMap = (HashMap) methodCall.arguments;
        PriceBar newOHLC = new PriceBar(new Date((long) argMap.get("open_time")), (double) argMap.get("open"),
                (double) argMap.get("high"), (double) argMap.get("low"), (double) argMap.get("close"), 0L);
        realTimeChart.onNewPrice(newOHLC);
        result.success(null);
    }

    @Override
    public void dispose() {
    }

}
