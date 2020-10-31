import 'dart:io';
import 'package:activityTracker/widgets/line.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/helpers/timer_handler.dart';

class ExportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dateTimeRange = context.select<DaysProvider, DateTimeRange>(
        (daysProvider) => daysProvider.dateRange);
    final proj = Provider.of<ProjectsProvider>(context).projects;
    List<Project> filteredProjects = [];
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
      if (timersStop.isNotEmpty)
        filteredProjects.add(pro.copyWith(updRecords: timersStop));
    });
    return filteredProjects.isEmpty
        ? Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      height: 120,
                      child: Image.asset(
                        'assets/export.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Text(
                    LocaleKeys.NoActivityPeriod.tr(),
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  )
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    height: 130,
                    child: Image.asset(
                      'assets/export.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                ExportProjects(filteredProjects: filteredProjects)
              ],
            ),
          );
  }
}

class ExportProjects extends StatefulWidget {
  ExportProjects({@required this.filteredProjects}) {
    filteredProjects.forEach((element) {
      _selectedProjects.add(element.projectID);
    });
  }
  final List<String> _selectedProjects = [];
  final List<Project> filteredProjects;

  @override
  _ExportProjectsState createState() => _ExportProjectsState();
}

class _ExportProjectsState extends State<ExportProjects> {
  final dateFormat = DateFormat('yyyy-MM-dd');
  final hourFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final List<String> headers = [
      LocaleKeys.ActivityHint.tr(),
      LocaleKeys.Date.tr(),
      LocaleKeys.Start.tr(),
      LocaleKeys.End.tr(),
      LocaleKeys.Duration.tr(),
    ];
    return Column(children: [
      Stack(
        children: [
          Align(
            child: Container(
              width: 230,
              child: RaisedButton(
                textColor: Colors.white,
                color: Colors.indigo,
                shape: StadiumBorder(),
                child: Text(
                  LocaleKeys.ExportCSV.tr(),
                  style: TextStyle(fontSize: 13),
                ),
                onPressed: () async {
                  List<List<String>> data = [];
                  widget.filteredProjects.forEach((project) {
                    if (widget._selectedProjects.indexWhere(
                            (element) => element == project.projectID) >=
                        0) {
                      List<Record> timersStop = project.records;
                      timersStop.forEach((record) {
                        List<String> row = [];
                        row.add(project.description);
                        row.add(dateFormat.format(record.startTime));
                        row.add(hourFormat.format(record.startTime));
                        row.add(hourFormat.format(record.endTime));
                        row.add(Duration(
                                seconds: record.endTime
                                    .difference(record.startTime)
                                    .inSeconds)
                            .formatDuration());
                        data.add(row);
                      });
                    }
                  });
                  data.sort((a, b) =>
                      DateTime.parse(a[1]).compareTo(DateTime.parse(b[1])));
                  data.insert(0, headers);
                  String csv = ListToCsvConverter().convert(data);
                  Directory directory = await getExternalStorageDirectory();
                  final String localPath =
                      '${directory.path}/activityTracker.csv';
                  File file = File(localPath);
                  await file.writeAsString(csv, flush: true);
                  await Share.shareFiles([localPath], text: 'Export');
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Checkbox(
                activeColor: Colors.indigo,
                tristate: true,
                value: widget._selectedProjects.length == 0
                    ? false
                    : widget._selectedProjects.length !=
                            widget.filteredProjects.length
                        ? null
                        : true,
                onChanged: (value) {
                  if (widget._selectedProjects.length !=
                      widget.filteredProjects.length) {
                    widget._selectedProjects.clear();
                    widget.filteredProjects.forEach((element) {
                      widget._selectedProjects.add(element.projectID);
                    });
                  } else
                    widget._selectedProjects.clear();
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
      ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: widget.filteredProjects.reversed
            .map((pr) => CheckboxListTile(
                  secondary: CircleAvatar(
                    child: Text(
                      '${pr.description.trim().substring(0, 1)}',
                      style: TextStyle(
                          color: pr.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Color(pr.color.value),
                    radius: 15.0,
                  ),
                  title: Text(pr.description,
                      style: TextStyle(
                          color: Theme.of(context)
                              .appBarTheme
                              .textTheme
                              .headline6
                              .color)),
                  value: widget._selectedProjects
                      .any((projectID) => projectID == pr.projectID),
                  activeColor: Colors.indigo,
                  onChanged: (_) => setState(() {
                    if (widget._selectedProjects
                        .any((projectID) => projectID == pr.projectID)) {
                      widget._selectedProjects.removeWhere(
                          (projectID) => projectID == pr.projectID);
                    } else {
                      widget._selectedProjects.add(pr.projectID);
                    }
                  }),
                ))
            .toList(),
      ),
    ]);
  }
}
