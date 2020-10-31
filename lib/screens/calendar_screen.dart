import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:activityTracker/generated/locale_keys.g.dart';
import 'package:activityTracker/models/project.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/projects_provider.dart';
import 'package:activityTracker/providers/settings_provider.dart';
import 'package:activityTracker/widgets/timer_records.dart';

import 'records_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List> _events = {};
  List _selectedEvents = [];
  CalendarController _calendarController;
  DateTime date;

  @override
  void initState() {
    final _selectedDay = DateTime.now();
    final first =
        DateTime(_selectedDay.year, _selectedDay.month - 1, _selectedDay.day);
    final last =
        DateTime(_selectedDay.year, _selectedDay.month + 1, _selectedDay.day);
    final days = Provider.of<DaysProvider>(context, listen: false)
        .initialDays
        .where((element) {
      return element.date.isAfter(first) && element.date.isBefore(last);
    });
    _events = {for (Days day in days) day.date: day.entries};
    _selectedEvents = _events[DateTime(
            _selectedDay.year, _selectedDay.month, _selectedDay.day)] ??
        [];
    date = _selectedDay;
    _calendarController = CalendarController();
    super.initState();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DaysProvider>();
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(
          LocaleKeys.Calendar.tr(),
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.event),
            onPressed: () => _calendarController.setSelectedDay(
              DateTime.now(),
              runCallback: true,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTableCalendarWithBuilders(),
            const SizedBox(height: 8.0),
            _buildEventList(),
          ],
        ),
      ),
    );
  }

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    final days = Provider.of<DaysProvider>(context, listen: false)
        .initialDays
        .where((element) {
      return element.date.isAfter(first.subtract(Duration(days: 1))) &&
          element.date.isBefore(last.add(Duration(days: 1)));
    });
    _events = {for (Days day in days) day.date: day.entries};
    setState(() {});
  }

  Widget _buildTableCalendarWithBuilders() {
    final firstDay = context.select((SettingsProvider value) => value.firstDay);
    return TableCalendar(
      onVisibleDaysChanged: _onVisibleDaysChanged,
      rowHeight: 50,
      locale: context.locale.toString(),
      calendarController: _calendarController,
      events: _events,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: firstDay == 0
          ? StartingDayOfWeek.monday
          : firstDay == 1
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.saturday,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarStyle: CalendarStyle(
        selectedColor: Colors.orange,
        todayColor: Colors.indigoAccent,
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
        holidayStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      headerStyle: HeaderStyle(
        leftChevronIcon: Icon(Icons.chevron_left,
            color: Theme.of(context).appBarTheme.textTheme.headline6.color),
        rightChevronIcon: Icon(Icons.chevron_right,
            color: Theme.of(context).appBarTheme.textTheme.headline6.color),
        centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      builders: CalendarBuilders(
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];
          if (events.isNotEmpty) {
            final event = events[0] as Project;
            children.add(
              Positioned(
                right: 1,
                bottom: 2,
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.color //Colors.blue[400],
                      ),
                  width: 16.0,
                  height: 16.0,
                  child: Center(
                    child: Text(
                      '${events.length}',
                      style: TextStyle().copyWith(
                        color: event.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return children;
        },
      ),
      onDaySelected: (day, events, holidays) => setState(() {
        date = day;
        _selectedEvents = events;
      }),
    );
  }

  Widget _buildEventList() {
    final selEvents = _selectedEvents.map((event) {
      final pr = event as Project;
      return Dismissible(
        key: Key('${pr.projectID}'),
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
          margin: EdgeInsets.only(right: 10, left: 10, top: 4, bottom: 4),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          context.read<ProjectsProvider>().deleteDayProject(
              project: pr, date: DateTime(date.year, date.month, date.day));
        },
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 1, horizontal: 5),
          child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => RecordsScreen(project: pr),
                  )),
              title: Text(
                pr.description,
                style: TextStyle(
                    color:
                        Theme.of(context).appBarTheme.textTheme.headline6.color,
                    fontSize: 14),
              ),
              leading: CircleAvatar(
                child: Text(
                  '${pr.description.trim().substring(0, 1)}',
                  style: TextStyle(
                      color: pr.color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white),
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Color(pr.color.value),
                radius: 15.0,
              ),
              trailing: Container(
                width: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TimerRecords(prj: pr),
                  ],
                ),
              )),
        ),
      );
    }).toList();
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) => selEvents[index],
      itemCount: selEvents.length,
    );
  }
}
