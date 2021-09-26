import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Calendar'),
        ),
        body: const CalendarHomePage(),
      ),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({Key? key}) : super(key: key);

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  var _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  var _focusedDay = DateTime.now();
  late LinkedHashMap<DateTime, List<Event>> _events;
  late LinkedHashMap<DateTime, List<Event>> _eventSource;
  late ValueNotifier<List<Event>> _selectedEvents;
  late DateTime _firstDay;
  late DateTime _lastDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int yearRange = 10;

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    List<DateTime> days = [];
    for(var d = start; d.compareTo(end) <= 0; d = d.add(const Duration(days: 1))) {
      days.add(d);
    }

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  @override
  void initState() {
    super.initState();
    _firstDay = DateTime.utc(_focusedDay.year - yearRange, 1, 1);
    _lastDay = DateTime.utc(_focusedDay.year + yearRange, 12, 31);
    _eventSource = _getEventSource();
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(_eventSource);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    super.dispose();
    _selectedEvents.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TableCalendar<Event>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rangeSelectionMode: _rangeSelectionMode,
          onDaySelected: _onDaySelected,
          onRangeSelected: _onRangeSelected,
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      onTap: () => print(value[index].title),
                      title: Text(value[index].title),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // TODO: カレンダーから情報を取得する
  LinkedHashMap<DateTime, List<Event>> _getEventSource() {
    var linkedHashMap = LinkedHashMap<DateTime, List<Event>>();
    linkedHashMap.addAll({
      DateTime.now().subtract(const Duration(days: 2)): [
        Event('Go shopping'),
        Event('Go to the dentist')
      ],
      DateTime.now().subtract(const Duration(days: 1)): [Event('Pay rent')],
      DateTime.now(): [Event('Attend a meeting'), Event('Have dinner with family'), Event('Go to the gym')],
      DateTime.now().add(const Duration(days: 3)): [
        Event('Garbage collection'),
        Event('Go mountain climbing')
      ],
    });
    return linkedHashMap;
  }
}

class Event {
  String title;

  Event(this.title);
}
