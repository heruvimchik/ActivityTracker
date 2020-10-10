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

  Future<void> loadPrefs;
  SharedPreferences _prefs;
  bool _hour24;
  bool _darkTheme;
  int _firstDay;
  int _language;

  List<String> get dayOfWeek => [..._dayOfWeek];
  List<String> get languageList => [..._languageList];
  bool get hour24 => _hour24;
  bool get darkTheme => _darkTheme;
  int get firstDay => _firstDay;
  int get language => _language;

  SettingsProvider() {
    loadPrefs = _getSettings();
  }

  Future<void> _getSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _hour24 = _prefs.getBool("hour24") ?? true;
    _darkTheme = _prefs.getBool("darkTheme") ?? false;
    _firstDay = _prefs.getInt("firstDay") ?? 0;
    _language = _prefs.getInt("language") ?? 0;
    if (_language < 0 || _language > _languageList.length - 1) _language = 0;
    if (_firstDay < 0 || _firstDay > _dayOfWeek.length - 1) _firstDay = 0;
    return;
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
