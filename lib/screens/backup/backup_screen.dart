import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upTimer/providers/auth_provider.dart';

import 'google_drive_screen.dart';

class BackupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text('Backup / Restore'),
      ),
      body: StreamBuilder<User>(
        stream: FirebaseAuth.instance.idTokenChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data != null) {
              Provider.of<AuthProvider>(context, listen: false).fetchFiles();
              return GoogleDriveScreen();
            }
            return InkWell(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
              onTap: () => context.read<AuthProvider>().silentLogin(),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
