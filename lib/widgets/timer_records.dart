import 'dart:async';

import 'package:flutter/material.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/models/project.dart';

class TimerRecords extends StatefulWidget {
  TimerRecords({@required this.prj}) {
    final timers = prj.records.where((timer) => timer.endTime != null);
    _run = Duration(
        seconds: timers.fold(
            0,
            (int sum, Record t) =>
                sum + t.endTime.difference(t.startTime).inSeconds));
  }
  Duration _run;
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
    Duration time = widget._run;
    final timerRun = widget.prj.records
        .firstWhere((timer) => timer.endTime == null, orElse: () => null);
    if (timerRun != null) {
      DateTime now = DateTime.now();
      time += Duration(seconds: now.difference(timerRun.startTime).inSeconds);
    }
    return Flexible(
        fit: FlexFit.loose,
        child: Text(
          time.formatDuration(),
          maxLines: 2,
          overflow: TextOverflow.clip,
        ));
  }
}
