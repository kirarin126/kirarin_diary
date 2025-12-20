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

  // 删除习惯
  Future<void> _deleteHabit(int index) async {
    setState(() {
      _habits.removeAt(index);
      // 重新排序
      for (int i = 0; i < _habits.length; i++) {
        _habits[i].sortOrder = i;
      }
    });
    await _saveHabits();
  }

  // 显示删除确认弹窗
  Future<bool?> _showDeleteConfirmDialog(HabitConfig habit) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '确认删除自定义习惯吗？',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '删除后，此习惯相关的历史记录也将一并清空。',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE581A3), Color(0xFFEC8BA4)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            '确认',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
                // 添加习惯按钮
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: ElevatedButton(
                    onPressed: _navigateToAddHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE581A3),
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
    return ClipRRect(
      key: ValueKey(habit.id),
      borderRadius: BorderRadius.circular(12),
      child: Dismissible(
        key: Key('dismissible_${habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmDialog(habit);
        },
        onDismissed: (direction) {
          _deleteHabit(index);
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 30),
          child: const Text(
            '删除',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child: Container(
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
                activeColor: const Color(0xFFE581A3),
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
        ),
      ),
    );
  }
}
