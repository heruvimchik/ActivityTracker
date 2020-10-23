import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:activityTracker/models/project.dart';
import 'package:activityTracker/providers/projects_provider.dart';

class AddProjectScreen extends StatefulWidget {
  final Project project;
  final String title;

  const AddProjectScreen({this.project, this.title});

  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _form = GlobalKey<FormState>();
  TextEditingController _textController = TextEditingController();
  Color _colour;
  @override
  void initState() {
    _textController.text = widget.project?.description ?? '';
    _colour = widget.project?.color ?? Colors.lightBlue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 20, top: 20),
              child: Form(
                key: _form,
                child: TextFormField(
                  decoration: InputDecoration.collapsed(
                    hintText: LocaleKeys.ActivityHint.tr(),
                  ),
                  onChanged: (value) => setState(() {}),
                  autofocus: true,
                  controller: _textController,
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return LocaleKeys.PleaseEnterName.tr();
                    }
                    return null;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: MaterialColorPicker(
                physics: NeverScrollableScrollPhysics(),
                onMainColorChange: (value) => _colour = value,
                allowShades: false,
                spacing: 5,
                circleSize: 30.0,
                selectedColor: _colour,
                shrinkWrap: true,
                onColorChange: (Color colour) => _colour = colour,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: RaisedButton(
                shape: StadiumBorder(),
                onPressed: _textController.text.trim().isEmpty
                    ? null
                    : () {
                        final isValid = _form.currentState.validate();
                        if (!isValid) return;

                        final provider = context.read<ProjectsProvider>();
                        widget.project == null
                            ? provider.addProject(_textController.text, _colour)
                            : provider.updateProject(
                                updProjectId: widget.project.projectID,
                                description: _textController.text,
                                color: _colour);
                        Navigator.of(context).pop();
                      },
                color: Colors.indigo,
                child: Text(
                  widget.project == null
                      ? LocaleKeys.StartActivity.tr()
                      : LocaleKeys.Update.tr(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.03,
            )
          ],
        ),
      ),
    );
  }
}
