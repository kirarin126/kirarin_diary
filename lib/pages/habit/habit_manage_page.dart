import 'package:flutter/material.dart';
import 'habit_config.dart';
import 'add_habit_page.dart';

/// 习惯管理页面 - 管理所有习惯的开关和排序
class HabitManagePage extends StatefulWidget {
  const HabitManagePage({super.key});

  @override
  State<HabitManagePage> createState() => _HabitManagePageState();
}

class _HabitManagePageState extends State<HabitManagePage> {
  List<HabitConfig> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await HabitConfigManager.loadConfigs();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  Future<void> _saveHabits() async {
    await HabitConfigManager.saveConfigs(_habits);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _habits.removeAt(oldIndex);
      _habits.insert(newIndex, item);
      // 更新排序
      for (int i = 0; i < _habits.length; i++) {
        _habits[i].sortOrder = i;
      }
    });
    _saveHabits();
  }

  void _toggleHabit(int index, bool value) {
    setState(() {
      _habits[index].isEnabled = value;
    });
    _saveHabits();
  }

  Future<void> _navigateToAddHabit() async {
    final result = await Navigator.of(context).push<HabitConfig>(
      MaterialPageRoute(builder: (context) => const AddHabitPage()),
    );
    if (result != null) {
      await HabitConfigManager.addHabit(result);
      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black54,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '习惯管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _habits.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      return _buildHabitItem(habit, index);
                    },
                  ),
                ),
                // 底部提示
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1、关闭后，仅隐藏对应习惯入口，不会清空历史数据。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2、按住习惯上下拖动，可调整排序。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 添加习惯按钮
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: ElevatedButton(
                    onPressed: _navigateToAddHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '添加习惯',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHabitItem(HabitConfig habit, int index) {
    return Container(
      key: ValueKey(habit.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: habit.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                habit.icon,
                style: TextStyle(
                  fontSize: habit.icon.length == 1 ? 20 : 24,
                  color: habit.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 习惯名称
          Expanded(
            child: Text(
              habit.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // 开关
          Switch(
            value: habit.isEnabled,
            onChanged: (value) => _toggleHabit(index, value),
            activeColor: const Color(0xFF4A90E2),
          ),
          // 拖动手柄
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.menu, color: Colors.grey, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
