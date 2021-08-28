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
  PageController _pageController;
  List _selectedEvents = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime first;
  DateTime last;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    first = DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
    last = DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
    final days = Provider.of<DaysProvider>(context, listen: false)
        .initialDays
        .where((element) {
      return element.date.isAfter(first) && element.date.isBefore(last);
    });
    _events = {for (Days day in days) day.date: day.entries};
    _selectedEvents = _events[
            DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day)] ??
        [];
    super.initState();
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
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
            onPressed: () {
              _pageController.jumpToPage(_pageController.initialPage);
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
                _selectedEvents = _getEventsForDay(_focusedDay);
              });
            },
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

  void _onVisibleDaysChanged(focusedDay) {
    _focusedDay = focusedDay;
    final first = DateTime(_focusedDay.year, _focusedDay.month, 0);
    final last = DateTime(_focusedDay.year, _focusedDay.month, 32);
    final days = Provider.of<DaysProvider>(context, listen: false)
        .initialDays
        .where((element) {
      return element.date.isAfter(first) && element.date.isBefore(last);
    });
    _events = {for (Days day in days) day.date: day.entries};
    setState(() {});
  }

  List _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Widget _buildTableCalendarWithBuilders() {
    final firstDay = context.select((SettingsProvider value) => value.firstDay);
    return TableCalendar(
      onCalendarCreated: (pageController) => _pageController = pageController,
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2100, 10, 16),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      rowHeight: 50,
      locale: context.locale.toString(),
      eventLoader: (day) => _getEventsForDay(day),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: firstDay == 0
          ? StartingDayOfWeek.monday
          : firstDay == 1
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.saturday,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarStyle: CalendarStyle(
        //selectedTextStyle: TextStyle().copyWith(color: Colors.orange),
        selectedDecoration:
            BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        todayTextStyle: TextStyle().copyWith(color: Colors.indigoAccent),
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle().copyWith(color: Colors.blue[600]),
        holidayTextStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      headerStyle: HeaderStyle(
        leftChevronIcon: Icon(Icons.chevron_left,
            color: Theme.of(context).appBarTheme.textTheme.headline6.color),
        rightChevronIcon: Icon(Icons.chevron_right,
            color: Theme.of(context).appBarTheme.textTheme.headline6.color),
        titleCentered: true,
        //centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          Widget children;
          if (events.isNotEmpty) {
            final event = events[0] as Project;
            children = Positioned(
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
            );
          }
          return children;
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedEvents = _getEventsForDay(selectedDay);
          });
        }
      },
      onPageChanged: _onVisibleDaysChanged,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
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
              project: pr,
              date: DateTime(
                  _selectedDay.year, _selectedDay.month, _selectedDay.day));
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
