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
}
