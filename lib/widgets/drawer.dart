import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upTimer/generated/locale_keys.g.dart';
import 'package:upTimer/providers/settings_provider.dart';
import 'package:upTimer/screens/backup/backup_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 47, bottom: 10, left: 10),
            child: Text(
              LocaleKeys.Settings.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const Divider(
            color: Colors.grey,
            height: 1,
          ),
          SizedBox(
            height: 10,
          ),
          Selector<SettingsProvider, bool>(
            selector: (_, sett) => sett.hour24,
            builder: (context, value, _) => SwitchListTile(
              dense: true,
              title: Text(
                LocaleKeys.HourFMT.tr(),
                style: TextStyle(fontSize: 13),
              ),
              value: value,
              onChanged: (newValue) => settings.setHour24(newValue),
              activeColor: Colors.indigo,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Selector<SettingsProvider, bool>(
            selector: (_, sett) => sett.darkTheme,
            builder: (context, value, _) => SwitchListTile(
              dense: true,
              title: Text(
                LocaleKeys.DarkTheme.tr(),
                style: TextStyle(fontSize: 13),
              ),
              value: value,
              onChanged: (newValue) => settings.seTheme(newValue),
              activeColor: Colors.indigo,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Selector<SettingsProvider, int>(
            selector: (_, sett) => sett.firstDay,
            builder: (context, value, _) => ChooseSetting(
              title: LocaleKeys.BeginWeek.tr(),
              listValue: settings.dayOfWeek[value].tr(),
              value: value,
              onTap: settings.setFirstDay,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Selector<SettingsProvider, int>(
            selector: (_, sett) => sett.language,
            builder: (context, value, _) {
              return ChooseSetting(
                title: LocaleKeys.Language.tr(),
                listValue: settings.languageList[value],
                value: value,
                onTap: settings.setLanguage,
              );
            },
          ),
          SizedBox(
            height: 10,
          ),
          InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Backup / Restore',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    margin: const EdgeInsets.all(14),
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      size: 18,
                    ),
                  )
                ],
              ),
            ),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BackupScreen(),
                )),
          ),
        ],
      ),
    );
  }
}

class ChooseSetting extends StatelessWidget {
  final String title;
  final String listValue;
  final int value;
  final Function(int) onTap;

  const ChooseSetting({this.title, this.listValue, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_left,
                size: 18,
              ),
              onPressed: () {
                int v = value - 1;
                onTap(v);
              },
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Text(
              listValue,
              style: TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_right, size: 18),
            onPressed: () {
              int v = value + 1;
              onTap(v);
            },
          ),
        ],
      ),
    );
  }
}
