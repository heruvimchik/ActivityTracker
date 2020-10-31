import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';

class SettingsProvider with ChangeNotifier {
  final List<String> _dayOfWeek = [
    LocaleKeys.Monday,
    LocaleKeys.Sunday,
    LocaleKeys.Saturday,
  ];

  final List<String> _languageList = [
    'English',
    'Русский',
  ];

  final List<String> _autoBackupList = [
    LocaleKeys.Never,
    '1',
    '3',
    '7',
    '14',
    '30',
    '90',
    '180',
  ];

  final List<Duration> autoExpireList = [
    Duration(days: 7200),
    Duration(days: 1),
    //Duration(seconds: 5),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
    Duration(days: 90),
    Duration(days: 180),
  ];

  SharedPreferences _prefs;
  bool _hour24 = true;
  bool _darkTheme = false;
  int _firstDay = 0;
  int _language = 0;
  int _autoBackup = 0;
  DateTime expireDate;
  Future<void> settingsLoaded;

  List<String> get dayOfWeek => [..._dayOfWeek];
  List<String> get languageList => [..._languageList];
  List<String> get autoBackupList => [..._autoBackupList];

  bool get hour24 => _hour24;
  bool get darkTheme => _darkTheme;
  int get autoBackup => _autoBackup;
  int get firstDay => _firstDay;
  int get language => _language;

  SettingsProvider() {
    settingsLoaded = _getSettings();
  }

  Future<void> _getSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _hour24 = _prefs.getBool("hour24") ?? true;
    _darkTheme = _prefs.getBool("darkTheme") ?? false;
    _firstDay = _prefs.getInt("firstDay") ?? 0;
    _language = _prefs.getInt("language") ?? 0;
    _autoBackup = _prefs.getInt("autoBackup") ?? 0;
    final date = _prefs.getString('expireDate');
    if (date != null) expireDate = DateTime.tryParse(date);

    if (_language < 0 || _language > _languageList.length - 1) _language = 0;
    if (_firstDay < 0 || _firstDay > _dayOfWeek.length - 1) _firstDay = 0;
    if (_autoBackup < 0 || _autoBackup > _autoBackupList.length - 1)
      _autoBackup = 0;
    if (_autoBackup > 0 && expireDate == null) setAutoExpire(_autoBackup);

    notifyListeners();
  }

  Future<void> _setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _setInt(String key, int value) async {
    await _prefs.setInt(key, value);
    notifyListeners();
  }

  Future<void> setHour24(bool value) async {
    _hour24 = value;
    await _setBool('hour24', value);
  }

  Future<void> seTheme(bool value) async {
    _darkTheme = value;
    await _setBool('darkTheme', value);
  }

  Future<void> setAutoBackup(int value) async {
    if (value > _autoBackupList.length - 1) value = 0;
    if (value < 0) value = _autoBackupList.length - 1;
    _autoBackup = value;
    await setAutoExpire(value);
    await _setInt('autoBackup', value);
  }

  Future<void> setAutoExpire(int value) async {
    expireDate = DateTime.now().add(autoExpireList[value]);
    await _prefs.setString('expireDate', expireDate.toIso8601String());
  }

  Future<void> setFirstDay(int value) async {
    if (value > _dayOfWeek.length - 1) value = 0;
    if (value < 0) value = _dayOfWeek.length - 1;
    _firstDay = value;
    await _setInt('firstDay', value);
  }

  Future<void> setLanguage(int value) async {
    if (value > _languageList.length - 1) value = 0;
    if (value < 0) value = _languageList.length - 1;
    _language = value;
    await _setInt('language', value);
  }
}
