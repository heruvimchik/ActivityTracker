import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/providers/settings_provider.dart';
import 'package:activityTracker/screens/add_record_screen.dart';

import 'project_item.dart';

class DayGrouping extends StatelessWidget {
  final Days day;

  DayGrouping(this.day);

  bool get _isRunning {
    final running = day.entries.indexWhere((prj) {
      for (Record rec in prj.records) {
        if (rec.endTime == null) return true;
      }
      return false;
    });
    return running >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    Duration run = Duration();
    day.entries.forEach((entry) {
      final timersDays =
          entry.records.where((record) => record.endTime != null);
      run = Duration(
          seconds: timersDays.fold(
              run.inSeconds,
              (int sum, Record t) =>
                  sum + t.endTime.difference(t.startTime).inSeconds));
    });
    return ExpansionTile(
      initiallyExpanded: isNow(now, day.date) ||
          isNow(yesterday, day.date) ||
          day.entries.length == 1 ||
          _isRunning,
      key: Key(day.date.toString()),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DateName(date: day.date),
          Text(
            run.formatDuration(),
            style: TextStyle(color: Colors.grey[700], fontSize: 15),
          ),
        ],
      ),
      children: <Widget>[
        ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => Dismissible(
                  key: Key('${day.entries[index].projectID}'),
                  background: Card(
                    color: Theme.of(context).errorColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child:
                              Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    margin:
                        EdgeInsets.only(right: 15, left: 15, top: 4, bottom: 4),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    context.read<ProjectsProvider>().deleteDayProject(
                        project: day.entries[index], date: day.date);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ProjectItem(
                        project: day.entries[index], scrollable: true),
                  ),
                ),
            itemCount: day.entries.length),
      ],
    );
  }
}

class DayGroupingRecords extends StatelessWidget {
  final DateTime date;
  final projectID;
  final List<Record> daysRecords;

  const DayGroupingRecords({this.date, this.projectID, this.daysRecords});

  bool get _isRunning {
    for (Record rec in daysRecords) {
      if (rec.endTime == null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final timersRecords = daysRecords.where((record) => record.endTime != null);
    Duration run = Duration();
    run = Duration(
        seconds: timersRecords.fold(
            run.inSeconds,
            (int sum, Record t) =>
                sum + t.endTime.difference(t.startTime).inSeconds));

    final hour24 = context.select((SettingsProvider value) => value.hour24);
    final timeFormat = hour24 ? DateFormat('H:mm') : DateFormat('h:mm a');
    return ExpansionTile(
      initiallyExpanded: isNow(now, date) ||
          isNow(yesterday, date) ||
          daysRecords.length == 1 ||
          _isRunning,
      key: Key(date.toString()),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DateName(date: date),
          Text(
            run.formatDuration(),
            style: TextStyle(color: Colors.grey[700], fontSize: 15),
          ),
        ],
      ),
      children: <Widget>[
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) => Dismissible(
            key: Key('_rec_${daysRecords[index].recordID}'),
            background: Card(
              color: Theme.of(context).errorColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                ],
              ),
              margin: EdgeInsets.only(right: 15, left: 15, top: 4, bottom: 4),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              context
                  .read<ProjectsProvider>()
                  .deleteRecord(projectID, daysRecords[index].recordID);
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 1, horizontal: 15),
              child: ListTile(
                title: Row(
                  children: <Widget>[
                    Text(
                      timeFormat
                          .format(daysRecords[index].startTime)
                          .toLowerCase(),
                      style: TextStyle(fontSize: 14),
                    ),
                    daysRecords[index].endTime == null
                        ? Text(' - ...')
                        : Text(
                            ' - ' +
                                timeFormat
                                    .format(daysRecords[index].endTime)
                                    .toLowerCase(),
                            style: TextStyle(fontSize: 14),
                          ),
                  ],
                ),
                trailing: daysRecords[index].endTime == null
                    ? Text(LocaleKeys.Running.tr(),
                        style: TextStyle(color: Colors.red, fontSize: 14))
                    : Text(daysRecords[index]
                        .endTime
                        .difference(daysRecords[index].startTime)
                        .formatDuration()),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddRecordScreen(
                        record: daysRecords[index], projectId: projectID))),
              ),
            ),
          ),
          itemCount: daysRecords.length,
        ),
      ],
    );
  }
}

class DateName extends StatelessWidget {
  final DateTime date;

  DateName({this.date});

  @override
  Widget build(BuildContext context) {
    final DateFormat _dateFormatYear =
        DateFormat('EEE, MMM dd, yyyy', context.locale.toString());
    final DateFormat _dateFormat =
        DateFormat('EEE, MMM dd', context.locale.toString());

    Text dateName = Text('');
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (isNow(now, date))
      dateName = Text(LocaleKeys.Today.tr(),
          style: TextStyle(fontWeight: FontWeight.w500));
    else if (isNow(yesterday, date))
      dateName = Text(LocaleKeys.Yesterday.tr(),
          style: TextStyle(fontWeight: FontWeight.w500));
    else if (date.year == now.year)
      dateName = Text(_dateFormat.format(date),
          style: TextStyle(fontWeight: FontWeight.w500));
    else
      dateName = Text(_dateFormatYear.format(date),
          style: TextStyle(fontWeight: FontWeight.w500));
    return dateName;
  }
}
