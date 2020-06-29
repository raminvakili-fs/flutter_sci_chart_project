import 'package:flutter/material.dart';
import 'package:flutterscichartproject/api/deriv_connection_websocket.dart';
import 'package:flutterscichartproject/charts/sci_candle_chart.dart';

class CandleChartPage extends StatefulWidget {
  @override
  _CandleChartPageState createState() => _CandleChartPageState();
}

class _CandleChartPageState extends State<CandleChartPage> {
  CandleChartController _controller;
  BinaryAPI _api;
  int _numOfTicks = 0;
  String _tickStyle = 'candles';
  int _granularity = 60;
  int _historySize = 1000;

  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() async {
    _api = BinaryAPI();
    await _api.run();
    setState(() {
      _connected = true;
    });
    _subscribeTick();
  }

  void _reloadChart() async {
    await _api.unsubscribeAll(_tickStyle, shouldForced: true);
    _tickStyle = _granularity == 1 ? 'ticks' : 'candles';
    _subscribeTick();
  }

  void _subscribeTick() {
    final Map<String, dynamic> request = {
      'ticks_history': 'R_50',
      'adjust_start_time': 1,
      'granularity': _granularity > 1 ? _granularity : null,
      'count': _historySize,
      'end': 'latest',
      'start': DateTime.now()
              .subtract(const Duration(days: 20))
              .millisecondsSinceEpoch ~/
          1000,
      'style': _tickStyle,
      'subscribe': 1,
    };
    _api.subscribe('ticks_history', req: request).listen(
      (response) {
        _loadAPIResponse(response);
      },
      onDone: () => print('Done!'),
      onError: (e) => throw new Exception(e),
    );
  }

  void _loadAPIResponse(Map<String, dynamic> data) {
    switch (data['msg_type']) {
      case 'candles':
        _numOfTicks = 0;
        _controller.loadHistoryCandles(data['candles']);
        _numOfTicks += data['candles'].length;
        break;
      case 'ohlc':
        _controller.addOHLC(data['ohlc']);
        _numOfTicks++;
        break;
      case 'history':
        _numOfTicks = 0;
        _controller.loadHistoryTicks(data['history']);
        _numOfTicks += data['history']['times'].length;
        break;
      case 'tick':
        _numOfTicks++;
        _controller.addTick(data['tick']);
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticks: $_numOfTicks',
          style: TextStyle(fontSize: 10),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => _controller.scrollToCurrentTick(),
          ),
          PopupMenuButton<int>(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.access_time),
            ),
            onSelected: (choice) {
              _granularity = choice;
              _reloadChart();
            },
            itemBuilder: (BuildContext context) {
              return {1, 60, 120, 180, 300, 600, 900, 3600}
                  .map((int choice) => PopupMenuItem<int>(
                        value: choice,
                        child: Text('Granularity ${choice}s'),
                      ))
                  .toList();
            },
          ),
          PopupMenuButton<int>(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.history),
            ),
            onSelected: (choice) {
              _historySize = choice;
              _reloadChart();
            },
            itemBuilder: (BuildContext context) {
              return {100, 200, 500, 1000, 2000, 5000}
                  .map((int choice) => PopupMenuItem<int>(
                        value: choice,
                        child: Text('History $choice'),
                      ))
                  .toList();
            },
          ),
          PopupMenuButton<String>(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.multiline_chart),
            ),
            onSelected: (choice) {
              _controller.onIndicator(choice);
            },
            itemBuilder: (BuildContext context) {
              return {'MACD', 'RSI'}
                  .map((String choice) => PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      ))
                  .toList();
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          SciCandleChart(
            onChartCreated: (CandleChartController controller) =>
                _controller = controller,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                color: Colors.white24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      child: Icon(Icons.show_chart),
                      onPressed: () => _controller?.changeChartType('line'),
                    ),
                    FlatButton(
                      child: Icon(Icons.equalizer),
                      onPressed: () => _controller?.changeChartType('candle'),
                    ),
                    FlatButton(
                      child: Icon(Icons.swap_vert),
                      onPressed: () => _controller?.changeChartType('ohlc'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: _connected ? SizedBox.shrink() : CircularProgressIndicator(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.outlined_flag),
        onPressed: () => _controller.addMarker(),
      ),
    );
  }
}
