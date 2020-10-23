import 'package:activityTracker/helpers/const.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final hour24 = context.select((SettingsProvider value) => value.hour24);
    final hourFormat = hour24 ? date24h : date12h;
    final isLoadingFiles =
        context.select((AuthProvider value) => value.isLoadingFiles);

    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        RaisedButton(
            textColor: Colors.white,
            color: Colors.indigo,
            shape: StadiumBorder(),
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
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            )),
        SizedBox(
          height: 15,
        ),
        InkWell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.Restore.tr(),
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Selector<AuthProvider, Future<ga.FileList>>(
                      selector: (_, auth) => auth.filesLoaded,
                      builder: (context, futureFileList, _) =>
                          FutureBuilder<ga.FileList>(
                        future: futureFileList,
                        builder:
                            (context, AsyncSnapshot<ga.FileList> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Text(LocaleKeys.Loading.tr(),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w200,
                                    fontFamily: 'Roboto'));

                          if (snapshot.data == null ||
                              snapshot.data.files.length == 0) return Text('');
                          return Text(
                            LocaleKeys.LastBackup.tr() +
                                ': ' +
                                hourFormat.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.tryParse(snapshot
                                                    .data.files.first.name ??
                                                '') ??
                                            0)),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w200,
                                fontFamily: 'Roboto'),
                          );
                        },
                      ),
                    ),
                  ],
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
          onTap: isLoadingFiles
              ? null
              : () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => RestoreScreen(),
                  ));
                },
        ),
        SizedBox(
          height: 15,
        ),
        InkWell(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.Account.tr(),
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Roboto'),
                    ),
                  ],
                ),
                Text(
                  LocaleKeys.Logout.tr(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          onTap: () => authGoogle.logoutFromGoogle(),
        ),
      ],
    );
  }
}
