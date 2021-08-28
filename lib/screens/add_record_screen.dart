import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/providers/settings_provider.dart';
import 'package:activityTracker/widgets/line.dart';

class AddRecordScreen extends StatefulWidget {
  final String projectId;
  final Record record;
  const AddRecordScreen({this.record, this.projectId});

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final dateFormat = DateFormat('EEE, MMM dd, yyyy', LocaleKeys.locale.tr());
  DateTime dateNew;
  DateTime startNew;
  DateTime endNew;

  bool get _isDateRight {
    final st = DateTime(
        0,
        0,
        0,
        startNew?.hour ?? 0,
        startNew?.minute ?? 0,
        startNew?.second ?? 0,
        startNew?.millisecond ?? 0,
        startNew?.microsecond ?? 0);
    final end = DateTime(
        0,
        0,
        0,
        endNew?.hour ?? 0,
        endNew?.minute ?? 0,
        endNew?.second ?? 0,
        endNew?.millisecond ?? 0,
        endNew?.microsecond ?? 0);
    if (endNew == null) {
      final nowtime = DateTime(
          dateNew.year,
          dateNew.month,
          dateNew.day,
          startNew?.hour ?? 0,
          startNew?.minute ?? 0,
          startNew?.second ?? 0,
          startNew?.millisecond ?? 0,
          startNew?.microsecond ?? 0);
      DateTime now = DateTime.now();
      if (now.isAtSameMomentAs(nowtime)) return true;
      return now.isAfter(nowtime);
    }
    if (end.isAtSameMomentAs(st)) return true;
    return end.isAfter(st);
  }

  bool get _isRunning {
    if (widget.record != null && widget.record.endTime == null) return true;
    return false;
  }

  @override
  void initState() {
    DateTime now = DateTime.now();
    if (widget.record == null) {
      dateNew = now;
      startNew = now;
      endNew = now;
    } else {
      dateNew = widget.record.startTime;
      startNew = widget.record.startTime;
      endNew = widget.record.endTime;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hour24 = context.select((SettingsProvider value) => value.hour24);
    final timeFormat = hour24 ? DateFormat('H:mm:ss') : DateFormat('h:mm:ss a');
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(
          LocaleKeys.Record.tr(),
          style: TextStyle(fontSize: 17),
        ),
        actions: <Widget>[
          widget.record == null
              ? Container()
              : IconButton(
                  icon: Icon(Icons.delete_forever),
                  onPressed: () {
                    context
                        .read<ProjectsProvider>()
                        .deleteRecord(widget.projectId, widget.record.recordID);
                    Navigator.of(context).pop();
                  },
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      LocaleKeys.Date,
                      style: TextStyle(fontSize: 15),
                    ).tr(),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_left),
                      onPressed: () => setState(() {
                        dateNew = DateTime(
                            dateNew.year, dateNew.month, dateNew.day - 1);
                      }),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            initialDate: dateNew ?? DateTime.now(),
                            lastDate: endNew == null
                                ? DateTime.now()
                                : DateTime(2100));
                        if (date != null && date != dateNew)
                          setState(() => dateNew = date);
                      },
                      child: Text(dateFormat.format(dateNew),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_right),
                      onPressed: (endNew == null &&
                              DateTime.now().isBefore(DateTime(dateNew.year,
                                  dateNew.month, dateNew.day + 1)))
                          ? null
                          : () => setState(() {
                                dateNew = DateTime(dateNew.year, dateNew.month,
                                    dateNew.day + 1);
                              }),
                    ),
                  ),
                ],
              ),
            ),
            Line(),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      LocaleKeys.Start,
                      style: TextStyle(fontSize: 15),
                    ).tr(),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_left),
                      onPressed: () => setState(() {
                        startNew = DateTime(
                            dateNew.year,
                            dateNew.month,
                            dateNew.day,
                            startNew.hour,
                            startNew.minute - 5,
                            startNew.second,
                            startNew.millisecond,
                            startNew.microsecond);
                      }),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: GestureDetector(
                        onTap: () => hour24
                            ? DatePicker.showTimePicker(context,
                                locale: LocaleType.values[
                                    int.parse(LocaleKeys.locValue.tr())],
                                onConfirm: (date) =>
                                    setState(() => startNew = date),
                                currentTime: startNew)
                            : DatePicker.showTime12hPicker(context,
                                locale: LocaleType.values[
                                    int.parse(LocaleKeys.locValue.tr())],
                                onConfirm: (date) =>
                                    setState(() => startNew = date),
                                currentTime: startNew),
                        child: Text(timeFormat.format(startNew).toLowerCase(),
                            textAlign: TextAlign.center,
                            style: _isDateRight
                                ? TextStyle(fontSize: 15)
                                : TextStyle(color: Colors.red, fontSize: 15)),
                      ),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_right),
                      onPressed: (!_isDateRight && endNew == null)
                          ? null
                          : () => setState(() {
                                startNew = DateTime(
                                    dateNew.year,
                                    dateNew.month,
                                    dateNew.day,
                                    startNew.hour,
                                    startNew.minute + 5,
                                    startNew.second,
                                    startNew.millisecond,
                                    startNew.microsecond);
                              }),
                    ),
                  ),
                ],
              ),
            ),
            Line(),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      LocaleKeys.End,
                      style: TextStyle(fontSize: 15),
                    ).tr(),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_left),
                      onPressed: _isRunning
                          ? null
                          : () => setState(() {
                                endNew = DateTime(
                                    dateNew.year,
                                    dateNew.month,
                                    dateNew.day,
                                    endNew.hour,
                                    endNew.minute - 5,
                                    endNew.second,
                                    endNew.millisecond,
                                    endNew.microsecond);
                              }),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: GestureDetector(
                        onTap: _isRunning
                            ? null
                            : () => hour24
                                ? DatePicker.showTimePicker(context,
                                    locale: LocaleType.values[
                                        int.parse(LocaleKeys.locValue.tr())],
                                    onConfirm: (date) =>
                                        setState(() => endNew = date),
                                    currentTime: endNew)
                                : DatePicker.showTime12hPicker(context,
                                    locale: LocaleType.values[
                                        int.parse(LocaleKeys.locValue.tr())],
                                    onConfirm: (date) =>
                                        setState(() => endNew = date),
                                    currentTime: endNew),
                        child: Text(
                            !_isRunning
                                ? timeFormat.format(endNew).toLowerCase()
                                : LocaleKeys.Running.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_right),
                      onPressed: _isRunning
                          ? null
                          : () => setState(() {
                                endNew = DateTime(
                                    dateNew.year,
                                    dateNew.month,
                                    dateNew.day,
                                    endNew.hour,
                                    endNew.minute + 5,
                                    endNew.second,
                                    endNew.millisecond,
                                    endNew.microsecond);
                              }),
                    ),
                  ),
                ],
              ),
            ),
            Line(),
            _isRunning
                ? Container()
                : Container(
                    //height: 50,
                    padding: EdgeInsets.only(left: 10, right: 10, top: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: Text(
                            LocaleKeys.Duration.tr(),
                            style: TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Flexible(fit: FlexFit.loose, child: Container()),
                        Container(
                          width: 90,
                          //flex: 2,
                          //fit: FlexFit.loose,
                          child: Text(
                            Duration(
                                    seconds: DateTime(
                                            0,
                                            0,
                                            0,
                                            endNew.hour,
                                            endNew.minute,
                                            endNew.second,
                                            endNew.millisecond,
                                            endNew.microsecond)
                                        .difference(DateTime(
                                            0,
                                            0,
                                            0,
                                            startNew.hour,
                                            startNew.minute,
                                            startNew.second,
                                            startNew.millisecond,
                                            startNew.microsecond))
                                        .inSeconds)
                                .formatDuration(),
                            style: TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Flexible(fit: FlexFit.loose, child: Container()),
                      ],
                    ),
                  ),
            //Expanded(child: Container()),
            Container(
              padding: EdgeInsets.only(top: 20),
              width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: StadiumBorder(),
                  primary: Colors.indigo,
                ),
                child: Text(
                  LocaleKeys.Save.tr(),
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: !_isDateRight
                    ? null
                    : () {
                        final startRec = DateTime(
                            dateNew.year,
                            dateNew.month,
                            dateNew.day,
                            startNew.hour,
                            startNew.minute,
                            startNew.second,
                            startNew.millisecond,
                            startNew.microsecond);
                        final endRec = DateTime(
                            dateNew.year,
                            dateNew.month,
                            dateNew.day,
                            endNew?.hour ?? 0,
                            endNew?.minute ?? 0,
                            endNew?.second ?? 0,
                            endNew?.millisecond ?? 0,
                            endNew?.microsecond ?? 0);
                        final rec = Record(
                            recordID: widget.record?.recordID ?? null,
                            startTime: startRec,
                            endTime: endNew != null ? endRec : endNew);
                        context.read<ProjectsProvider>().updateRecord(
                            projectID: widget.projectId, updRecord: rec);
                        Navigator.of(context).pop();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
