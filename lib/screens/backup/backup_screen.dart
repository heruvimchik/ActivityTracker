import 'package:activityTracker/helpers/const.dart';
import 'package:activityTracker/providers/premium_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/providers/auth_provider.dart';

import 'google_drive_screen.dart';

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _flushBarError = FlushBarMy.errorBar(text: LocaleKeys.ErrorLogin.tr());

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PremiumProvider>().isPro;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme!.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(LocaleKeys.Backup.tr(), style: TextStyle(fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              height: 130,
              child: Image.asset(
                'assets/download.png',
                fit: BoxFit.fill,
              ),
            ),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.idTokenChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data != null) {
                    Provider.of<AuthProvider>(context, listen: false)
                        .fetchFiles(isPro);
                    return GoogleDriveScreen();
                  }
                  return ListTile(
                    title: Text(
                      LocaleKeys.Login.tr(),
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_right,
                      size: 18,
                    ),
                    onTap: () async {
                      try {
                        await context.read<AuthProvider>().silentLogin();
                      } catch (e) {
                        if (mounted)
                          _flushBarError
                            ..dismiss()
                            ..show(context);
                      }
                    },
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
