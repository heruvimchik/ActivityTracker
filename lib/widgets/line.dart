import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/providers/settings_provider.dart';

class NoRecordsWidget extends StatelessWidget {
  const NoRecordsWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            LocaleKeys.NoActivity.tr(),
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
          Icon(Icons.add),
        ],
      ),
    );
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
