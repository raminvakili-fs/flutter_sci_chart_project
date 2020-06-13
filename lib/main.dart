import 'package:flutter/material.dart';
import 'package:flutterscichartproject/candle_chart_page.dart';
import 'package:flutterscichartproject/line_chart_page.dart';

import 'charts/sci_candle_chart.dart';
import 'charts/sci_line_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar : AppBar(
          title: Text('Platform View'),
        ),
        body: ChartsList(),
      ),
    );
  }
}

class ChartsList extends StatelessWidget {
  const ChartsList({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text('LineChart'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => LineChartPage()
          )),
        ),
        ListTile(
          title: Text('CandleChart'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => CandleChartPage()
          )),
        )
      ],
    );
  }
}


