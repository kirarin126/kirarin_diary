import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeCalendar extends StatefulWidget {
  final String name;

  // 1. 添加 'const' 到构造函数声明
  // 2. 使用 'super.key' 简化语法
  const HomeCalendar({super.key, required this.name});

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _today; // 缓存今天的日期

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDay = _today;
    _selectedDay = _today;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0), // 外边距
              padding: const EdgeInsets.all(0), // 内边距
              decoration: BoxDecoration(
                color: Colors.white, // 背景色
                borderRadius: BorderRadius.circular(12.0), // 圆角
                boxShadow: const [
                  // 阴影
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TableCalendar(
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month', // 只保留月视图
                  // CalendarFormat.twoWeeks: '2 weeks', // 移除这一行
                  // CalendarFormat.week: 'Week', // 如果你也不想要周视图按钮，也移除这行
                },
                calendarFormat: CalendarFormat.month, // 默认显示月视图
                // --- 本地化设置 ---
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'zh_CN', // 设置为简体中文
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration : BoxDecoration(
                    color: Color.fromRGBO(229, 129, 163, 1), // 选中日期的背景色
                    shape: BoxShape.circle,
                    
                  ),  
                  // 设置除周末外的日历文本样式
                  // defaultTextStyle: TextStyle(
                  //   fontSize: 20,
                  //   color: Color(0xFF666666),
                  //   fontWeight: FontWeight.w600,
                  // ),
                  // // 设置周末的文本样式
                  // weekendTextStyle: TextStyle(
                  //   fontSize: 20,
                  //   color: Color(0xFFFF0000),
                  //   fontWeight: FontWeight.bold,
                  // ),
                  // // 设置当前日期的文本样式
                  todayTextStyle: TextStyle(
                    // fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:Color(0xFFE581A3),
                  ),
                  // 设置当前日期的容器样式
                  todayDecoration: BoxDecoration(
                    // color: Color(0xFFE581A3),
                    shape: BoxShape.circle,
                  ),
                ),

                onDaySelected: (selectedDay, focusedDay) {
                  print('选择的日期是: $selectedDay');
                  // enabledDayPredicate 会阻止未来日期被选中，所以这里无需额外检查
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },

                // --- 核心逻辑 1: 控制可点击性 ---
                enabledDayPredicate: (day) {
                  // 今天和今天之前的日期可点击 (day <= today)
                  return !day.isAfter(_today);
                },
                // --- 核心逻辑 2: 自定义样式 ---
                calendarBuilders: CalendarBuilders(
                  // --- 核心修改：自定义星期标题 ---
                  dowBuilder: (context, day) {
                    // `day` 是一个代表星期几的 DateTime 对象 (e.g., 1970-01-05 是 Monday)
                    final weekday = day.weekday; // 1=Monday, 7=Sunday

                    // 定义只包含一个字符的中文星期标题
                    final labels = ['一', '二', '三', '四', '五', '六', '日'];

                    // weekday - 1 是因为 weekday 从 1 开始，而 List 索引从 0 开始
                    final label = labels[weekday - 1];

                    return Center(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 12.0), // 可根据需要调整样式
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 辅助函数：判断两个日期是否是同一天 (忽略时间)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
