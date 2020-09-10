import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upTimer/generated/locale_keys.g.dart';
import 'package:upTimer/helpers/timer_handler.dart';
import 'package:upTimer/models/project.dart';
import 'package:upTimer/providers/projects_provider.dart';
import 'package:upTimer/widgets/day_grouping.dart';
import 'package:upTimer/widgets/timer_records.dart';

import 'add_project_screen.dart';
import 'add_record_screen.dart';

enum Options { addRecord, editProject, deleteProject }

class RecordsScreen extends StatelessWidget {
  final Project project;

  const RecordsScreen({Key key, this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prj = Provider.of<ProjectsProvider>(context).projects.firstWhere(
        (proj) => proj.projectID == project.projectID,
        orElse: () => null);

    if (prj == null) return Text('');
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: ListTile(
          leading: CircleAvatar(
            child: Text(
              '${prj.description.trim().substring(0, 1)}',
              style: TextStyle(color: Colors.white),
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
                        record: null, projectId: project.projectID)));
              } else if (selected == Options.deleteProject) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                      title: Text(LocaleKeys.DeleteDialog.tr()),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(ctx).pop();
                              context
                                  .read<ProjectsProvider>()
                                  .deleteProject(project);
                            },
                            child: Text(LocaleKeys.Yes.tr())),
                        FlatButton(
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
      body: ListRecords(projectId: project.projectID),
      floatingActionButton: isRunning(prj)
          ? FloatingActionButton(
              onPressed: () {
                context.read<ProjectsProvider>().stopRecord(project.projectID);
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.pause, color: Colors.white))
          : FloatingActionButton(
              onPressed: () {
                context.read<ProjectsProvider>().addRecord(project.projectID);
              },
              backgroundColor: Colors.indigo,
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
    );
  }
}

class ListRecords extends StatelessWidget {
  final String projectId;

  const ListRecords({Key key, this.projectId}) : super(key: key);

  List<DayGroupingRecords> _groupDaysRecords(
      List<DayGroupingRecords> days, Record record) {
    bool newDay = days.isEmpty ||
        !days.any((DayGroupingRecords day) =>
            day.date.year == record.startTime.year &&
            day.date.month == record.startTime.month &&
            day.date.day == record.startTime.day);
    if (newDay) {
      days.add(DayGroupingRecords(
          date: DateTime(
            record.startTime.year,
            record.startTime.month,
            record.startTime.day,
          ),
          projectID: projectId));
    }

    days
        .firstWhere((day) =>
            day.date.year == record.startTime.year &&
            day.date.month == record.startTime.month &&
            day.date.day == record.startTime.day)
        .daysRecords
        .add(record);
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final prj = Provider.of<ProjectsProvider>(context, listen: false)
        .projects
        .firstWhere((prj) => prj.projectID == projectId);
    List<DayGroupingRecords> days = prj.records.reversed
        .fold(<DayGroupingRecords>[], _groupDaysRecords)
          ..sort((a, b) => b.date.compareTo(a.date));
    return ListView.builder(
      itemBuilder: (_, index) => days[index],
      itemCount: days.length,
    );
  }
}
