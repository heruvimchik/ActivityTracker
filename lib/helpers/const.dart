import 'package:intl/intl.dart';
import 'package:upTimer/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

final date24h = DateFormat('MMM dd yyyy HH:mm:ss', LocaleKeys.locale.tr());
final date12h = DateFormat('MMM dd yyyy hh:mm:ss a', LocaleKeys.locale.tr());
final dateFormatUTC = DateFormat('yyyy-MM-dd\'T\'HH:mm:ss.sss\'Z\'');
