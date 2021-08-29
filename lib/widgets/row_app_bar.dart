import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:provider/provider.dart';

class RowAppBar extends StatefulWidget {
  @override
  _RowAppBarState createState() => _RowAppBarState();
}

class _RowAppBarState extends State<RowAppBar> {
  DateTimeRange? dateRange;

  void pickRangeDate(BuildContext ctx) async {
    final date = await showDateRangePicker(
        initialDateRange: dateRange ??
            DateTimeRange(start: DateTime.now(), end: DateTime.now()),
        context: ctx,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null && date != dateRange) {
      context.read<DaysProvider>().dateRange = date;
      setState(() => dateRange = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yy', LocaleKeys.locale.tr());
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2.2),
          child: InkWell(
            onTap: () => pickRangeDate(context),
            child: Text(
                dateRange != null
                    ? '${dateFormat.format(dateRange!.start)} - ${dateFormat.format(dateRange!.end)}'
                    : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).appBarTheme.actionsIconTheme!.color,
                    fontSize: 13)),
          ),
        ),
        Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 2.2),
            child: dateRange == null
                ? InkWell(
                    child: Icon(Icons.filter_list,
                        color: Theme.of(context)
                            .appBarTheme
                            .actionsIconTheme!
                            .color),
                    onTap: () => pickRangeDate(context),
                  )
                : InkWell(
                    child: Icon(Icons.cancel, color: Colors.redAccent),
                    onTap: () {
                      context.read<DaysProvider>().dateRange = null;
                      setState(() => dateRange = null);
                    },
                  )),
      ],
    );
  }
}
