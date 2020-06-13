import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void LineChartCreatedCallback(LineChartController controller);

const String lineChartKey = 'SciLineChart';

class SciLineChart extends StatefulWidget {
  const SciLineChart({
    Key key,
    this.onLineChartCreated,
  }) : super(key: key);

  final LineChartCreatedCallback onLineChartCreated;

  @override
  State<StatefulWidget> createState() => SciLineChartState();
}

class SciLineChartState extends State<SciLineChart> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: lineChartKey,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: lineChartKey,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text(
      '$defaultTargetPlatform is not yet supported by the map view plugin',
    );
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onLineChartCreated == null) {
      return;
    }
    widget.onLineChartCreated(new LineChartController(id));
  }
}

class LineChartController {
  LineChartController(int id) {
    this._channel = new MethodChannel('$lineChartKey$id');
  }

  MethodChannel _channel;

  Future<void> loadUrl(String url) async {
    return _channel.invokeMethod('loadUrl', url);
  }
}
