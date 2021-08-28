import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/screens/charts/bar_chart_screen.dart';
import 'package:activityTracker/widgets/day_grouping.dart';
import 'package:activityTracker/widgets/navigation_bar.dart';
import 'package:activityTracker/widgets/timer_records.dart';

import 'add_project_screen.dart';
import 'add_record_screen.dart';
import 'charts/line_chart_screen.dart';

enum Options { addRecord, editProject, deleteProject }

class RecordsScreen extends StatefulWidget {
  final Project project;
  RecordsScreen({this.project});

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _selectedIndex = 0;

  final _tabs = [
    NavigationBarTab(
      title: LocaleKeys.Records,
      icon: Icons.timer,
    ),
    NavigationBarTab(
      title: LocaleKeys.DailyActivity,
      icon: CupertinoIcons.chart_bar_alt_fill,
    ),
    NavigationBarTab(
      title: LocaleKeys.Statistic,
      icon: Icons.show_chart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final prj = Provider.of<ProjectsProvider>(context).projects.firstWhere(
        (proj) => proj.projectID == widget.project.projectID,
        orElse: () => null);

    if (prj == null) return Text('');
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: ListTile(
          leading: CircleAvatar(
            child: Text(
              '${prj.description.trim().substring(0, 1)}',
              style: TextStyle(
                  color: prj.color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Color(prj.color.value),
            radius: 20.0,
          ),
          title: Text(
            prj.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              TimerRecords(prj: prj),
            ],
          ),
        ),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: (Options selected) {
              if (selected == Options.addRecord) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddRecordScreen(
                        record: null, projectId: widget.project.projectID)));
              } else if (selected == Options.deleteProject) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                      title: Text(LocaleKeys.DeleteDialog.tr()),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(ctx).pop();
                              context
                                  .read<ProjectsProvider>()
                                  .deleteProject(widget.project);
                            },
                            child: Text(LocaleKeys.Yes.tr())),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(LocaleKeys.No.tr())),
                      ]),
                );
              } else if (selected == Options.editProject) {
                showModalBottomSheet(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(25.0))),
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => AddProjectScreen(
                        project: prj, title: LocaleKeys.EditActivity.tr()));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.add_circle, color: Colors.indigoAccent),
                    Text('   ${LocaleKeys.NewRecord.tr()}',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
                value: Options.addRecord,
              ),
              PopupMenuItem(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.edit, color: Colors.indigoAccent),
                    Text(
                      '   ${LocaleKeys.EditActivity.tr()}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                value: Options.editProject,
              ),
              PopupMenuItem(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.delete_forever,
                        color: Colors.indigoAccent),
                    Text('   ${LocaleKeys.DeleteActivity.tr()}',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
                value: Options.deleteProject,
              ),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: <Widget>[
        ListRecords(projectId: widget.project.projectID),
        BarChartScreen(project: prj),
        Consumer<DaysProvider>(
          builder: (context, daysProvider, _) {
            final List<MyRow> days = [];
            daysProvider.initialDays.forEach((day) {
              final prj = day.entries.firstWhere(
                  (p) => p.projectID == widget.project.projectID,
                  orElse: () => null);
              if (prj != null) {
                List<Record> rec = prj.records
                    .where((element) => element.endTime != null)
                    .toList();
                days.add(MyRow(
                    day.date,
                    rec.fold(
                        0,
                        (double sum, Record rec) =>
                            sum +
                            rec.endTime
                                    .difference(rec.startTime)
                                    .inSeconds
                                    .toDouble() /
                                3600)));
              }
            });
            return LineChartScreen(days: days, color: prj.color);
          },
        ),
      ].elementAt(_selectedIndex),
      floatingActionButton: isRunning(prj)
          ? FloatingActionButton(
              onPressed: () => context
                  .read<ProjectsProvider>()
                  .stopRecord(widget.project.projectID),
              backgroundColor: Colors.red.withOpacity(0.8),
              child: Icon(Icons.pause, color: Colors.white))
          : FloatingActionButton(
              onPressed: () => context
                  .read<ProjectsProvider>()
                  .addRecord(widget.project.projectID),
              backgroundColor: Colors.indigo.withOpacity(0.8),
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
      bottomNavigationBar: NavigationBar(
        tabIndex: _selectedIndex,
        onChangeTabIndex: (index) {
          if (_selectedIndex != index) setState(() => _selectedIndex = index);
        },
        tabs: _tabs,
      ),
    );
  }
}

class ListRecords extends StatelessWidget {
  final String projectId;
  const ListRecords({this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DaysProvider>(
      builder: (context, daysProvider, _) {
        List<DayGroupingRecords> recordsByDays = [];
        daysProvider.initialDays.forEach((day) {
          final prj = day.entries
              .firstWhere((p) => p.projectID == projectId, orElse: () => null);
          if (prj != null) {
            recordsByDays.add(DayGroupingRecords(
              date: day.date,
              projectID: projectId,
              daysRecords: prj.records.reversed.toList(),
            ));
          }
        });
        if (recordsByDays.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    height: 120,
                    child: Image.asset(
                      'assets/hourglass.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Text(
                    LocaleKeys.NoRecords.tr(),
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  ),
                  SizedBox(
                    height: 80,
                  )
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemBuilder: (_, index) => recordsByDays[index],
          itemCount: recordsByDays.length,
        );
      },
    );
  }
}
