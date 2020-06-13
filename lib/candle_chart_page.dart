import 'package:flutter/material.dart';
import 'package:flutterscichartproject/charts/sci_candle_chart.dart';

class CandleChartPage extends StatefulWidget {
  @override
  _CandleChartPageState createState() => _CandleChartPageState();
}

class _CandleChartPageState extends State<CandleChartPage> {
  CandleChartController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SciCandleChart'),
      ),
      body: Stack(
        children: <Widget>[
          SciCandleChart(
            onChartCreated: (CandleChartController controller) =>
                _controller = controller,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FlatButton(
                    child: Icon(Icons.show_chart),
                    onPressed: () => _controller?.changeChartType('line'),
                    color: Colors.white10,
                  ),
                  FlatButton(
                    child: Icon(Icons.equalizer),
                    onPressed: () => _controller?.changeChartType('candle'),
                    color: Colors.white10,
                  ),
                  FlatButton(
                    child: Icon(Icons.swap_vert),
                    onPressed: () => _controller?.changeChartType('ohlc'),
                    color: Colors.white10,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
