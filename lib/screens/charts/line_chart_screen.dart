import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/widgets/day_grouping.dart';

class LineChartScreen extends StatefulWidget {
  final List<MyRow> days;
  final Color color;

  LineChartScreen({this.days, this.color});
  @override
  _LineChartScreenState createState() => _LineChartScreenState();
}

class _LineChartScreenState extends State<LineChartScreen> {
  DateTime _time;
  Map<String, num> _measures;
  int changeIndex = 1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    DateTime filter;
    switch (changeIndex) {
      case 0:
        filter = DateTime(now.year, now.month, now.day - 7);
        break;
      case 1:
        filter = DateTime(now.year, now.month - 1, now.day);
        break;
      case 2:
        filter = DateTime(now.year, now.month - 3, now.day);
        break;
      case 3:
        filter = DateTime(now.year, now.month - 6, now.day);
        break;
      case 4:
        filter = DateTime(now.year - 1, now.month, now.day);
        break;
    }
    List<MyRow> data = [];
    if (filter != null) {
      data = widget.days
          .where((day) =>
              day.timeStamp.isAfter(filter) && day.timeStamp.isBefore(now))
          .toList();
    } else {
      data = widget.days;
    }
    final List<charts.Series<MyRow, DateTime>> seriesList = [
      charts.Series<MyRow, DateTime>(
        id: 'Statistics',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(widget.color),
        areaColorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(widget.color.withOpacity(0.5)),
        domainFn: (MyRow row, _) => row.timeStamp,
        measureFn: (MyRow row, _) => row.hour,
        data: data,
      )
    ];
    final simpleCurrencyFormatter =
        charts.BasicNumericTickFormatterSpec.fromNumberFormat(
            NumberFormat.compact());
    Color col = Theme.of(context).appBarTheme.textTheme.headline6.color;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 5,
          ),
          _time != null ? DateName(date: _time) : Text(''),
          Text(_measures != null
              ? Duration(seconds: ((_measures['Statistics'] * 60) * 60).toInt())
                  .formatDuration()
              : ''),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height -
                220 -
                AppBar().preferredSize.height,
            child: charts.TimeSeriesChart(
              seriesList,
              defaultRenderer: charts.LineRendererConfig(includeArea: true),
              animate: false,
              selectionModels: [
                charts.SelectionModelConfig(
                  type: charts.SelectionModelType.info,
                  changedListener: _onSelectionChanged,
                )
              ],
              primaryMeasureAxis: charts.NumericAxisSpec(
                  tickFormatterSpec: simpleCurrencyFormatter,
                  renderSpec: charts.GridlineRendererSpec(
                    lineStyle: charts.LineStyleSpec(
                        thickness: 1,
                        color: charts.ColorUtil.fromDartColor(
                            col.withOpacity(0.0))),
                    labelStyle: charts.TextStyleSpec(
                        color: charts.ColorUtil.fromDartColor(
                            col.withOpacity(0.5))),
                  )),
              domainAxis: charts.DateTimeAxisSpec(
                  renderSpec: charts.GridlineRendererSpec(
                    lineStyle: charts.LineStyleSpec(
                        thickness: 1,
                        color: charts.ColorUtil.fromDartColor(
                            col.withOpacity(0.2))),
                    labelStyle: charts.TextStyleSpec(
                        color: charts.ColorUtil.fromDartColor(
                            col.withOpacity(0.5))),
                  ),
                  tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
                    hour: charts.TimeFormatterSpec(
                        format: '', transitionFormat: ''),
                    minute: charts.TimeFormatterSpec(
                        format: '', transitionFormat: ''),
                    month: charts.TimeFormatterSpec(
                        format: 'MMM', transitionFormat: 'MMM'),
                    //DateFormat('MMM dd', LocaleKeys.locale.tr())
                    day: charts.TimeFormatterSpec(
                        format: 'd', transitionFormat: 'MMM dd'),
                  )),
            ),
          ),
          SizedBox(
            height: 7,
          ),
          ChangeDate(
            color: widget.color,
            tabIndex: changeIndex,
            onChangeIndex: (tabIndex) {
              if (changeIndex != tabIndex)
                setState(() => changeIndex = tabIndex);
            },
          ),
          SizedBox(
            height: 90,
          ),
        ],
      ),
    );
  }

  _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;
    DateTime time;
    final measures = <String, num>{};

    if (selectedDatum.isNotEmpty) {
      time = selectedDatum.first.datum.timeStamp;
      selectedDatum.forEach((charts.SeriesDatum datumPair) {
        measures[datumPair.series.displayName] = datumPair.datum.hour;
      });
    }
    // Request a build.
    if (_time != time && time != null) {
      setState(() {
        _time = time;
        _measures = measures;
      });
    }
  }
}

class ChangeDate extends StatelessWidget {
  final Color color;
  final int tabIndex;
  final Function(int tabIndex) onChangeIndex;

  ChangeDate({this.color, this.onChangeIndex, this.tabIndex});

  final List<String> labels = [
    '7' + 'D'.tr(),
    '1M',
    '3M',
    '6M',
    '1' + 'Y'.tr(),
    'All'.tr()
  ];

  @override
  Widget build(BuildContext context) {
    Color textCol =
        color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
            right: Radius.circular(50.0), left: Radius.circular(50.0)),
        color: color.withOpacity(0.9),
      ),
      height: 30,
      width: MediaQuery.of(context).size.width * 0.9,
      child: Row(
        children: List.generate(
          labels.length,
          (index) {
            return Expanded(
                child: InkWell(
                    onTap: () => onChangeIndex(index),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(labels[index],
                          style: TextStyle(
                              color: index == tabIndex
                                  ? textCol
                                  : textCol.withOpacity(0.4),
                              fontSize: 13)),
                    )));
          },
        ),
      ),
    );
  }
}

class MyRow {
  final DateTime timeStamp;
  final double hour;
  MyRow(this.timeStamp, this.hour);
}
