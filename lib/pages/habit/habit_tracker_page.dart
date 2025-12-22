import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'habit_config.dart';
import 'habit_manage_page.dart';

/// 习惯追踪页面 - 用于记录和追踪日常健康习惯
class HabitTrackerPage extends StatefulWidget {
  final String name;
  final int initialModeIndex;
  const HabitTrackerPage({
    super.key,
    required this.name,
    this.initialModeIndex = 0,
  });

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  List<String> modes = [];
  List<HabitConfig> habitConfigs = [];
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
    _loadHabitsAndRecords();
  }

  // 加载习惯配置和记录
  Future<void> _loadHabitsAndRecords() async {
    // 加载启用的习惯
    final configs = await HabitConfigManager.getEnabledHabits();
    final modesList = configs.map((c) => c.name).toList();

    // 加载记录
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recordsKey);
    List<Map<String, String>> loadedRecords = [];
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      loadedRecords = list.map((e) => Map<String, String>.from(e)).toList();
    }

    setState(() {
      habitConfigs = configs;
      modes = modesList;
      records = loadedRecords;
      // 确保 initialModeIndex 在有效范围内
      if (widget.initialModeIndex < modes.length) {
        selectedModeIndex = widget.initialModeIndex;
      } else {
        selectedModeIndex = 0;
      }
    });
  }

  // 保存记录到本地
  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
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

  // 判断当前模式是否为生理期
  bool get _isPeriodMode {
    if (selectedModeIndex >= habitConfigs.length) return false;
    return habitConfigs[selectedModeIndex].id == 'period';
  }

  // 判断选中日期是否有生理期记录
  bool get _hasTodayPeriodRecord {
    final dateStr = _selectedDay.toIso8601String().substring(0, 10);
    return records.any((r) => r['date'] == dateStr && r['mode'] == '生理期');
  }

  // 获取预测的生理期日期（浅粉色显示）
  // 基于最近一次记录 + 周期长度进行预测
  // 支持查看未来任意月份的预测（当用户切换月份时）
  List<DateTime> _getPredictedPeriodDates() {
    final currentMode = modes.isNotEmpty && selectedModeIndex < modes.length
        ? modes[selectedModeIndex]
        : '';
    if (currentMode != '生理期') return [];

    // 默认周期参数
    const int defaultCycleLength = 28; // 默认周期28天
    const int defaultPeriodLength = 6; // 默认经期6天

    // 获取所有生理期记录，按日期排序
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return [];

    // 按日期排序，找到每个周期的开始日期
    periodRecords.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    // 找到所有周期的开始日期（标记为"生理期开始"的记录）
    final cycleStarts = <DateTime>[];
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        final date = DateTime.tryParse(r['date'] ?? '');
        if (date != null) {
          cycleStarts.add(date);
        }
      }
    }

    // 如果没有明确的开始标记，使用第一个记录日期
    if (cycleStarts.isEmpty) {
      final firstDate = DateTime.tryParse(periodRecords.first['date'] ?? '');
      if (firstDate != null) {
        cycleStarts.add(firstDate);
      }
    }

    if (cycleStarts.isEmpty) return [];

    // 获取最近一次周期开始日期
    cycleStarts.sort((a, b) => b.compareTo(a)); // 降序，最新的在前
    final lastCycleStart = cycleStarts.first;

    // 计算平均周期长度（如果有多个周期记录）
    int avgCycleLength = defaultCycleLength;
    if (cycleStarts.length >= 2) {
      final cycleLengths = <int>[];
      for (int i = 0; i < cycleStarts.length - 1; i++) {
        final length = cycleStarts[i].difference(cycleStarts[i + 1]).inDays;
        // 排除异常值（21-45天内的周期才计入）
        if (length >= 21 && length <= 45) {
          cycleLengths.add(length);
        }
      }
      if (cycleLengths.isNotEmpty) {
        avgCycleLength =
            (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length)
                .round();
      }
    }

    // 获取当前查看月份的范围
    final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

    // 计算从最后一次记录到当前查看月份需要多少个周期
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 生成预测日期列表
    final predictedDates = <DateTime>[];

    // 从最后一次记录开始，向前推算多个周期，直到覆盖当前查看的月份
    DateTime currentPrediction = lastCycleStart.add(
      Duration(days: avgCycleLength),
    );

    // 预测未来最多12个周期（约1年）
    for (int cycle = 0; cycle < 12; cycle++) {
      // 检查这个预测周期是否已经有实际记录了
      final hasActualRecord = cycleStarts.any((start) {
        final diff = (start.difference(currentPrediction).inDays).abs();
        return diff <= 7; // 7天内认为是同一个周期
      });

      if (!hasActualRecord) {
        // 生成这个周期的预测天数
        for (int day = 0; day < defaultPeriodLength; day++) {
          final predictedDate = currentPrediction.add(Duration(days: day));

          // 只添加当前查看月份内的预测
          if (predictedDate.year == focusedMonth.year &&
              predictedDate.month == focusedMonth.month) {
            // 检查这个日期是否已经有实际记录
            final dateStr = predictedDate.toIso8601String().substring(0, 10);
            final hasRecord = periodRecords.any((r) => r['date'] == dateStr);
            if (!hasRecord) {
              predictedDates.add(predictedDate);
            }
          }
        }
      }

      // 移动到下一个预测周期
      currentPrediction = currentPrediction.add(Duration(days: avgCycleLength));

      // 如果预测日期已经超过当前查看月份很多，停止计算
      if (currentPrediction.isAfter(nextMonth.add(const Duration(days: 45)))) {
        break;
      }
    }

    // 滚动推迟逻辑：如果预测日已过但用户未记录，今天也显示预测
    if (predictedDates.isEmpty &&
        focusedMonth.year == todayDate.year &&
        focusedMonth.month == todayDate.month) {
      // 计算下一个预测日期
      DateTime nextPrediction = lastCycleStart.add(
        Duration(days: avgCycleLength),
      );
      while (nextPrediction.isBefore(todayDate)) {
        nextPrediction = nextPrediction.add(Duration(days: avgCycleLength));
      }

      // 如果预测日已过但在合理范围内（15天内），从今天开始显示
      final daysSincePrediction = todayDate
          .difference(lastCycleStart.add(Duration(days: avgCycleLength)))
          .inDays;

      if (daysSincePrediction > 0 && daysSincePrediction <= 15) {
        for (int day = 0; day < defaultPeriodLength; day++) {
          final dateStr = todayDate
              .add(Duration(days: day))
              .toIso8601String()
              .substring(0, 10);
          final hasRecord = periodRecords.any((r) => r['date'] == dateStr);
          if (!hasRecord) {
            predictedDates.add(todayDate.add(Duration(days: day)));
          }
        }
      }
    }

    return predictedDates;
  }

  // 判断日期是否为预测日期
  bool _isPredictedDate(DateTime day) {
    if (!_isPeriodMode) return false;
    final predictedDates = _getPredictedPeriodDates();
    return predictedDates.any((d) => isSameDay(d, day));
  }

  // 获取推迟天数（用于滚动推迟显示）
  // 返回值：0=未推迟，>0=推迟天数，<0=还有几天到预测日
  int _getDelayDays() {
    if (!_isPeriodMode) return 0;

    const int defaultCycleLength = 28;

    // 获取所有周期开始日期
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return 0;

    final cycleStarts = <DateTime>[];
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        final date = DateTime.tryParse(r['date'] ?? '');
        if (date != null) cycleStarts.add(date);
      }
    }

    if (cycleStarts.isEmpty) {
      final firstDate = DateTime.tryParse(periodRecords.first['date'] ?? '');
      if (firstDate != null) cycleStarts.add(firstDate);
    }

    if (cycleStarts.isEmpty) return 0;

    cycleStarts.sort((a, b) => b.compareTo(a));
    final lastCycleStart = cycleStarts.first;

    // 计算平均周期
    int avgCycleLength = defaultCycleLength;
    if (cycleStarts.length >= 2) {
      final cycleLengths = <int>[];
      for (int i = 0; i < cycleStarts.length - 1; i++) {
        final length = cycleStarts[i].difference(cycleStarts[i + 1]).inDays;
        if (length >= 21 && length <= 45) cycleLengths.add(length);
      }
      if (cycleLengths.isNotEmpty) {
        avgCycleLength =
            (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length)
                .round();
      }
    }

    final predictedStart = lastCycleStart.add(Duration(days: avgCycleLength));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return todayDate.difference(predictedStart).inDays;
  }

  // 获取周期状态信息（用于显示提示）
  String _getPeriodStatusText() {
    if (!_isPeriodMode) return '';

    final delayDays = _getDelayDays();

    if (delayDays > 0) {
      if (delayDays > 15) {
        return '周期异常（推迟${delayDays}天）';
      }
      return '推迟${delayDays}天';
    } else if (delayDays == 0) {
      return '预计今天';
    } else {
      return '距下次${-delayDays}天';
    }
  }

  // 添加生理期记录
  // 支持选择任意日期作为开始日期
  // 如果已有记录，会进行合并处理
  Future<void> _addPeriodRecord() async {
    final now = DateTime.now();
    final startDate = _selectedDay;
    final today = DateTime(now.year, now.month, now.day);

    // 计算应该填充到哪一天（不超过今天，最多6天）
    final endDate = startDate.add(const Duration(days: 5)); // 第6天
    final actualEndDate = endDate.isAfter(today) ? today : endDate;

    // 查找当前周期是否已有"生理期开始"记录
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    String? existingCycleStart;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        existingCycleStart = r['date'];
        break;
      }
    }

    setState(() {
      // 如果已有开始记录，需要判断是修改还是新增
      if (existingCycleStart != null) {
        final existingStartDate = DateTime.tryParse(existingCycleStart);

        if (existingStartDate != null) {
          final daysDiff = existingStartDate.difference(startDate).inDays.abs();

          if (daysDiff <= 10) {
            // 10天内认为是同一个周期，需要调整开始日期
            // 删除旧的"生理期开始"标记
            final oldStartIndex = records.indexWhere(
              (r) => r['date'] == existingCycleStart && r['mode'] == '生理期',
            );
            if (oldStartIndex >= 0 && startDate.isBefore(existingStartDate)) {
              // 新日期更早，更新旧记录为自动填充
              records[oldStartIndex]['note'] = '生理期自动填充';
            }
          }
        }
      }

      // 填充从开始日期到实际结束日期的记录
      DateTime currentDate = startDate;
      int dayIndex = 0;

      while (!currentDate.isAfter(actualEndDate)) {
        final dateStr = currentDate.toIso8601String().substring(0, 10);

        // 检查该日期是否已有生理期记录
        final existingIndex = records.indexWhere(
          (r) => r['date'] == dateStr && r['mode'] == '生理期',
        );

        if (existingIndex >= 0) {
          // 已有记录，如果这是我们选的开始日期，更新标记
          if (dayIndex == 0) {
            records[existingIndex]['note'] = '生理期开始';
          }
        } else {
          // 没有记录，添加新记录
          final currentTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          final formattedDateTime =
              '${currentDate.year}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.day.toString().padLeft(2, '0')} $currentTime';

          records.insert(0, {
            'title': '${currentDate.month}月${currentDate.day}日 $currentTime',
            'note': dayIndex == 0 ? '生理期开始' : '生理期自动填充',
            'date': dateStr,
            'time': currentTime,
            'datetime': formattedDateTime,
            'mode': '生理期',
          });
        }

        currentDate = currentDate.add(const Duration(days: 1));
        dayIndex++;
      }
    });

    await _saveRecords();
  }

  // 为选中日期添加单条生理期记录（不是开始新周期）
  // 用于在周期范围内或恢复期内添加记录
  Future<void> _addPeriodRecordForSelectedDay() async {
    final now = DateTime.now();
    final dateStr = _selectedDay.toIso8601String().substring(0, 10);

    // 检查该日期是否已有记录
    final existingIndex = records.indexWhere(
      (r) => r['date'] == dateStr && r['mode'] == '生理期',
    );

    if (existingIndex >= 0) {
      // 已有记录，不需要添加
      return;
    }

    // 添加新记录（标记为自动填充）
    setState(() {
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final formattedDateTime =
          '${_selectedDay.year}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.day.toString().padLeft(2, '0')} $currentTime';

      records.insert(0, {
        'title': '${_selectedDay.month}月${_selectedDay.day}日 $currentTime',
        'note': '生理期自动填充',
        'date': dateStr,
        'time': currentTime,
        'datetime': formattedDateTime,
        'mode': '生理期',
      });
    });

    await _saveRecords();
  }

  // 删除选中日期的生理期记录
  Future<void> _removeTodayPeriodRecords() async {
    final dateStr = _selectedDay.toIso8601String().substring(0, 10);
    setState(() {
      records.removeWhere((r) => r['date'] == dateStr && r['mode'] == '生理期');
    });
    await _saveRecords();
  }

  // 删除当前周期的所有生理期记录（从开始日期开始的所有记录）
  // 当用户在生理期第一天点击"没来"时调用
  Future<void> _removeCurrentCycleRecords() async {
    final selectedDateStr = _selectedDay.toIso8601String().substring(0, 10);

    // 检查选中日期是否是周期开始日
    final isStartDay = records.any(
      (r) =>
          r['date'] == selectedDateStr &&
          r['mode'] == '生理期' &&
          r['note']?.contains('生理期开始') == true,
    );

    if (!isStartDay) return;

    setState(() {
      // 删除从开始日期开始的所有当前周期记录
      // 包括开始日和之后6天内的自动填充记录
      final startDate = _selectedDay;
      final endDate = startDate.add(const Duration(days: 6));

      records.removeWhere((r) {
        if (r['mode'] != '生理期') return false;
        final recordDateStr = r['date'] ?? '';
        // 删除从开始日期到结束日期的所有记录
        return recordDateStr.compareTo(selectedDateStr) >= 0 &&
            recordDateStr.compareTo(
                  endDate.toIso8601String().substring(0, 10),
                ) <=
                0;
      });
    });
    await _saveRecords();
  }

  // 标记生理期提前结束
  // 删除选中日期之后的自动填充记录，保留今天及之前的记录
  Future<void> _markPeriodEnded() async {
    final selectedDateStr = _selectedDay.toIso8601String().substring(0, 10);

    // 找到本周期的开始日期
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    // 找到当前周期的开始日期（最近的"生理期开始"记录）
    String? currentCycleStart;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        currentCycleStart = r['date'];
        break;
      }
    }

    if (currentCycleStart == null) return;

    setState(() {
      // 删除选中日期之后的自动填充记录（属于当前周期的）
      records.removeWhere((r) {
        if (r['mode'] != '生理期') return false;
        final recordDate = r['date'] ?? '';
        // 删除日期在选中日期之后且在当前周期内的记录
        return recordDate.compareTo(selectedDateStr) > 0 &&
            recordDate.compareTo(currentCycleStart!) >= 0;
      });

      // 更新选中日期的记录，标记为经期结束
      final todayRecordIndex = records.indexWhere(
        (r) => r['date'] == selectedDateStr && r['mode'] == '生理期',
      );
      if (todayRecordIndex >= 0) {
        records[todayRecordIndex]['note'] = '生理期结束';
      }
    });

    await _saveRecords();
  }

  // 判断选中日期是否是未来日期
  bool get _isSelectedDayFuture {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    return selectedDate.isAfter(todayDate);
  }

  // 判断是否在"走了"（经期结束）后的5天内
  // 返回：true = 显示走了/没走，false = 显示来了/没来
  bool get _isWithin5DaysAfterPeriodEnd {
    // 找到最近一次"生理期结束"的记录
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return false;

    // 按日期降序排序
    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    // 查找最近的"生理期结束"记录
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

    // 5天内返回true
    return daysSinceEnd >= 0 && daysSinceEnd <= 5;
  }

  // 取消"走了"状态，恢复经期记录
  Future<void> _cancelPeriodEnd() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 找到最近的"生理期结束"记录
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    String? endDateStr;
    String? cycleStartStr;

    for (var r in periodRecords) {
      if (r['note']?.contains('生理期结束') == true) {
        endDateStr = r['date'];
      }
      if (r['note']?.contains('生理期开始') == true) {
        cycleStartStr = r['date'];
        break;
      }
    }

    if (endDateStr == null || cycleStartStr == null) return;

    final endDate = DateTime.tryParse(endDateStr);
    final cycleStart = DateTime.tryParse(cycleStartStr);
    if (endDate == null || cycleStart == null) return;

    setState(() {
      // 将"生理期结束"改回"生理期自动填充"
      final endRecordIndex = records.indexWhere(
        (r) => r['date'] == endDateStr && r['mode'] == '生理期',
      );
      if (endRecordIndex >= 0) {
        records[endRecordIndex]['note'] = '生理期自动填充';
      }

      // 重新填充到今天为止（但不超过6天）
      final daysSinceStart = todayDate.difference(cycleStart).inDays;
      final maxDays = daysSinceStart < 6 ? daysSinceStart + 1 : 6;

      for (int i = 0; i < maxDays; i++) {
        final date = cycleStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().substring(0, 10);

        final hasRecord = records.any(
          (r) => r['date'] == dateStr && r['mode'] == '生理期',
        );

        if (!hasRecord) {
          final now = DateTime.now();
          final currentTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          final formattedDateTime =
              '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $currentTime';

          records.insert(0, {
            'title': '${date.month}月${date.day}日 $currentTime',
            'note': '生理期自动填充',
            'date': dateStr,
            'time': currentTime,
            'datetime': formattedDateTime,
            'mode': '生理期',
          });
        }
      }
    });

    await _saveRecords();
  }

  // 判断选中日期是否是当前周期的第一天（生理期开始日）
  bool get _isSelectedDayFirstDayOfCycle {
    final selectedDateStr = _selectedDay.toIso8601String().substring(0, 10);
    // 检查选中日期是否标记为"生理期开始"
    return records.any(
      (r) =>
          r['date'] == selectedDateStr &&
          r['mode'] == '生理期' &&
          r['note']?.contains('生理期开始') == true,
    );
  }

  // 判断选中日期是否在当前周期范围内
  // 返回值：true = 在周期范围内，应显示"走了/没走"
  // 逻辑：
  // - 如果周期尚未结束：开始日后的任意一天（只要没有手动点击"走了"）
  // - 如果周期已结束：开始日后第2天到结束日
  bool get _isWithinCurrentCycle {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    // 找到最近一次"生理期开始"的记录
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return false;

    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    String? cycleStartStr;
    String? cycleEndStr;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        cycleStartStr = r['date'];
        break;
      }
    }

    // 检查是否有"生理期结束"记录
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期结束') == true) {
        cycleEndStr = r['date'];
        break;
      }
    }

    if (cycleStartStr == null) return false;

    final cycleStart = DateTime.tryParse(cycleStartStr);
    if (cycleStart == null) return false;

    final cycleStartDate = DateTime(
      cycleStart.year,
      cycleStart.month,
      cycleStart.day,
    );

    // 计算选中日期与开始日期的天数差
    final daysSinceStart = selectedDate.difference(cycleStartDate).inDays;

    // 选中日期必须在开始日之后（第2天及以后）
    if (daysSinceStart < 1) return false;

    // 如果周期已经结束
    if (cycleEndStr != null) {
      final cycleEnd = DateTime.tryParse(cycleEndStr);
      if (cycleEnd != null) {
        final cycleEndDate = DateTime(
          cycleEnd.year,
          cycleEnd.month,
          cycleEnd.day,
        );
        // 选中日期在结束日之后，不在周期范围内
        if (selectedDate.isAfter(cycleEndDate)) {
          return false;
        }
      }
      // 选中日期在开始日之后、结束日当天或之前，在周期范围内
      return true;
    }

    // 周期尚未结束：开始日后的任意一天都在周期范围内
    // 用户可以随时选择"走了"来标记结束
    return true;
  }

  // 判断选中日期是否在预计结束日之后（需要提示用户标记结束）
  // 返回值：true = 在预计结束日之后且周期未结束，"走了"按钮应该高亮
  // 注意：如果周期已结束，返回false（由恢复期逻辑接管）
  bool get _isAfterExpectedEndDate {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    // 找到最近一次"生理期开始"的记录
    final periodRecords = records.where((r) => r['mode'] == '生理期').toList();
    if (periodRecords.isEmpty) return false;

    periodRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    String? cycleStartStr;
    String? cycleEndStr;
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期开始') == true) {
        cycleStartStr = r['date'];
        break;
      }
    }

    // 检查是否有"生理期结束"记录
    for (var r in periodRecords) {
      if (r['note']?.contains('生理期结束') == true) {
        cycleEndStr = r['date'];
        break;
      }
    }

    // 如果周期已结束，返回false（由恢复期逻辑接管）
    if (cycleEndStr != null) return false;

    if (cycleStartStr == null) return false;

    final cycleStart = DateTime.tryParse(cycleStartStr);
    if (cycleStart == null) return false;

    final cycleStartDate = DateTime(
      cycleStart.year,
      cycleStart.month,
      cycleStart.day,
    );

    // 预计结束日是开始日后第6天
    final expectedEndDate = cycleStartDate.add(const Duration(days: 5));

    // 选中日期在预计结束日之后返回true
    return selectedDate.isAfter(expectedEndDate);
  }

  // 判断选中日期是否在"走了"后的恢复期内（结束日后5天内）
  // 返回值：true = 在恢复期内，应显示"走了/没走"
  bool get _isWithinRecoveryPeriod {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    // 找到最近的"生理期结束"记录
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

    final cycleEndDate = DateTime(endDate.year, endDate.month, endDate.day);

    // 计算选中日期与结束日期的天数差
    final daysSinceEnd = selectedDate.difference(cycleEndDate).inDays;

    // 在结束日之后的1-5天内返回true
    return daysSinceEnd >= 1 && daysSinceEnd <= 5;
  }

  // 构建生理期 Switch 按钮
  // 逻辑说明：
  // - 未来日期：不显示按钮
  // - 第一天（生理期开始日）：显示"来了/没来"，让用户可以撤销
  // - 第2-6天（周期范围内）：显示"走了/没走"
  // - 无记录但在周期范围内（开始日后6天内）：显示"走了/没走"（用户可能延长）
  // - 无记录但在恢复期内（结束日后5天内）：显示"走了/没走"（用户可以取消结束）
  // - 其他情况：显示"来了/没来"
  Widget _buildPeriodSwitchButton() {
    // 检查是否是未来日期
    if (_isSelectedDayFuture) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: const Text(
          '未来日期无法操作',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final hasRecord = _hasTodayPeriodRecord;
    final isFirstDay = _isSelectedDayFirstDayOfCycle;
    final isWithinCycle = _isWithinCurrentCycle;
    final isWithinRecovery = _isWithinRecoveryPeriod;

    // 检查选中日期的记录是否标记为"生理期结束"
    final selectedDateStr = _selectedDay.toIso8601String().substring(0, 10);
    final isEnded = records.any(
      (r) =>
          r['date'] == selectedDateStr &&
          r['mode'] == '生理期' &&
          r['note']?.contains('生理期结束') == true,
    );

    // 关键逻辑：决定显示哪种按钮
    // 显示"走了/没走"的情况：
    // 1. 有记录且不是第一天（在周期范围内）
    // 2. 无记录但在周期范围内（包括延迟期，用户可以标记结束）
    // 3. 无记录但在恢复期内（结束日后5天内，用户可以取消结束或延长）
    final showEndedButtons =
        (hasRecord && !isFirstDay) ||
        (!hasRecord && isWithinCycle) ||
        (!hasRecord && isWithinRecovery);

    final leftText = showEndedButtons ? '走了' : '来了';
    final rightText = showEndedButtons ? '没走' : '没来';

    // 获取是否在预计结束日之后
    final isAfterExpected = _isAfterExpectedEndDate;

    // 判断哪边高亮
    // - 显示"走了/没走"时：
    //   - 已结束：左边高亮（走了）
    //   - 在预计结束日之后（第7天及以后）且周期未结束：左边高亮（提示用户该结束了）
    //   - 在结束日后的恢复期内：左边高亮（走了）
    //   - 其他：右边高亮（没走）
    // - 显示"来了/没来"时：
    //   - 有记录（第一天）：左边高亮（来了）
    //   - 其他：右边高亮（没来）
    final leftHighlight = showEndedButtons
        ? (isEnded || isAfterExpected || isWithinRecovery)
        : (hasRecord && isFirstDay);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE581A3), width: 1),
      ),
      child: Row(
        children: [
          // 左边按钮
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (showEndedButtons) {
                  // 显示"走了/没走"按钮
                  if (hasRecord && !isEnded) {
                    // 有记录且未结束，点击"走了"标记经期结束
                    await _markPeriodEnded();
                  } else if (!hasRecord && isWithinCycle) {
                    // 无记录但在周期范围内（未结束），点击"走了"先添加记录再标记结束
                    await _addPeriodRecordForSelectedDay();
                    await _markPeriodEnded();
                  } else if (!hasRecord && isWithinRecovery) {
                    // 无记录但在恢复期内（已结束后），点击"走了"延长生理期
                    // 先取消之前的结束状态（恢复记录），然后添加到选中日期并重新标记结束
                    await _cancelPeriodEnd();
                    await _addPeriodRecordForSelectedDay();
                    await _markPeriodEnded();
                  }
                  // 已结束状态（有记录），点击"走了"不做操作
                } else {
                  // 显示"来了/没来"按钮
                  if (!hasRecord) {
                    // 无记录，点击"来了"添加记录
                    await _addPeriodRecord();
                  }
                  // 有记录但是第一天，点击"来了"不做操作（已经来了）
                }
              },
              child: Container(
                height: double.infinity,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: leftHighlight
                      ? const Color(0xFFE581A3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  leftText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: leftHighlight
                        ? Colors.white
                        : const Color(0xFFE581A3),
                  ),
                ),
              ),
            ),
          ),
          // 右边按钮
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (showEndedButtons) {
                  // 显示"走了/没走"按钮
                  if (isEnded) {
                    // 已结束状态，点击"没走"取消结束，恢复记录
                    await _cancelPeriodEnd();
                  } else if (!hasRecord && isWithinRecovery) {
                    // 无记录但在恢复期内，点击"没走"取消结束，恢复记录
                    await _cancelPeriodEnd();
                  } else if (!hasRecord && isWithinCycle) {
                    // 无记录但在周期范围内，点击"没走"添加生理期记录
                    // 表示这一天还在生理期中，但不标记结束
                    await _addPeriodRecordForSelectedDay();
                  }
                  // 有记录但未结束，点击"没走"不做操作（保持当前状态）
                } else {
                  // 显示"来了/没来"按钮
                  if (hasRecord && isFirstDay) {
                    // 有记录且是第一天，点击"没来"删除该周期的所有记录
                    await _removeCurrentCycleRecords();
                  }
                  // 无记录时，点击"没来"不做操作
                }
              },
              child: Container(
                height: double.infinity,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: !leftHighlight
                      ? const Color(0xFFE581A3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: !leftHighlight
                        ? Colors.white
                        : const Color(0xFFE581A3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 编辑记录弹窗
  Future<void> _showEditRecordDialog(int index) async {
    final currentMode = modes[selectedModeIndex];
    String note = records[index]['note'] ?? '';
    final controller = TextEditingController(text: note);
    final recordTime = records[index]['time'] ?? '';

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
                        Icons.edit_outlined,
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
                            '编辑记录',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '当前模式：$currentMode',
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

                // 打卡时间显示卡片（只读）
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E4E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Color(0xFFE581A3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '打卡时间',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E4E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recordTime,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE581A3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                          setState(() {
                            records[index]['note'] = note.trim();
                          });
                          await _saveRecords();
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
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '保存修改',
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
                            '当前模式：$currentMode',
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
                          final currentTime =
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
                          final date = _selectedDay;
                          // 格式化日期时间：2025/12/20 09:00:24
                          final formattedDateTime =
                              '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} $currentTime';

                          setState(() {
                            final title =
                                '${date.month}月${date.day}日 $currentTime';
                            records.insert(0, {
                              'title': title,
                              'note': note.trim(),
                              'date': date.toIso8601String().substring(0, 10),
                              'time': currentTime,
                              'datetime': formattedDateTime,
                              'mode': currentMode,
                            });
                          });
                          await _saveRecords();
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

  @override
  Widget build(BuildContext context) {
    // 如果习惯列表还未加载，显示加载指示器
    if (modes.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFEEF3), Color(0xFFF9F9F9)],
              stops: [0.0, 0.4],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE581A3)),
          ),
        ),
      );
    }

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
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HabitManagePage(),
                          ),
                        );
                        // 返回后刷新习惯列表
                        _loadHabitsAndRecords();
                      },
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
                            lastDay: DateTime.utc(2030, 12, 31),
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
                              // 默认日期样式（用于显示预测日期的浅粉色背景）
                              defaultBuilder: (context, day, focusedDay) {
                                // 如果是预测日期且在生理期模式，显示浅粉色背景
                                if (_isPeriodMode && _isPredictedDate(day)) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFCE4EC), // 浅粉色
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Color(0xFFE581A3),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 记录列表标题
                        if (!_isPeriodMode) ...[
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  // 优先显示完整日期时间，兼容旧数据
                                                  record['datetime'] ??
                                                      '${record['date']?.replaceAll('-', '/')} ${record['time'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
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
                                                _showEditRecordDialog(
                                                  realIndex,
                                                );
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
        child: _isPeriodMode
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 周期状态提示
                  if (_getPeriodStatusText().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDelayDays() > 0
                              ? const Color(0xFFFFE0B2) // 推迟时用橙色背景
                              : _getDelayDays() == 0
                              ? const Color(0xFFE1BEE7) // 预计今天用紫色
                              : const Color(0xFFE8F5E9), // 未到日期用绿色
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPeriodStatusText(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _getDelayDays() > 0
                                ? const Color(0xFFE65100)
                                : _getDelayDays() == 0
                                ? const Color(0xFF7B1FA2)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  _buildPeriodSwitchButton(),
                ],
              )
            : SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 234, 145, 175),
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
