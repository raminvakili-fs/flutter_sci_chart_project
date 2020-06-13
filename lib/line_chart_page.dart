import 'package:flutter/material.dart';
import 'package:flutterscichartproject/charts/sci_line_chart.dart';

class LineChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SciLineChart'),),
      body: SciLineChart(onLineChartCreated: (LineChartController controller) {

      },),
    );
  }
}
