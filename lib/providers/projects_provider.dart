import 'dart:ui';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:activityTracker/helpers/db_helpers.dart';
import 'package:activityTracker/models/project.dart';

class ProjectsProvider with ChangeNotifier {
  final DaysProvider _daysProvider;
  List<Project> _projects = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Project> get projects => [..._projects];

  ProjectsProvider(this._daysProvider) {
    fetchProjects();
  }

  Future<void> fetchProjects({bool initNotification = true}) async {
    final dataList = await DBHelper.db.getData();
    _projects = dataList
        .map(
          (item) => Project.fromDB(item),
        )
        .toList();
    _isLoaded = true;
    notifyListeners();
    _daysProvider.setProjectsDays(_projects);
    if (initNotification)
      _initLocalNotification();
    else
      flutterLocalNotificationsPlugin.cancelAll();
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initLocalNotification() async {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    final initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: null);

    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false);

    final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS);

    //await _deleteNotificationChannel();
    //await _createNotificationChannel();
    //await flutterLocalNotificationsPlugin.cancelAll();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _selectNotification);
  }

  Future<void> _createNotificationChannel() async {
    var androidNotificationChannel = AndroidNotificationChannel(
      'NotificationChannelId',
      'NotificationChannel',
      'NotificationChannelDescription',
      enableVibration: false,
      showBadge: false,
      playSound: false,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> _deleteNotificationChannel() async {
    const channelId = 'NotificationChannelId';
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel(channelId);
  }

  Future _selectNotification(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      final result = payload.split(' ');
      if (result[0] == 'Start')
        stopRecord(result[1]);
      else
        addRecord(result[1]);
    }
  }

  Future<void> _showNotification(
      {required Project project, required bool start}) async {
    final timers = project.records.where((timer) => timer.endTime != null);
    Duration run = Duration(
        seconds: timers.fold(
            0,
            (int sum, Record timer) =>
                sum + timer.endTime!.difference(timer.startTime!).inSeconds));
    final now = DateTime.now();
    final timerRun =
        project.records.firstWhereOrNull((timer) => timer.endTime == null);
    if (timerRun != null) {
      run += Duration(seconds: now.difference(timerRun.startTime!).inSeconds);
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'NotificationChannelId',
      'NotificationChannel',
      'description',
      color: project.color,
      visibility: NotificationVisibility.public,
      showWhen: start,
      usesChronometer: start,
      when: start
          ? DateTime(now.year, now.month, now.day, now.hour, now.minute,
                  now.second - run.inSeconds)
              .millisecondsSinceEpoch
          : null,
      onlyAlertOnce: true,
      autoCancel: false,
      ongoing: start,
      enableVibration: false,
      channelShowBadge: false,
      playSound: false,
    );
    final iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    final id = project.projectID.replaceAll('-', '');
    final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
    await flutterLocalNotificationsPlugin.show(
        number,
        project.description + (start ? '' : '  ${run.formatDuration()}'),
        start ? LocaleKeys.StopTimer.tr() : LocaleKeys.StartTimer.tr(),
        platformChannelSpecifics,
        payload: (start ? 'Start ' : 'Stop ') + project.projectID);
  }

  Future<void> addProject(String description, Color color) async {
    final record = Record(
      recordID: Uuid().v4(),
      startTime: DateTime.now(),
      endTime: null,
    );
    final newProject = Project(
      projectID: Uuid().v4(),
      color: color,
      records: <Record>[record],
      description: description,
    );
    _projects.add(newProject);
    notifyListeners();
    _daysProvider.addProjectDays(newProject);
    await DBHelper.db.insert(newProject.toMap());
    _showNotification(project: _projects.last, start: true);
  }

  Future<void> updateProject(
      {required String? updProjectId,
      String? description,
      Color? color}) async {
    final index = _projects.indexWhere((prj) => prj.projectID == updProjectId);
    if (index < 0) return;
    _projects[index] = _projects[index].copyWith(
      updDescription: description,
      updColor: color,
    );
    notifyListeners();
    _daysProvider.updateProjectDays(_projects[index]);

    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);
    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    }
  }

  Future<void> updateRecord(
      {required String projectID, required Record updRecord}) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) return;
    final indRec = _projects[index]
        .records
        .indexWhere((timer) => timer.recordID == updRecord.recordID);

    if (indRec >= 0) {
      _projects[index].records[indRec] =
          _projects[index].records[indRec].copyWith(
                endTime: updRecord.endTime,
                startTime: updRecord.startTime,
              );
      _daysProvider.updateRecordDays(
          projectID, _projects[index].records[indRec]);
    } else {
      final record = Record(
        recordID: Uuid().v4(),
        startTime: updRecord.startTime,
        endTime: updRecord.endTime,
      );
      _projects[index].records.add(record);
      _daysProvider.addNewRecord(_projects[index], record);
    }
    notifyListeners();
    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);
    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    }
    //else
    //  _showNotification(project: _projects[index], start: false);
  }

  Future<void> addRecord(String? projectID) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) {
      final id = projectID!.replaceAll('-', '');
      final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
      flutterLocalNotificationsPlugin.cancel(number);
      return;
    }
    final running = _projects[index]
        .records
        .firstWhereOrNull((timer) => timer.endTime == null);
    if (running != null) return;
    final record = Record(
      recordID: Uuid().v4(),
      startTime: DateTime.now(),
      endTime: null,
    );
    _projects[index].records.add(record);
    notifyListeners();
    _daysProvider.addNewRecord(_projects[index], record);
    await DBHelper.db.update(_projects[index]);
    _showNotification(project: _projects[index], start: true);
  }

  Future<void> stopRecord(String projectID) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) {
      final id = projectID.replaceAll('-', '');
      final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
      flutterLocalNotificationsPlugin.cancel(number);
      return;
    }
    final now = DateTime.now();
    final indexStop =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);
    if (indexStop < 0) return;
    final start = _projects[index].records[indexStop].startTime!;
    if (now.year != start.year ||
        now.month != start.month ||
        now.day != start.day) {
      final days = now.difference(start).inDays;
      if (days < 0) {
        _projects[index].records[indexStop].endTime = now;
      } else {
        _projects[index].records[indexStop].endTime =
            DateTime(start.year, start.month, start.day, 23, 59, 59, 999, 0);
      }
      _daysProvider.updateRecordDays(
          projectID, _projects[index].records[indexStop]);
      for (int day = 1; day <= days; day++) {
        final record = Record(
          recordID: Uuid().v4(),
          startTime:
              DateTime(start.year, start.month, start.day + day, 0, 0, 0),
          endTime: (day == days)
              ? now
              : DateTime(
                  start.year, start.month, start.day + day, 23, 59, 59, 999, 0),
        );
        _projects[index].records.add(record);
        _daysProvider.addNewDay(_projects[index], record);
      }
      _daysProvider.update();
    } else {
      _projects[index].records[indexStop].endTime = now;
      _daysProvider.updateRecordDays(
          projectID, _projects[index].records[indexStop]);
    }
    notifyListeners();
    await DBHelper.db.update(_projects[index]);
    _showNotification(project: _projects[index], start: false);
  }

  Future<void> deleteProject(Project project) async {
    await DBHelper.db.delete(project);
    final id = project.projectID.replaceAll('-', '');
    final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
    flutterLocalNotificationsPlugin.cancel(number);
    _daysProvider.deleteProjectDays(project.projectID);
    _projects.removeWhere((prj) => prj.projectID == project.projectID);
    notifyListeners();
  }

  Future<void> deleteRecord(String projectID, String? recordID) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) return;
    final runningDeleted = _projects[index]
        .records
        .firstWhereOrNull((timer) => timer.endTime == null);

    _projects[index]
        .records
        .removeWhere((element) => element.recordID == recordID);
    notifyListeners();
    _daysProvider.deleteRecordDays(projectID, recordID);

    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);

    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    } else if (runningDeleted?.recordID == recordID)
      _showNotification(project: _projects[index], start: false);
  }

  Future<void> deleteDayProject(
      {required Project project, required DateTime date}) async {
    final index =
        _projects.indexWhere((prj) => prj.projectID == project.projectID);
    if (index < 0) return;
    bool runningDeleted = false;
    project.records.forEach((deletedRecord) {
      _projects[index]
          .records
          .removeWhere((record) => record.recordID == deletedRecord.recordID);
      if (deletedRecord.endTime == null) runningDeleted = true;
    });

    notifyListeners();
    _daysProvider.deleteProjectInDay(project.projectID, date);

    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);

    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    } else if (runningDeleted)
      _showNotification(project: _projects[index], start: false);
  }

  Future<void> clear() async {
    DBHelper.db.clear();
    _projects.clear();
    notifyListeners();
  }
}
