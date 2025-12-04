import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dnsc_events/colors/color.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime today = DateTime.now();

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: CustomColor.primary),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: CustomColor.primary,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: CustomColor.primary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: CustomColor.primary,
            shape: BoxShape.circle,
          ),
        ),
        availableGestures: AvailableGestures.horizontalSwipe,
        focusedDay: today,
        firstDay: DateTime.utc(2000, 10, 2),
        lastDay: DateTime.utc(2050, 10, 1),
        onDaySelected: _onDaySelected,
        selectedDayPredicate: (day) => isSameDay(day, today),
      ),
    );
  }
}
