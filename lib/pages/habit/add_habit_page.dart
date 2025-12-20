import 'package:flutter/material.dart';
import 'habit_config.dart';

/// 添加习惯页面
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  int _weeklyGoal = 7;
  int _selectedColorIndex = 0;

  // 可选颜色列表
  final List<Color> _colors = [
    const Color(0xFF4A90E2), // 蓝色
    const Color(0xFF5C6BC0), // 靛蓝色
    const Color(0xFF26A69A), // 青色
    const Color(0xFF66BB6A), // 绿色
    const Color(0xFF9CCC65), // 浅绿色
    const Color(0xFFFFCA28), // 黄色
    const Color(0xFF8D6E63), // 棕色
    const Color(0xFFEC407A), // 粉红色
    const Color(0xFFAB47BC), // 紫色
    const Color(0xFFEF5350), // 红色
  ];

  void _showGoalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '选择每周打卡目标',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...List.generate(7, (index) {
                final days = index + 1;
                return ListTile(
                  title: Text('每周打卡 $days 天', textAlign: TextAlign.center),
                  onTap: () {
                    setState(() {
                      _weeklyGoal = days;
                    });
                    Navigator.of(context).pop();
                  },
                  trailing: _weeklyGoal == days
                      ? const Icon(Icons.check, color: Color(0xFF4A90E2))
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入习惯名称')));
      return;
    }

    if (name.length > 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('习惯名称不能超过10个字')));
      return;
    }

    final habitIcon = icon.isNotEmpty ? icon : name.substring(0, 1);
    final habit = HabitConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: habitIcon,
      color: _colors[_selectedColorIndex],
      isEnabled: true,
      weeklyGoal: _weeklyGoal,
    );

    Navigator.of(context).pop(habit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = _iconController.text.isNotEmpty
        ? _iconController.text
        : (_nameController.text.isNotEmpty
              ? _nameController.text.substring(0, 1)
              : '文');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        title: const Text(
          '添加习惯',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveHabit,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 习惯名称
            const Text(
              '习惯名称',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '请输入习惯名称（10字内）',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),

            // 目标
            const Text(
              '目标',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showGoalPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '目标',
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        Text(
                          '每周打卡 $_weeklyGoal 天',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 图标文字
            const Text(
              '图标文字',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _iconController,
                maxLength: 2,
                decoration: InputDecoration(
                  hintText: '输入1个字',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(height: 40),

            // 图标预览
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayIcon,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _colors[_selectedColorIndex],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 颜色选择
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(_colors.length, (index) {
                  final color = _colors[index];
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
