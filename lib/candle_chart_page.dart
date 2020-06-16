import 'package:flutter/material.dart';
import 'package:flutter_deriv_api/api/common/tick/ohlc.dart';
import 'package:flutter_deriv_api/api/common/tick/tick_base.dart';
import 'package:flutter_deriv_api/api/common/tick/tick_history.dart';
import 'package:flutter_deriv_api/api/common/tick/tick_history_subscription.dart';
import 'package:flutter_deriv_api/basic_api/generated/api.dart';
import 'package:flutter_deriv_api/services/connection/api_manager/base_api.dart';
import 'package:flutter_deriv_api/services/connection/api_manager/connection_information.dart';
import 'package:flutter_deriv_api/services/dependency_injector/injector.dart';
import 'package:flutter_deriv_api/services/dependency_injector/module_container.dart';
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

    _connectToWS();
  }
  void _connectToWS() async {
    ModuleContainer().initialize(Injector.getInjector());
    await Injector.getInjector().get<BaseAPI>().connect(ConnectionInformation(
        appId: '1089', brand: 'binary', endpoint: 'frontend.binaryws.com'));
    _getTickStream();
  }

  void _getTickStream() async {
    try {
      final TickHistorySubscription subscription =
      await TickHistory.fetchTicksAndSubscribe(
        TicksHistoryRequest(
          ticksHistory: 'R_50',
          adjustStartTime: 1,
          count: 20,
          end: 'latest',
          start: 1,
          style: 'candles',
        ),
      );

      _controller.loadHistoryCandles(subscription.tickHistory);

      subscription.tickStream.listen((TickBase tick) {
        final OHLC ohlc = tick;
        if (ohlc != null) {
          _controller.addOHLC(ohlc);
        }
      });
    } on Exception catch (e) {

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
