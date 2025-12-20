import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 习惯追踪页面 - 用于记录和追踪日常健康习惯
class HabitTrackerPage extends StatefulWidget {
  final String name;
  const HabitTrackerPage({super.key, required this.name});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  final List<String> modes = ['洗头', '便便', '喝奶茶'];
  int selectedModeIndex = 0;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _today;

  List<Map<String, String>> records = [];
  static const String _recordsKey = 'poop_records';

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDay = _today;
    _selectedDay = _today;
    _loadRecords();
  }

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

  DateTime get _lastDayOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  // 判断两个日期是否是同一天 (忽略时间)
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 获取指定日期的记录
  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final dateStr = day.toIso8601String().substring(0, 10);
    final currentMode = modes[selectedModeIndex];
    return records
        .where((r) => r['date'] == dateStr && r['mode'] == currentMode)
        .toList();
  }

  // 编辑记录弹窗
  Future<void> _showEditRecordDialog(int index) async {
    final currentMode = modes[selectedModeIndex];
    String note = records[index]['note'] ?? '';
    final controller = TextEditingController(text: note);
    final List<String> timeOptions = List.generate(24 * 2, (i) {
      final h = (i ~/ 2).toString().padLeft(2, '0');
      final m = (i % 2 == 0) ? '00' : '30';
      return '$h:$m';
    });
    String selectedTime =
        records[index]['time'] ??
        timeOptions[DateTime.now().hour * 2 +
            (DateTime.now().minute >= 30 ? 1 : 0)];

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
              Text(
                '当前模式：$currentMode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE581A3),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '编辑备注',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('时间点：', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTime,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: timeOptions
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedTime = v;
                      },
                    ),
                  ),
                ],
              ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) => note = value,
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
                          records[index]['time'] = selectedTime;
                          final date = _selectedDay;
                          records[index]['title'] =
                              '${date.month}月${date.day}日$selectedTime';
                          records[index]['mode'] = currentMode;
                        });
                        await _saveRecords();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('保存'),
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

  // 添加记录弹窗
  Future<void> _showAddRecordDialog() async {
    String note = '';
    final controller = TextEditingController();
    final currentMode = modes[selectedModeIndex];
    final List<String> timeOptions = List.generate(24 * 2, (i) {
      final h = (i ~/ 2).toString().padLeft(2, '0');
      final m = (i % 2 == 0) ? '00' : '30';
      return '$h:$m';
    });
    String selectedTime =
        timeOptions[DateTime.now().hour * 2 +
            (DateTime.now().minute >= 30 ? 1 : 0)];

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
              Text(
                '当前模式：$currentMode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE581A3),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '添加记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('时间：', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTime,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: timeOptions
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedTime = v;
                      },
                    ),
                  ),
                ],
              ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) => note = value,
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
                      setState(() {
                        final date = _selectedDay;
                        final title = '${date.month}月${date.day}日$selectedTime';
                        records.insert(0, {
                          'title': title,
                          'note': note.trim(), // 允许为空
                          'date': date.toIso8601String().substring(
                            0,
                            10,
                          ), // yyyy-MM-dd
                          'time': selectedTime,
                          'mode': currentMode,
                        });
                      });
                      await _saveRecords();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedDateStr = _selectedDay.toIso8601String().substring(0, 10);
    String currentMode = modes[selectedModeIndex];
    List<Map<String, String>> todayRecords = records
        .where((r) => r['date'] == selectedDateStr && r['mode'] == currentMode)
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEEF3), Color(0xFFF9F9F9)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '健康习惯',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '管理',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // 标签切换 (胶囊样式)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E4E8), // 浅粉底色
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: List.generate(modes.length, (index) {
                    final isSelected = selectedModeIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedModeIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            modes[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.black45,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 主内容区域 (日历 + 记录列表)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 日历卡片
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TableCalendar(
                            locale: 'zh_CN',
                            firstDay: DateTime.utc(2010, 10, 16),
                            lastDay: _lastDayOfMonth,
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            eventLoader: _getEventsForDay,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ),
                            calendarStyle: const CalendarStyle(
                              outsideDaysVisible: false,
                              selectedDecoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: Color(0xFFE581A3),
                                    width: 1.5,
                                  ), // 选中日期粉色边框
                                ),
                              ),
                              selectedTextStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              todayDecoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent, // 今日无边框无背景
                              ),
                              todayTextStyle: TextStyle(
                                color: Color(0xFFE581A3), // 今日日期粉色文字
                                fontWeight: FontWeight.bold,
                              ),
                              markerDecoration: BoxDecoration(
                                // 默认的marker太小，我们用builder自定义
                                color: Colors.transparent,
                              ),
                            ),
                            onPageChanged: (focusedDay) {
                              setState(() => _focusedDay = focusedDay);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarBuilders: CalendarBuilders(
                              // 自定义有记录的日期样式
                              markerBuilder: (context, day, events) {
                                if (events.isNotEmpty) {
                                  // 如果有记录，显示粉色圆圈背景
                                  return Positioned.fill(
                                    child: Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE581A3), // 粉色
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                              // 覆盖默认的selectedBuilder
                              selectedBuilder: (context, day, focusedDay) {
                                // 如果有记录，显示粉色背景
                                if (_getEventsForDay(day).isNotEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4A90E2), // 蓝色
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                // 选中非今日日期时，显示粉色边框
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFFE581A3), // 粉色边框
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              // 自定义今日样式 (粉色文字，无边框)
                              todayBuilder: (context, day, focusedDay) {
                                // 如果今日有记录，显示蓝色背景
                                if (_getEventsForDay(day).isNotEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4A90E2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                // 今日无记录时，粉色文字无边框
                                return Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Color(0xFFE581A3), // 粉色文字
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 记录列表标题
                        Row(
                          children: [
                            Text(
                              '${modes[selectedModeIndex]}记录',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 记录列表
                        if (todayRecords.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '今天暂未打卡',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: List.generate(todayRecords.length, (
                              index,
                            ) {
                              final record = todayRecords[index];
                              final realIndex = records.indexOf(record);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFE581A3,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Color(0xFFE581A3),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record['time'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if ((record['note'] ?? '')
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    record['note']!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit')
                                              _showEditRecordDialog(realIndex);
                                            if (v == 'delete')
                                              _deleteRecord(realIndex);
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('编辑'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('删除'),
                                            ),
                                          ],
                                          child: const Icon(
                                            Icons.more_horiz,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 100), // 底部留白给按钮
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 底部固定打卡按钮
      bottomSheet: Container(
        color: const Color(0xFFF9F9F9),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 30,
          top: 10,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 234, 145, 175), // 粉色
              foregroundColor: const Color(0xFFFFFFFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _showAddRecordDialog,
            child: const Text(
              '打卡',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
