import 'package:flutter/material.dart';
import 'package:activityTracker/models/project.dart';

class Days {
  final DateTime date;
  final List<Project> entries = <Project>[];
  Days(this.date);
}

class DaysProvider with ChangeNotifier {
  List<Days> _days = [];
  List<Days> _initialDays = [];
  DateTimeRange _dateRange;

  List<Days> get days => [..._days];
  List<Days> get initialDays => [..._initialDays];
  DateTimeRange get dateRange => _dateRange;

  Future<void> setProjectsDays(List<Project> value) async {
    _initialDays = value.reversed.fold(<Days>[], _groupDays);
    _initialDays.sort((a, b) => b.date.compareTo(a.date));
    _notify();
    return;
  }

  void addProjectDays(Project project) {
    final record = project.records[0];
    final newProj = Project(
        color: project.color,
        projectID: project.projectID,
        description: project.description,
        records: <Record>[record]);
    bool newDay = _initialDays.isEmpty ||
        !_initialDays.any((Days day) =>
            day.date.year == record.startTime.year &&
            day.date.month == record.startTime.month &&
            day.date.day == record.startTime.day);
    if (newDay) {
      _initialDays.add(Days(DateTime(
        record.startTime.year,
        record.startTime.month,
        record.startTime.day,
      )));
    }
    _initialDays
        .firstWhere((Days day) =>
            day.date.year == record.startTime.year &&
            day.date.month == record.startTime.month &&
            day.date.day == record.startTime.day)
        .entries
        .insert(0, newProj);
    _notify();
  }

  void updateProjectDays(Project project) {
    _initialDays.forEach((days) {
      Project p = days.entries.firstWhere(
          (entry) => entry.projectID == project.projectID,
          orElse: () => null);
      p?.description = project.description;
      p?.color = project.color;
    });
    _notify();
  }

  void deleteProjectDays(String projectId) {
    _initialDays.forEach((days) {
      days.entries.removeWhere((entry) => entry.projectID == projectId);
    });
    _initialDays.removeWhere((element) => element.entries.isEmpty);
    _notify();
  }

  void deleteRecordDays(String projectId, String recordID) {
    for (Days day in _initialDays) {
      final p = day.entries.indexWhere((entry) => entry.projectID == projectId);
      if (p < 0) continue;
      final r =
          day.entries[p].records.indexWhere((rec) => rec.recordID == recordID);
      if (r < 0) continue;
      day.entries[p].records.removeAt(r);
      if (day.entries[p].records.isEmpty) day.entries.removeAt(p);
      if (day.entries.isEmpty) _initialDays.remove(day);
      break;
    }
    _notify();
  }

  void deleteProjectInDay(String projectId, DateTime date) {
    Days day = _initialDays.firstWhere((element) => element.date == date,
        orElse: () => null);
    if (day == null) return;
    day.entries.removeWhere((entry) => entry.projectID == projectId);
    if (day.entries.isEmpty) _initialDays.remove(day);
    _notify();
  }

  bool addNewDay(Project proj, Record record) {
    bool newDay = _initialDays.isEmpty ||
        !_initialDays.any((Days day) =>
            day.date.year == record.startTime.year &&
            day.date.month == record.startTime.month &&
            day.date.day == record.startTime.day);
    if (newDay) {
      _initialDays.add(Days(DateTime(
        record.startTime.year,
        record.startTime.month,
        record.startTime.day,
      )));
    }

    final dayInit = _initialDays.indexWhere((Days day) =>
        day.date.year == record.startTime.year &&
        day.date.month == record.startTime.month &&
        day.date.day == record.startTime.day);
    if (_initialDays[dayInit]
            .entries
            .indexWhere((index) => index.projectID == proj.projectID) <
        0) {
      _initialDays[dayInit].entries.add(Project(
            records: <Record>[],
            color: proj.color,
            projectID: proj.projectID,
            description: proj.description,
          ));
    }
    _initialDays[dayInit]
        .entries
        .firstWhere((element) => element.projectID == proj.projectID)
        .records
        .add(record);
    return newDay;
  }

  void updateRecordDays(String projectID, Record record) {
    for (Days day in _initialDays) {
      final p = day.entries.indexWhere((entry) => entry.projectID == projectID);
      if (p < 0) continue;
      final r = day.entries[p].records
          .indexWhere((rec) => rec.recordID == record.recordID);
      if (r < 0) continue;
      if (day.entries[p].records[r].startTime.year != record.startTime.year ||
          day.entries[p].records[r].startTime.month != record.startTime.month ||
          day.entries[p].records[r].startTime.day != record.startTime.day) {
        day.entries[p].records.removeAt(r);
        final proj = day.entries.elementAt(p);
        if (day.entries[p].records.isEmpty) day.entries.removeAt(p);
        if (day.entries.isEmpty) _initialDays.remove(day);

        if (addNewDay(proj, record))
          _initialDays.sort((a, b) => b.date.compareTo(a.date));
      } else {
        day.entries[p].records[r].startTime = record.startTime;
        day.entries[p].records[r].endTime = record.endTime;
      }
      break;
    }
    _notify();
  }

  void addNewRecord(Project project, Record record) {
    if (addNewDay(project, record)) {
      _initialDays.sort((a, b) => b.date.compareTo(a.date));
    }
    _notify();
  }

  void update() {
    _initialDays.sort((a, b) => b.date.compareTo(a.date));
    _notify();
  }

  set dateRange(DateTimeRange value) {
    _dateRange = value;
    _notify();
  }

  List<Days> _groupDays(List<Days> days, Project project) {
    days = project.records.fold(days, (List<Days> daysRecords, Record record) {
      bool newDay = daysRecords.isEmpty ||
          !daysRecords.any((Days day) =>
              day.date.year == record.startTime.year &&
              day.date.month == record.startTime.month &&
              day.date.day == record.startTime.day);
      if (newDay) {
        daysRecords.add(Days(DateTime(
          record.startTime.year,
          record.startTime.month,
          record.startTime.day,
        )));
      }
      final day = daysRecords.indexWhere((Days day) =>
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

  void _notify() {
    _days = _initialDays;
    if (_dateRange != null) {
      _days = _days
          .where((day) =>
              (day.date.isAfter(_dateRange.start.subtract(Duration(days: 1))) &&
                  day.date.isBefore(_dateRange.end.add(Duration(days: 1)))))
          .toList();
    }
    notifyListeners();
  }
}
