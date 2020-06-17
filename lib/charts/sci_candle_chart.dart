import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deriv_api/api/common/models/candle_model.dart';
import 'package:flutter_deriv_api/api/common/tick/ohlc.dart';
import 'package:flutter_deriv_api/api/common/tick/tick_history.dart';
import 'package:flutter_deriv_api/api/common/tick/tick_history_subscription.dart';
import 'package:flutter_deriv_api/basic_api/generated/api.dart';
import 'package:flutter_deriv_api/services/connection/api_manager/base_api.dart';
import 'package:flutter_deriv_api/services/connection/api_manager/connection_information.dart';
import 'package:flutter_deriv_api/services/dependency_injector/injector.dart';
import 'package:flutter_deriv_api/services/dependency_injector/module_container.dart';
import 'package:flutter_deriv_api/utils/helpers.dart';

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

  Future<void> loadHistoryCandles(TickHistory tickHistory) async {
    return _channel.invokeMethod('loadHistoryCandles', {
      'candles': tickHistory.candles
          .map((CandleModel candle) => {
                'open': candle.open,
                'close': candle.close,
                'low': candle.low,
                'high': candle.high,
                'epoch': candle.epoch.millisecondsSinceEpoch,
              })
          .toList()
    });
  }

  Future<void> addOHLC(OHLC ohlc) async {
    return _channel.invokeMethod('addOHLC', {
      'open': double.tryParse(ohlc.open),
      'close': double.tryParse(ohlc.close),
      'low': double.tryParse(ohlc.low),
      'high': double.tryParse(ohlc.high),
      'epoch': ohlc.epoch.millisecondsSinceEpoch,
      'open_time': ohlc.openTime.millisecondsSinceEpoch,
      'granularity': ohlc.granularity,
    });
  }
}
