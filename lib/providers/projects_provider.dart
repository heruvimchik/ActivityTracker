import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:upTimer/helpers/timer_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:upTimer/helpers/db_helpers.dart';
import 'package:upTimer/models/project.dart';

class ProjectsProvider with ChangeNotifier {
  Future<void> loadDb;
  List<Project> _projects;
  List<Project> get projects => [..._projects];

  ProjectsProvider() {
    loadDb = fetchProjects();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initLocalNotification() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: null);

    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

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

  Future _selectNotification(String payload) async {
    if (payload != null && payload.isNotEmpty) {
      final result = payload.split(' ');
      if (result[0] == 'Start')
        stopRecord(result[1]);
      else
        addRecord(result[1]);
    }
  }

  Future<void> _showNotification({Project project, bool start}) async {
    final timers = project.records.where((timer) => timer.endTime != null);
    Duration run = Duration(
        seconds: timers.fold(
            0,
            (int sum, Record timer) =>
                sum + timer.endTime.difference(timer.startTime).inSeconds));
    final now = DateTime.now();
    final timerRun = project.records
        .firstWhere((timer) => timer.endTime == null, orElse: () => null);
    if (timerRun != null) {
      run += Duration(seconds: now.difference(timerRun.startTime).inSeconds);
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'NotificationChannelId',
      'NotificationChannel',
      'description',
      color: project.color,
      visibility: NotificationVisibility.Public,
      showWhen: start,
      when: DateTime(now.year, now.month, now.day, now.hour, now.minute,
              now.second - run.inSeconds)
          .millisecondsSinceEpoch,
      onlyAlertOnce: true,
      autoCancel: false,
      ongoing: start,
      enableVibration: false,
      channelShowBadge: false,
      playSound: false,
    );
    final iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    final id = project.projectID.replaceAll('-', '');
    final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
    await flutterLocalNotificationsPlugin.show(
        number,
        project.description + (start ? '' : '  ${run.formatDuration()}'),
        start ? 'Stop' : 'Start',
        platformChannelSpecifics,
        payload: (start ? 'Start ' : 'Stop ') + project.projectID);
  }

  Future<void> addProject(String description, Color color) async {
    final record = Record(
      recordID: Uuid().v4(),
      startTime: DateTime.now(),
      endTime: null,
    );
    final newPlace = Project(
      projectID: Uuid().v4(),
      color: color,
      records: <Record>[record],
      description: description,
    );
    _projects.add(newPlace);
    notifyListeners();
    await DBHelper.db.insert(newPlace.toMap());
    _showNotification(project: _projects.last, start: true);
  }

  Future<void> fetchProjects({bool initNotification = true}) async {
    final dataList = await DBHelper.db.getData();
    _projects = dataList
        .map(
          (item) => Project.fromDB(item),
        )
        .toList();
    notifyListeners();
    if (initNotification)
      _initLocalNotification();
    else
      flutterLocalNotificationsPlugin.cancelAll();
    return;
  }

  Future<void> updateProject(
      {@required String updProjectId, String description, Color color}) async {
    final index = _projects.indexWhere((prj) => prj.projectID == updProjectId);
    if (index < 0) return;
    _projects[index] = _projects[index].copyWith(
      updDescription: description,
      updColor: color,
    );
    notifyListeners();
    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);
    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    }
  }

  Future<void> updateRecord(
      {@required String projectID, Record updRecord}) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    final indRec = _projects[index]
        .records
        .indexWhere((timer) => timer.recordID == updRecord.recordID);

    if (indRec >= 0) {
      _projects[index].records[indRec] =
          _projects[index].records[indRec].copyWith(
                endTime: updRecord.endTime,
                startTime: updRecord.startTime,
              );
    } else {
      final record = Record(
        recordID: Uuid().v4(),
        startTime: updRecord.startTime,
        endTime: updRecord.endTime,
      );
      _projects[index].records.add(record);
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

  Future<void> addRecord(String projectID) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) {
      final id = projectID.replaceAll('-', '');
      final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
      flutterLocalNotificationsPlugin.cancel(number);
      return;
    }
    final running = _projects[index]
        .records
        .firstWhere((timer) => timer.endTime == null, orElse: () => null);
    if (running != null) return;

    final record = Record(
      recordID: Uuid().v4(),
      startTime: DateTime.now(),
      endTime: null,
    );

    _projects[index].records.add(record);
    notifyListeners();
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
    final start = _projects[index].records[indexStop].startTime;

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
      for (int day = 1; day <= days; day++) {
        _projects[index].records.add(Record(
              recordID: Uuid().v4(),
              startTime:
                  DateTime(start.year, start.month, start.day + day, 0, 0, 0),
              endTime: (day == days)
                  ? now
                  : DateTime(start.year, start.month, start.day + day, 23, 59,
                      59, 999, 0),
            ));
      }
    } else {
      _projects[index].records[indexStop].endTime = now;
    }
    notifyListeners();
    await DBHelper.db.update(_projects[index]);
    _showNotification(project: _projects[index], start: false);
  }

  Future<void> deleteProject(Project project) async {
    _projects.removeWhere((prj) => prj.projectID == project.projectID);
    notifyListeners();
    await DBHelper.db.delete(project);
    final id = project.projectID.replaceAll('-', '');
    final number = int.parse(id.substring(0, 8), radix: 16) & 0x7fffffff;
    flutterLocalNotificationsPlugin.cancel(number);
  }

  Future<void> deleteRecord(String projectID, String recordID) async {
    final index = _projects.indexWhere((prj) => prj.projectID == projectID);
    if (index < 0) return;
    final runningDeleted = _projects[index]
        .records
        .firstWhere((timer) => timer.endTime == null, orElse: () => null);

    _projects[index]
        .records
        .removeWhere((element) => element.recordID == recordID);
    notifyListeners();
    await DBHelper.db.update(_projects[index]);
    final running =
        _projects[index].records.indexWhere((timer) => timer.endTime == null);

    if (running >= 0) {
      _showNotification(project: _projects[index], start: true);
    } else if (runningDeleted?.recordID == recordID)
      _showNotification(project: _projects[index], start: false);
  }

  Future<void> clear() async {
    DBHelper.db.clear();
    _projects.clear();
    notifyListeners();
  }
}
