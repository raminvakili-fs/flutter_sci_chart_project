import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void CandleChartCreatedCallback(CandleChartController controller);

const String candleChartKey = 'SciCandleChart';

class SciCandleChart extends StatefulWidget {
  const SciCandleChart({
    Key key,
    this.onChartCreated,
  }) : super(key: key);

  final CandleChartCreatedCallback onChartCreated;

  @override
  State<StatefulWidget> createState() => SciCandleChartState();
}

class SciCandleChartState extends State<SciCandleChart> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: candleChartKey,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: candleChartKey,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text(
      '$defaultTargetPlatform is not yet supported by the map view plugin',
    );
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onChartCreated == null) {
      return;
    }
    widget.onChartCreated(new CandleChartController(id));
  }
}

class CandleChartController {
  CandleChartController(int id) {
    this._channel = new MethodChannel('$candleChartKey$id');
  }

  MethodChannel _channel;

  Future<void> changeChartType(String type) async {
    return _channel.invokeMethod('changeChartType', type);
  }

  Future<void> loadHistoryCandles(List<dynamic> candles) async {
    return _channel.invokeMethod('loadHistoryCandles', {
      'candles': candles
          .map((dynamic candle) => {
                'open': candle['open'],
                'close': candle['close'],
                'low': candle['low'],
                'high': candle['high'],
                'epoch': candle['epoch'] * 1000,
              })
          .toList()
    });
  }

  Future<void> loadHistoryTicks(Map<String, dynamic> history) async {
    final List<Map<String, dynamic>> historyList = <Map<String, dynamic>>[];
    for (int i = 0; i < history['times'].length; i++) {
      historyList.add({
        'open': history['prices'][i],
        'close': history['prices'][i],
        'low': history['prices'][i],
        'high': history['prices'][i],
        'epoch': history['times'][i] * 1000,
      });
    }
    return _channel
        .invokeMethod('loadHistoryCandles', {'candles': historyList});
  }

  Future<void> addOHLC(Map<String, dynamic> ohlc) async {
    return _channel.invokeMethod('addOHLC', {
      'open': double.tryParse(ohlc['open']),
      'close': double.tryParse(ohlc['close']),
      'low': double.tryParse(ohlc['low']),
      'high': double.tryParse(ohlc['high']),
      'epoch': ohlc['epoch'] * 1000,
      'open_time': ohlc['open_time'] * 1000,
      'granularity': ohlc['granularity'],
    });
  }

  Future<void> addTick(Map<String, dynamic> tick) {
    return _channel.invokeMethod('addOHLC', {
      'open': tick['ask'],
      'close': tick['ask'],
      'low': tick['ask'],
      'high': tick['ask'],
      'epoch': tick['epoch'] * 1000,
      'open_time': tick['epoch'] * 1000,
      'granularity': 1,
    });
  }

  Future<void> scrollToCurrentTick() =>
      _channel.invokeMethod('scrollToCurrentTick');

  Future<void> addMarker() =>
      _channel.invokeMethod('addMarker');
}
