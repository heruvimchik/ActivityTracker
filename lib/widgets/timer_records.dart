import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upTimer/helpers/timer_handler.dart';
import 'package:upTimer/models/project.dart';

class TimerRecords extends StatefulWidget {
  const TimerRecords({
    Key key,
    @required this.prj,
  }) : super(key: key);

  final Project prj;

  @override
  _TimerRecordsState createState() => _TimerRecordsState();
}

class _TimerRecordsState extends State<TimerRecords> {
  Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (ModalRoute.of(context).isCurrent && isRunning(widget.prj)) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timers = widget.prj.records.where((timer) => timer.endTime != null);
    Duration run = Duration(
        seconds: timers.fold(
            0,
            (int sum, Record t) =>
                sum + t.endTime.difference(t.startTime).inSeconds));
    final timerRun = widget.prj.records
        .firstWhere((timer) => timer.endTime == null, orElse: () => null);
    if (timerRun != null) {
      DateTime now = DateTime.now();
      run += Duration(seconds: now.difference(timerRun.startTime).inSeconds);
    }
    return Flexible(
        fit: FlexFit.loose,
        child: Text(
          run.formatDuration(),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ));
  }
}
