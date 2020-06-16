import 'package:flutter/material.dart';
import 'package:flutter_deriv_api/state/connection/connection_bloc.dart';
import 'package:flutterscichartproject/candle_chart_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CandleChartPage(),
    );
  }
}


