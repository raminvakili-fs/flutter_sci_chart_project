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
        realTimeChart = new RealTimeChart(context);
    }

    @Override
    public View getView() {
        return realTimeChart.getChartLayout();
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        switch (methodCall.method) {
            case "changeChartType":
                changeChartType(methodCall, result);
                break;
            case "loadHistoryCandles":
                loadHistoryCandles(methodCall, result);
                break;
            case "addOHLC":
                addOHLC(methodCall, result);
                break;
            case "scrollToCurrentTick":
                realTimeChart.scrollToCurrentTick();
                break;
            default:
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
        for (HashMap candleMap : candlesList) {
            prices.add(new PriceBar(new Date((long) candleMap.get("epoch")),
                    (candleMap.get("open") instanceof Integer) ? 1.0 * (int) (candleMap.get("open")) : (double) (candleMap.get("open")),
                    (candleMap.get("high") instanceof Integer) ? 1.0 * (int) (candleMap.get("high")) : (double) (candleMap.get("high")),
                    (candleMap.get("low") instanceof Integer) ? 1.0 * (int) (candleMap.get("low")) : (double) (candleMap.get("low")),
                    (candleMap.get("close") instanceof Integer) ? 1.0 * (int) (candleMap.get("close")) : (double) (candleMap.get("close")),
                    0L));
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
