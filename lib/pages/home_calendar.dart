import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeCalendar extends StatefulWidget {
  final String name;
  const HomeCalendar({super.key, required this.name});

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  // 编辑记录弹窗
  Future<void> _showEditRecordDialog(int index) async {
    String note = records[index]['note'] ?? '';
    final controller = TextEditingController(text: note);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('编辑备注', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                maxLines: 3,
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入备注',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE581A3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE581A3), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) {
                  note = value;
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE581A3),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (note.trim().isNotEmpty) {
                        setState(() {
                          records[index]['note'] = note.trim();
                        });
                        await _saveRecords();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('保存', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 删除记录
  Future<void> _deleteRecord(int index) async {
    setState(() {
      records.removeAt(index);
    });
    await _saveRecords();
  }
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _today;

  List<Map<String, String>> records = [];

  static const String _recordsKey = 'poop_records';

  // 加载本地记录
  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recordsKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      records = list.map((e) => Map<String, String>.from(e)).toList();
      setState(() {});
    }
  }

  // 保存记录到本地
  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // 弹窗输入备注内容
  Future<void> _showAddRecordDialog() async {
    String note = '';
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                maxLines: 3,
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入备注',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE581A3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE581A3), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) {
                  note = value;
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE581A3),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (note.trim().isNotEmpty) {
                        setState(() {
                          final now = DateTime.now();
                          final title =
                              '${now.month}月${now.day}日${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
                          records.insert(0, {
                            'title': title,
                            'note': note.trim(),
                            'date': now.toIso8601String().substring(0, 10), // yyyy-MM-dd
                          });
                        });
                        await _saveRecords();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('确定', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

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
  _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final isLastMonth =
        _focusedDay.year == DateTime.now().year &&
        _focusedDay.month == DateTime.now().month;
    // 过滤出选中日期的记录
    String selectedDateStr = _selectedDay.toIso8601String().substring(0, 10); // yyyy-MM-dd
    List<Map<String, String>> todayRecords = records.where((r) => r['date'] == selectedDateStr).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ...existing code...
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
                    todayDecoration: BoxDecoration(shape: BoxShape.circle),
                  ),
                  onPageChanged: (focusedDay) {
                    final now = DateTime.now();
                    if (focusedDay.year > now.year ||
                        (focusedDay.year == now.year &&
                            focusedDay.month > now.month)) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '便便记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF393939),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: List.generate(todayRecords.length, (index) {
                    final record = todayRecords[index];
                    // 需要找到原始 records 的 index 以便编辑/删除
                    final realIndex = records.indexOf(record);
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
                              padding: const EdgeInsets.only(
                                left: 12.0,
                                right: 12.0,
                                bottom: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      record['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Color(0xFFE581A3)),
                                    tooltip: '编辑',
                                    onPressed: () => _showEditRecordDialog(realIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Color(0xFF888888)),
                                    tooltip: '删除',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('确认删除'),
                                          content: const Text('确定要删除这条记录吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('取消'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('删除'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteRecord(realIndex);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12.0,
                                right: 12.0,
                                bottom: 0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '备注: ${record['note'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF888888),
                                      ),
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
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFFE581A3),
        child: const Icon(Icons.add, color: Colors.white),
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
