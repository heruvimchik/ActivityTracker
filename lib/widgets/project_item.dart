import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:activityTracker/helpers/timer_handler.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/providers/scroll_provider.dart';
import 'package:activityTracker/screens/records_screen.dart';
import 'package:activityTracker/widgets/timer_records.dart';
import '../models/project.dart';

class ProjectItem extends StatelessWidget {
  final bool scrollable;
  final Project project;

  const ProjectItem({Key key, this.scrollable, this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 1, horizontal: 5),
      child: ListTile(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RecordsScreen(project: project),
              )),
          title: Text(
            project.description,
            style: TextStyle(
                color: Theme.of(context).appBarTheme.textTheme.headline6.color,
                fontSize: 14),
          ),
          leading: CircleAvatar(
            child: Text(
              '${project.description.trim().substring(0, 1)}',
              style: TextStyle(
                  color: project.color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Color(project.color.value),
            radius: 15.0,
          ),
          trailing: Container(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TimerRecords(prj: project),
                isRunning(project)
                    ? IconButton(
                        onPressed: () => context
                            .read<ProjectsProvider>()
                            .stopRecord(project.projectID),
                        icon: Icon(Icons.pause, color: Colors.red),
                      )
                    : IconButton(
                        onPressed: () {
                          context
                              .read<ProjectsProvider>()
                              .addRecord(project.projectID);
                          if (scrollable)
                            context.read<ScrollProvider>().jumpTo();
                        },
                        icon:
                            Icon(Icons.play_arrow, color: Colors.indigoAccent),
                      ),
              ],
            ),
          )),
    );
  }
}
