import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:activityTracker/providers/settings_provider.dart';

class ShowImage extends StatelessWidget {
  const ShowImage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkmode =
        context.select<SettingsProvider, bool>((value) => value.darkTheme);
    return Center(
        child: Image.asset(
      'assets/nodata.png',
      fit: BoxFit.fill,
      color: darkmode ? Colors.white70 : Colors.black38,
    ));
  }
}

class Line extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final darkmode =
        context.select<SettingsProvider, bool>((value) => value.darkTheme);
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 0.07)),
        color: darkmode ? Colors.white70 : Colors.black38,
      ),
    );
  }
}
