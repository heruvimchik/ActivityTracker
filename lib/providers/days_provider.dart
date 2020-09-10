import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:upTimer/models/project.dart';
import 'package:upTimer/widgets/day_grouping.dart';

class DaysProvider with ChangeNotifier {
  List<Project> _daysProjects;
  List<DayGrouping> _days;
  List<DayGrouping> _initialDays;
  DateTimeRange _dateRange;

  List<DayGrouping> get days => _days;
  DateTimeRange get dateRange => _dateRange;

  set daysProjects(List<Project> value) {
    _daysProjects = value;
    _initialDays = _daysProjects.reversed.fold(<DayGrouping>[], _groupDays);
    _days = _initialDays;
    if (_dateRange != null) {
      _days = _days
          .where((day) =>
              (day.date.isAfter(_dateRange.start.subtract(Duration(days: 1))) &&
                  day.date.isBefore(_dateRange.end.add(Duration(days: 1)))))
          .toList();
    }
    _days.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  set dateRange(DateTimeRange value) {
    _dateRange = value;
    _days = _initialDays;
    if (_dateRange != null) {
      _days = _days
          .where((day) =>
              (day.date.isAfter(_dateRange.start.subtract(Duration(days: 1))) &&
                  day.date.isBefore(_dateRange.end.add(Duration(days: 1)))))
          .toList();
    }
    _days.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<DayGrouping> _groupDays(List<DayGrouping> days, Project project) {
    days = project.records.reversed.fold(days,
        (List<DayGrouping> daysRecords, Record record) {
      bool newDay = daysRecords.isEmpty ||
          !daysRecords.any((DayGrouping day) =>
              day.date.year == record.startTime.year &&
              day.date.month == record.startTime.month &&
              day.date.day == record.startTime.day);
      if (newDay) {
        daysRecords.add(DayGrouping(DateTime(
          record.startTime.year,
          record.startTime.month,
          record.startTime.day,
        )));
      }
      final day = daysRecords.indexWhere((DayGrouping day) =>
          day.date.year == record.startTime.year &&
          day.date.month == record.startTime.month &&
          day.date.day == record.startTime.day);
      if (daysRecords[day]
              .entries
              .indexWhere((index) => index.projectID == project.projectID) <
          0) {
        daysRecords[day].entries.add(Project(
              records: <Record>[],
              color: project.color,
              projectID: project.projectID,
              description: project.description,
            ));
      }
      daysRecords[day]
          .entries
          .firstWhere((element) => element.projectID == project.projectID)
          .records
          .add(record);
      return daysRecords;
    });
    return days;
  }
}
