import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/providers/auth_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/providers/settings_provider.dart';

class RestoreScreen extends StatelessWidget {
  final date24h = DateFormat('MMM dd yyyy HH:mm:ss', LocaleKeys.locale.tr());
  final date12h = DateFormat('MMM dd yyyy hh:mm:ss a', LocaleKeys.locale.tr());
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final proj = Provider.of<ProjectsProvider>(context, listen: false);
    final filesLoaded =
        context.select((AuthProvider value) => value.filesLoaded);
    final hour24 = context.select((SettingsProvider value) => value.hour24);
    final hourFormat = hour24 ? date24h : date12h;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(LocaleKeys.Restore.tr(), style: TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<ga.FileList>(
        future: filesLoaded,
        builder: (context, AsyncSnapshot<ga.FileList> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          if (snapshot.data == null) return Text('');
          return ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) => Dismissible(
              key: Key('${snapshot.data.files[index].name}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).errorColor,
                child: Icon(Icons.delete, color: Colors.white, size: 40),
                alignment: Alignment.centerRight,
                margin: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              ),
              confirmDismiss: (direction) => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(LocaleKeys.DeleteBackup.tr()),
                  actions: <Widget>[
                    FlatButton(
                        onPressed: () async {
                          try {
                            await auth.deleteGoogleDriveFile(
                                gdID: snapshot.data.files[index].id);
                            Navigator.of(ctx).pop(true);
                            FlushbarHelper.createSuccess(
                                    message: LocaleKeys.SuccessDelete.tr(),
                                    duration: Duration(seconds: 2))
                                .show(context);
                          } catch (e) {
                            Navigator.of(ctx).pop(false);
                            FlushbarHelper.createError(
                                    message: LocaleKeys.ErrorDelete.tr(),
                                    duration: Duration(seconds: 2))
                                .show(context);
                          }
                        },
                        child: Text(LocaleKeys.Yes.tr())),
                    FlatButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(LocaleKeys.No.tr())),
                  ],
                ),
              ),
              onDismissed: (direction) {},
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 1, horizontal: 5),
                child: ListTile(
                  title: Text(hourFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(
                          int.tryParse(snapshot.data.files[index].name) ?? 0))),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(LocaleKeys.RestoreBackup.tr()),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              try {
                                await auth.downloadGoogleDriveFile(
                                    gdID: snapshot.data.files[index].id,
                                    projects: proj);
                                FlushbarHelper.createSuccess(
                                        message:
                                            LocaleKeys.SuccessDownload.tr(),
                                        duration: Duration(seconds: 2))
                                    .show(context);
                              } catch (e) {
                                FlushbarHelper.createError(
                                        message: LocaleKeys.ErrorDownload.tr(),
                                        duration: Duration(seconds: 2))
                                    .show(context);
                              }
                            },
                            child: Text(LocaleKeys.Yes.tr())),
                        FlatButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(LocaleKeys.No.tr())),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            itemCount: snapshot.data.files.length,
          );
        },
      ),
    );
  }
}
