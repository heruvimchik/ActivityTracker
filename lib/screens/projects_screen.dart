import 'package:activityTracker/widgets/line.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/widgets/project_item.dart';

class ProjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, projProvider, __) {
        if (projProvider.projects == null ||
            projProvider.projects.length == 0) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    height: 120,
                    child: Image.asset(
                      'assets/jetpack.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  NoRecordsWidget()
                ],
              ),
            ),
          );
        }

        final projects = projProvider.projects.reversed.toList();
        return ListView.builder(
          itemBuilder: (context, index) => Dismissible(
            key: Key('__item_${projects[index].projectID}'),
            background: Card(
              color: Theme.of(context).errorColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                ],
              ),
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
