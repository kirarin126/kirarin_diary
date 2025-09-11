import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeCalendar extends StatefulWidget {
  final String name;
  const HomeCalendar({super.key, required this.name});

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _today;

  final List<Map<String, String>> records = [
    {
      'title': '9月11日15:16:16',
      'note': '今天的便便状态良好，颜色正常，形状适中。',
    },
    {
      'title': '9月11日10:30:00',
      'note': '有点稀，可能是因为昨晚吃了辣的。'
    },
    {
      'title': '9月11日10:30:00',
      'note': '非常顺畅，感觉很好！'
    },
  ];

  DateTime get _lastDayOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDay = _today;
    _selectedDay = _today;
  }

  @override
  Widget build(BuildContext context) {
    final isLastMonth = _focusedDay.year == DateTime.now().year && _focusedDay.month == DateTime.now().month;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 218, 210, 210),
                      blurRadius: 4.0,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: TableCalendar(
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  locale: 'zh_CN',
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: _lastDayOfMonth,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color.fromRGBO(229, 129, 163, 1),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE581A3),
                    ),
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                  ),
                  onPageChanged: (focusedDay) {
                    final now = DateTime.now();
                    if (focusedDay.year > now.year ||
                        (focusedDay.year == now.year && focusedDay.month > now.month)) {
                      return;
                    }
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: isLastMonth ? Colors.grey : Colors.black,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  enabledDayPredicate: (day) => !day.isAfter(_today),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final weekday = day.weekday;
                      final labels = ['一', '二', '三', '四', '五', '六', '日'];
                      final label = labels[weekday - 1];
                      return Center(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '便便记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF393939)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: records.map((record) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      record['title'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      // overflow: TextOverflow.ellipsis, //超出部分省略
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '备注: ${record['note'] ?? ''}',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 判断两个日期是否是同一天 (忽略时间)
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
