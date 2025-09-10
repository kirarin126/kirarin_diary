import 'package:flutter/material.dart';

class HomeCalendar extends StatefulWidget {
  final String name; // 👈 新增参数

  const HomeCalendar({
    super.key,
    required this.name, // 👈 标记为必需
  });

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface, // 👈 设置背景色
        child: Center(child: Text('这是${widget.name}的日历页面')),
      ),
      appBar: AppBar(
        title: Text('${widget.name}的日历'),
        backgroundColor: const Color(0xFFE581A3),
      ),
    );
  }
}
