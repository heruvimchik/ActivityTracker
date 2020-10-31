import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/widgets/line.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen();
  @override
  _ChartsScreenState createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ItemScrollController scrollController = ItemScrollController();
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final dateTimeRange = context.select<DaysProvider, DateTimeRange>(
        (daysProvider) => daysProvider.dateRange);

    List<ProjectDuration> projectDuration = <ProjectDuration>[];
    final proj = Provider.of<ProjectsProvider>(context).projects;

    double totalHours = 0;
    proj.forEach((pro) {
      List<Record> timersStop =
          pro.records.where((record) => record.endTime != null).toList();
      if (dateTimeRange != null) {
        timersStop = timersStop.where((timer) {
          final date = DateTime(
              timer.startTime.year, timer.startTime.month, timer.startTime.day);
          return (date
                  .isAfter(dateTimeRange.start.subtract(Duration(days: 1))) &&
              date.isBefore(dateTimeRange.end.add(Duration(days: 1))));
        }).toList();
      }
      double duration = 0;
      duration = timersStop.fold(
          duration,
          (double sum, Record rec) =>
              sum +
              rec.endTime.difference(rec.startTime).inSeconds.toDouble() /
                  3600);
      totalHours += duration;
      if (timersStop.isNotEmpty)
        projectDuration.add(ProjectDuration(
            project: Project(color: pro.color, description: pro.description),
            duration: duration));
    });
    projectDuration = projectDuration.reversed.toList();
    if (projectDuration.isEmpty) {
      return Center(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              height: 120,
              child: Image.asset(
                'assets/report.png',
                fit: BoxFit.fill,
              ),
            ),
            Text(
              LocaleKeys.NoActivityPeriod.tr(),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ));
    }

    return MediaQuery.of(context).orientation == Orientation.portrait
        ? buildColumn(projectDuration, totalHours)
        : buildRow(projectDuration, totalHours);
  }

  Widget buildRow(List<ProjectDuration> projectDuration, double totalHours) {
    return Row(
      children: [
        buildStack(projectDuration, totalHours,
            radius: MediaQuery.of(context).size.height * 0.15),
        buildListProject(projectDuration),
      ],
    );
  }

  Column buildColumn(List<ProjectDuration> projectDuration, double totalHours) {
    return Column(
      children: [
        buildStack(projectDuration, totalHours,
            radius: MediaQuery.of(context).size.height * 0.1),
        buildListProject(projectDuration),
      ],
    );
  }

  Widget buildStack(List<ProjectDuration> projectDuration, double totalHours,
      {double radius}) {
    final hours = Duration(minutes: (totalHours * 60).toInt());
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
                pieTouchData: PieTouchData(touchCallback: (pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse.touchInput is FlLongPressEnd ||
                        pieTouchResponse.touchInput is FlPanEnd) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex = pieTouchResponse.touchedSectionIndex;
                      if (_touchedIndex != null && _touchedIndex >= 0)
                        scrollController.scrollTo(
                            index: _touchedIndex,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic);
                    }
                  });
                }),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 0,
                centerSpaceRadius: radius,
                sections: List.generate(projectDuration.length, (int index) {
                  final projectDur = projectDuration[index];
                  final procent =
                      (100.0 * projectDuration[index].duration / totalHours);
                  final String title =
                      procent >= 1 ? "${procent.toStringAsFixed(0)}%" : '';
                  return PieChartSectionData(
                    titlePositionPercentageOffset: 0.5,
                    value: projectDur.duration,
                    color: projectDur.project.color,
                    title: title,
                    titleStyle: TextStyle(
                        fontSize: _touchedIndex == index ? 20 : 13,
                        color: projectDur.project.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white),
                    radius: _touchedIndex == index ? 70 : 50,
                  );
                })),
          ),
          Text(
            totalHours.toInt().toStringAsFixed(0) +
                ' ${LocaleKeys.Hrs.tr()} ' +
                (hours.inMinutes - (hours.inHours * 60)).toStringAsFixed(0) +
                ' ${LocaleKeys.Min.tr()}',
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget buildListProject(List<ProjectDuration> projectDuration) {
    return Expanded(
      child: ScrollablePositionedList.builder(
          itemScrollController: scrollController,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () => setState(() {
                if (_touchedIndex == index) {
                  _touchedIndex = -1;
                } else
                  _touchedIndex = index;
              }),
              leading: CircleAvatar(
                child: Text(
                  '${projectDuration[index].project.description.trim().substring(0, 1)}',
                  style: TextStyle(
                      color: projectDuration[index]
                                  .project
                                  .color
                                  .computeLuminance() >
                              0.5
                          ? Colors.black
                          : Colors.white),
                  textAlign: TextAlign.center,
                ),
                backgroundColor:
                    Color(projectDuration[index].project.color.value),
                radius: 15.0,
              ),
              title: Text(
                (Duration(
                            seconds:
                                ((projectDuration[index].duration * 60) * 60)
                                    .toInt()))
                        .formatDuration() +
                    '  ' +
                    projectDuration[index].project.description,
                style: TextStyle(
                    fontWeight: _touchedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
            );
          },
          itemCount: projectDuration.length),
    );
  }
}

class ProjectDuration {
  final Project project;
  final double duration;

  ProjectDuration({this.project, this.duration});
}
