import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

final date24h = DateFormat('MMM dd yyyy HH:mm:ss', LocaleKeys.locale.tr());
final date12h = DateFormat('MMM dd yyyy hh:mm:ss a', LocaleKeys.locale.tr());
final dateFormatUTC = DateFormat('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');

class FlushBarMy {
  static Flushbar succesBar({@required String text}) {
    return Flushbar(
      message: text,
      backgroundColor: Colors.black,
      icon: Icon(
        Icons.check_circle,
        color: Colors.green[300],
      ),
      leftBarIndicatorColor: Colors.green[300],
      animationDuration: Duration(milliseconds: 700),
      duration: Duration(seconds: 2),
      onTap: (flushbar) => flushbar.dismiss(),
    );
  }

  static Flushbar errorBar({@required String text}) {
    return Flushbar(
      message: text,
      backgroundColor: Colors.black,
      icon: Icon(
        Icons.warning,
        color: Colors.red[300],
      ),
      leftBarIndicatorColor: Colors.red[300],
      animationDuration: Duration(milliseconds: 700),
      duration: Duration(seconds: 2),
      onTap: (flushbar) => flushbar.dismiss(),
    );
  }
}
