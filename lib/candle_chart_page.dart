import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterscichartproject/charts/sci_candle_chart.dart';

class CandleChartPage extends StatefulWidget {
  @override
  _CandleChartPageState createState() => _CandleChartPageState();
}

class _CandleChartPageState extends State<CandleChartPage> {
  CandleChartController _controller;

  @override
  void initState() {
    super.initState();
    _initTickStream();
  }

  void _initTickStream() async {
    WebSocket ws;
    try {
      ws = await WebSocket.connect(
          'wss://ws.binaryws.com/websockets/v3?app_id=1089');

      if (ws?.readyState == WebSocket.open) {
        ws.listen(
          (response) {
            final data = Map<String, dynamic>.from(json.decode(response));
            _loadAPIResponse(data);
          },
          onDone: () => print('Done!'),
          onError: (e) => throw new Exception(e),
        );
        ws.add(json.encode({
          "ticks_history": "R_50",
          "adjust_start_time": 1,
          "count": 30,
          "end": "latest",
          "start": 1,
          "style": "candles",
          "subscribe": 1,
        }));
      }
    } catch (e) {
      ws?.close();
      print('Error: $e');
    }
  }

  void _loadAPIResponse(Map<String, dynamic> data) {
    switch (data['msg_type']) {
      case 'candles':
        _controller.loadHistoryCandles(data['candles']);
        break;
      case 'ohlc':
        _controller.addOHLC(data['ohlc']);
        break;
    }
  }

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
