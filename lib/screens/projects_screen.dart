import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upTimer/generated/locale_keys.g.dart';
import 'package:upTimer/providers/projects_provider.dart';
import 'package:upTimer/widgets/line.dart';
import 'package:upTimer/widgets/project_item.dart';

class ProjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, projProvider, __) {
        final projects = projProvider.projects.reversed.toList();
        if (projects.length == 0) return ShowImage();
        return ListView.builder(
          itemBuilder: (context, index) => Dismissible(
            key: Key('__item_${projects[index].projectID}'),
            background: Container(
              color: Theme.of(context).errorColor,
              child: Icon(Icons.delete, color: Colors.white, size: 40),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(LocaleKeys.DeleteDialog.tr()),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(LocaleKeys.Yes.tr())),
                  FlatButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(LocaleKeys.No.tr())),
                ],
              ),
            ),
            onDismissed: (direction) {
              context.read<ProjectsProvider>().deleteProject(projects[index]);
            },
            child: ProjectItem(project: projects[index], scrollable: false),
          ),
          itemCount: projects.length,
        );
      },
    );
  }
}
