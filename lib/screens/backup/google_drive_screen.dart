import 'package:activityTracker/helpers/const.dart';
import 'package:activityTracker/providers/premium_provider.dart';
import 'package:activityTracker/screens/pro_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/providers/auth_provider.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:activityTracker/providers/settings_provider.dart';

import 'restore_screen.dart';

class GoogleDriveScreen extends StatefulWidget {
  @override
  _GoogleDriveScreenState createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  final date24h = DateFormat('MMM dd yyyy HH:mm:ss', LocaleKeys.locale.tr());
  final date12h = DateFormat('MMM dd yyyy hh:mm:ss a', LocaleKeys.locale.tr());
  final _flushBarSuccess =
      FlushBarMy.succesBar(text: LocaleKeys.SuccessBackup.tr());
  final _flushBarError = FlushBarMy.errorBar(text: LocaleKeys.ErrorBackup.tr());

  @override
  Widget build(BuildContext context) {
    final authGoogle = Provider.of<AuthProvider>(context, listen: false);
    final hourFormat = context.select((SettingsProvider value) => value.hour24)
        ? date24h
        : date12h;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isLoadingFiles =
        context.select((AuthProvider value) => value.isLoadingFiles);
    final isPro = context.watch<PremiumProvider>().isPro;
    return Column(
      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: StadiumBorder(),
              primary: Colors.indigo,
            ),
            onPressed: isLoadingFiles
                ? null
                : () async {
                    try {
                      await authGoogle.uploadFileToGoogleDrive();
                      if (mounted)
                        _flushBarSuccess
                          ..dismiss()
                          ..show(context);
                    } catch (error) {
                      if (mounted)
                        _flushBarError
                          ..dismiss()
                          ..show(context);
                    }
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isLoadingFiles)
                  SizedBox(
                    height: 20.0,
                    width: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15, top: 6, bottom: 6, right: 15),
                  child: Text(
                    LocaleKeys.BackupButton.tr(),
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            )),
        ListTile(
          dense: true,
          title: Text(
            LocaleKeys.Restore.tr(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: Selector<AuthProvider, Future<ga.FileList>>(
            selector: (_, auth) => auth.filesLoaded,
            builder: (context, futureFileList, _) => FutureBuilder<ga.FileList>(
              future: futureFileList,
              builder: (context, AsyncSnapshot<ga.FileList> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Text(LocaleKeys.Loading.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w200,
                      ));

                if (snapshot.data == null || snapshot.data.files.length == 0)
                  return Text('');
                return Text(
                  LocaleKeys.LastBackup.tr() +
                      ': ' +
                      hourFormat.format(DateTime.fromMillisecondsSinceEpoch(
                          int.tryParse(snapshot.data.files.first.name ?? '') ??
                              0)),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Roboto'),
                );
              },
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 18,
          ),
          onTap: isLoadingFiles
              ? null
              : () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => RestoreScreen(),
                  ));
                },
        ),
        Selector<SettingsProvider, int>(
          selector: (_, sett) => sett.autoBackup,
          builder: (context, autoBackup, _) => ListTile(
            dense: true,
            title: Text(
              LocaleKeys.AutoBackup.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              autoBackup == 0
                  ? settings.autoBackupList[autoBackup].tr()
                  : LocaleKeys.day.plural(
                      int.tryParse(settings.autoBackupList[autoBackup])),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Roboto'),
            ),
            trailing: isPro
                ? Icon(
                    Icons.keyboard_arrow_right,
                    size: 18,
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.grey[300]),
                    child: Text(
                      LocaleKeys.Premium.tr(),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
            onTap: () => isPro
                ? showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20.0))),
                    builder: (context) => SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ListView(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: List.generate(
                            settings.autoBackupList.length,
                            (index) => RadioListTile<int>(
                              activeColor: Colors.indigo,
                              title: Text(index == 0
                                  ? settings.autoBackupList[index].tr()
                                  : LocaleKeys.day.plural(int.tryParse(
                                      settings.autoBackupList[index]))),
                              value: index,
                              groupValue: autoBackup,
                              dense: true,
                              onChanged: (value) {
                                settings.setAutoBackup(value);
                                authGoogle.setTimerAuto();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        )),
                  )
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProScreen(),
                    )),
          ),
        ),
        ListTile(
            dense: true,
            title: Text(
              LocaleKeys.Account.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Roboto'),
            ),
            trailing: Text(
              LocaleKeys.Logout.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            onTap: () => authGoogle.logoutFromGoogle()),
      ],
    );
  }
}
