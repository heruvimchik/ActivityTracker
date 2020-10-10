import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/settings_provider.dart';

class BarChartScreen extends StatelessWidget {
  final Project project;
  final List<String> daysOfWeek = const [
    'Sat',
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  const BarChartScreen({this.project});
  @override
  Widget build(BuildContext context) {
    List<Record> timersStop =
        project.records.where((record) => record.endTime != null).toList();
    double totalHours = 0;
    totalHours = timersStop.fold(
        totalHours,
        (double sum, Record rec) =>
            sum +
            rec.endTime.difference(rec.startTime).inSeconds.toDouble() / 3600);
    List<double> weekdaysTotal = [];
    for (int day = 1; day <= 7; day++) {
      final weekday =
          timersStop.where((element) => element.startTime.weekday == day);
      final value = weekday.fold(
          0.0,
          (double sum, Record rec) =>
              sum +
              rec.endTime.difference(rec.startTime).inSeconds.toDouble() /
                  3600);
      weekdaysTotal.add(value);
    }
    double maxy = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait)
      maxy = 60;
    else
      maxy = 130;
    Color col = Theme.of(context).appBarTheme.textTheme.headline6.color;
    final firstDay = context.select((SettingsProvider value) => value.firstDay);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxy,
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.transparent,
                  tooltipBottomMargin: 5,
                  getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.y.toStringAsFixed(1) + '%',
                      TextStyle(
                        fontSize: 13,
                        color: col,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTextStyles: (value) => TextStyle(color: col, fontSize: 14),
                  margin: 30,
                  getTitles: (double value) {
                    final day = value.toInt();
                    return daysOfWeek[day + 2 - firstDay].tr();
                  },
                ),
                leftTitles: SideTitles(showTitles: false),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: List.generate(7, (i) => i)
                  .map((day) => BarChartGroupData(
                        x: day,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            borderRadius: BorderRadius.circular(3),
                            colors: [project.color],
                            width: 30,
                            y: totalHours != 0
                                ? (100.0 * weekdaysTotal[day] / totalHours)
                                : 0,
                          )
                        ],
                        showingTooltipIndicators: [0],
                      ))
                  .toList(),
            ),
          ),
        ),
        SizedBox(height: 100)
      ],
    );
  }
}