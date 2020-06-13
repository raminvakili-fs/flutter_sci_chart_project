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
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () => _controller?.loadUrl('url'),
            ),
          )
        ],
      ),
    );
  }
}
