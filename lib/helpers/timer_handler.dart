import 'package:activityTracker/models/project.dart';

extension Format on Duration {
  String formatDuration() {
    if (this == null) return '';
    return this.inHours.toString().padLeft(2, "0") +
        ":" +
        (this.inMinutes - (this.inHours * 60)).toString().padLeft(2, "0") +
        ":" +
        (this.inSeconds - (this.inMinutes * 60)).toString().padLeft(2, "0");
  }
}

bool isRunning(Project projRun) {
  if (projRun.records.isEmpty) return false;
  final running = projRun.records
      .firstWhere((timer) => timer.endTime == null, orElse: () => null);
  return running != null;
}

bool isNow(DateTime now, DateTime date) {
  if (now.day == date.day && now.month == date.month && now.year == date.year)
    return true;
  return false;
}
