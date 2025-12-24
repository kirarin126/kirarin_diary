import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:first/pages/habit/habit_tracker_page.dart';
import 'package:first/pages/habit/habit_config.dart';

/// 健康习惯概览组件 - 在首页展示习惯追踪的摘要信息
class HabitSummarySection extends StatefulWidget {
  final VoidCallback? onMoreTap;

  const HabitSummarySection({super.key, this.onMoreTap});

  @override
  HabitSummarySectionState createState() => HabitSummarySectionState();
}

class HabitSummarySectionState extends State<HabitSummarySection> {
  List<Map<String, String>> records = [];
  List<HabitConfig> habitConfigs = [];
  static const String _recordsKey = 'poop_records';

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  // 公开的刷新方法，供外部调用
  Future<void> refreshData() async {
    // 加载启用的习惯
    final configs = await HabitConfigManager.getEnabledHabits();

    // 加载记录
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recordsKey);
    List<Map<String, String>> loadedRecords = [];
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      loadedRecords = list.map((e) => Map<String, String>.from(e)).toList();
    }

    if (!mounted) return;
    setState(() {
      habitConfigs = configs;
      records = loadedRecords;
    });
  }

  // 获取本周记录数量
  Map<String, int> _getWeeklyCompletionForMode(String mode) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    int total = now.weekday; // 本周已过去的天数

    // 使用 Set 去重统计完成的天数
    final Set<String> completedDates = {};
    for (var record in records) {
      if (record['mode'] == mode) {
        final dateStr = record['date'];
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null &&
              !date.isBefore(weekStart) &&
              !date.isAfter(weekEnd)) {
            completedDates.add(dateStr);
          }
        }
      }
    }

    return {'completed': completedDates.length, 'total': total};
  }

  // 获取本周的完成状态（周一到周日）
  List<bool> _getWeeklyStatus(String mode) {
    final now = DateTime.now();
    // 获取本周一的日期
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final List<bool> status = [];

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dateStr = day.toIso8601String().substring(0, 10);
      final hasRecord = records.any(
        (r) => r['date'] == dateStr && r['mode'] == mode,
      );
      status.add(hasRecord);
    }

    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '健康习惯',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: widget.onMoreTap,
                child: Row(
                  children: [
                    Text(
                      '更多',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 习惯列表
          ...habitConfigs.asMap().entries.map((entry) {
            return _buildHabitItem(entry.value, entry.key);
          }),
        ],
      ),
    );
  }

  Widget _buildHabitItem(HabitConfig config, int index) {
    final mode = config.name;
    final weeklyStatus = _getWeeklyStatus(mode);
    final weeklyCompletion = _getWeeklyCompletionForMode(mode);
    final icon = config.icon;
    final iconColor = config.color;
    final bgColor = config.color.withAlpha(25);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                HabitTrackerPage(name: mode, initialModeIndex: index),
          ),
        );
        // 返回后刷新数据
        refreshData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HabitConfigManager.getIconWidget(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      // 生理期模式不显示本周完成信息
                      if (mode != '生理期') ...[
                        const SizedBox(width: 8),
                        Text(
                          '本周完成${weeklyCompletion['completed']}/${weeklyCompletion['total']}天',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 周状态指示器 (周一到周日)
                  Row(
                    children: weeklyStatus.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final isCompleted = entry.value;
                      final now = DateTime.now();
                      final isToday = idx == (now.weekday - 1); // weekday: 1=周一

                      Color dotColor;
                      if (isCompleted) {
                        dotColor = const Color(0xFFE581A3);
                      } else {
                        dotColor = Colors.grey.shade300;
                      }

                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(3),
                          border: isToday && !isCompleted
                              ? Border.all(
                                  color: iconColor.withAlpha(128),
                                  width: 1,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 右侧复选框
            _buildCheckbox(mode),
          ],
        ),
      ),
    );
  }

  // 获取当天打卡次数
  int _getTodayCount(String mode) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return records.where((r) => r['date'] == today && r['mode'] == mode).length;
  }

  // 添加记录弹窗
  Future<void> _showAddRecordDialog(String mode) async {
    String note = '';
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFEEF3), Colors.white],
              stops: [0.0, 0.3],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部拖动指示器
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 标题区域
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE581A3).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFFE581A3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '添加记录',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '当前模式：$mode',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE581A3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 备注输入卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
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
                              color: const Color(0xFFF0E4E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Color(0xFFE581A3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '备注',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            '（选填）',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '记录一下这次的感受吧~',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE581A3),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        onChanged: (value) => note = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 底部按钮
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          // 获取当前时间作为打卡时间（包含秒数）
                          final now = DateTime.now();
                          final today = now.toIso8601String().substring(0, 10);
                          final currentTime =
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
                          final formattedDateTime =
                              '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $currentTime';

                          setState(() {
                            records.insert(0, {
                              'title': '${now.month}月${now.day}日 $currentTime',
                              'note': note.trim(),
                              'date': today,
                              'time': currentTime,
                              'datetime': formattedDateTime,
                              'mode': mode,
                            });
                          });

                          // 保存记录
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            _recordsKey,
                            jsonEncode(records),
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE581A3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '完成打卡',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(String mode) {
    // 如果是生理期模式，使用 switch 按钮
    if (mode == '生理期') {
      return _buildPeriodSwitch(mode);
    }

    final todayCount = _getTodayCount(mode);
    final hasCompleted = todayCount > 0;

    return GestureDetector(
      onTap: () => _showAddRecordDialog(mode),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasCompleted ? const Color(0xFFE581A3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasCompleted
                ? const Color(0xFFE581A3)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: hasCompleted
            ? Center(
                child: todayCount > 1
                    ? Text(
                        '$todayCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.check, color: Colors.white, size: 24),
              )
            : null,
      ),
    );
  }

  // 判断是否在"走了"（经期结束）后的5天内
  bool _isWithin5DaysAfterPeriodEnd() {
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return false;

    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    String? endDateStr;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期结束') == true) {
        endDateStr = r['date'];
        break;
      }
    }

    if (endDateStr == null) return false;

    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final daysSinceEnd = todayDate.difference(endDate).inDays;

    return daysSinceEnd >= 0 && daysSinceEnd <= 5;
  }

  // 构建生理期 Switch 按钮
  Widget _buildPeriodSwitch(String mode) {
    final hasRecord = _getTodayCount(mode) > 0;
    final isIn5DayRecovery = _isWithin5DaysAfterPeriodEnd();

    // 有记录或在5天恢复期内：显示"走了/没走"
    final showEndedButtons = hasRecord || isIn5DayRecovery;
    final leftText = showEndedButtons ? '走了' : '来了';
    final rightText = showEndedButtons ? '没走' : '没来';

    return Container(
      width: 100,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE581A3), width: 1),
      ),
      child: Row(
        children: [
          // 左边按钮（操作按钮）
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (showEndedButtons) {
                  if (hasRecord) {
                    await _markPeriodEnded();
                  }
                  // 在5天恢复期内点击"走了"不做操作
                } else {
                  await _addPeriodRecord();
                }
              },
              child: Container(
                height: double.infinity,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  leftText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE581A3),
                  ),
                ),
              ),
            ),
          ),
          // 右边按钮（状态显示）
          Expanded(
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFE581A3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                rightText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 添加生理期记录 (自动填充6天)
  Future<void> _addPeriodRecord() async {
    final now = DateTime.now();
    // 从今天开始
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      for (int i = 0; i < 6; i++) {
        final date = today.add(Duration(days: i));
        final dateStr = date.toIso8601String().substring(0, 10);

        // 检查该日期是否已有生理期记录，避免重复
        final hasRecord = records.any(
          (r) => r['date'] == dateStr && r['mode'] == '生理期',
        );

        if (!hasRecord) {
          final currentTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          final formattedDateTime =
              '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $currentTime';

          records.insert(0, {
            'title': '${date.month}月${date.day}日 $currentTime',
            'note': i == 0 ? '生理期开始' : '生理期自动填充',
            'date': dateStr,
            'time': currentTime,
            'datetime': formattedDateTime,
            'mode': '生理期',
          });
        }
      }
    });

    // 保存记录
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // 删除当天的生理期记录
  Future<void> _removeTodayPeriodRecords() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      records.removeWhere((r) => r['date'] == today && r['mode'] == '生理期');
    });

    // 保存记录
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // 标记生理期提前结束
  Future<void> _markPeriodEnded() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 找到本周期的开始日期
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    // 找到当前周期的开始日期
    String? currentCycleStart;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        currentCycleStart = r['date'];
        break;
      }
    }

    if (currentCycleStart == null) return;

    setState(() {
      // 删除今天之后的自动填充记录
      records.removeWhere((r) {
        if (r['mode'] != '生理期') return false;
        final recordDate = r['date'] ?? '';
        return recordDate.compareTo(today) > 0 &&
            recordDate.compareTo(currentCycleStart!) >= 0;
      });

      // 更新今天的记录，标记为经期结束
      final todayRecordIndex = records.indexWhere(
        (r) => r['date'] == today && r['mode'] == '生理期',
      );
      if (todayRecordIndex >= 0) {
        records[todayRecordIndex]['note'] = '生理期结束';
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }
}
