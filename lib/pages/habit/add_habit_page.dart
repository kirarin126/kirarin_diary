import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'habit_config.dart';

/// 添加/编辑习惯页面
class AddHabitPage extends StatefulWidget {
  final HabitConfig? habitToEdit; // 要编辑的习惯，为 null 时表示添加模式

  const AddHabitPage({super.key, this.habitToEdit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();

  String _goalType = 'daily';
  int _targetValue = 1;
  int _selectedColorIndex = 0;

  bool get isEditMode => widget.habitToEdit != null;

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

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      final habit = widget.habitToEdit!;
      _nameController.text = habit.name;
      _goalType = habit.goalType;
      _targetValue = habit.targetValue;

      _iconController.text = habit.icon;

      // 兼容旧数据
      if (_goalType == 'daily' && habit.weeklyGoal != 7) {
        // 如果旧数据 goalType 是默认 'daily' 但 weeklyGoal 不是 7，可能是旧的每周打卡习惯
        // 这里不做太多假设，主要依赖新字段
      }

      // 查找对应的颜色索引
      final colorIndex = _colors.indexWhere(
        (c) => c.value == habit.color.value,
      );
      if (colorIndex >= 0) {
        _selectedColorIndex = colorIndex;
      }
    }
  }

  void _showGoalPicker() {
    // 临时状态，用于 Picker 滚动时的变化，点击确定才同步到 valid values
    String tempType = _goalType;
    int tempValue = _targetValue;

    // 类型列表
    final types = ['每天打卡', '每周打卡', '不设置目标'];
    // 类型对应的 key
    final typeKeys = ['daily', 'weekly', 'none'];

    int initialTypeIndex = typeKeys.indexOf(_goalType);
    if (initialTypeIndex == -1) initialTypeIndex = 0;

    // 次数列表 (1-100)
    final values = List.generate(100, (index) => index + 1);
    int initialValueIndex = values.indexOf(_targetValue);
    if (initialValueIndex == -1) initialValueIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 350,
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                children: [
                  const Text(
                    '目标',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 左侧：类型选择
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: initialTypeIndex,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempType = typeKeys[index];
                              });
                            },
                            children: types
                                .map(
                                  (t) => Center(
                                    child: Text(
                                      t,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        // 右侧：次数选择 (只有非“不设置目标”才显示)
                        if (tempType != 'none')
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController:
                                        FixedExtentScrollController(
                                          initialItem: initialValueIndex,
                                        ),
                                    onSelectedItemChanged: (index) {
                                      tempValue = values[index];
                                    },
                                    children: values
                                        .map(
                                          (v) => Center(
                                            child: Text(
                                              '$v',
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const Text('次', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        if (tempType == 'none')
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _goalType = tempType;
                            if (_goalType == 'none') {
                              _targetValue = 0;
                            } else {
                              _targetValue = tempValue;
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFE581A3,
                          ), // 粉色，与保存按钮保持一致
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    // Icon logic: if _selectedIcon is set, serialize it. Else use text.
    final iconText = _iconController.text.trim();
    final finalIconStr = iconText.isNotEmpty
        ? iconText
        : (name.isNotEmpty ? name.substring(0, 1) : '文');

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

    final habit = HabitConfig(
      id: isEditMode
          ? widget.habitToEdit!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: finalIconStr,
      color: _colors[_selectedColorIndex],
      isEnabled: isEditMode ? widget.habitToEdit!.isEnabled : true,
      sortOrder: isEditMode ? widget.habitToEdit!.sortOrder : 0,
      goalType: _goalType,
      targetValue: _targetValue,
      weeklyGoal: _goalType == 'weekly' ? _targetValue : 7, // 简单兼容
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
    // Determined what to display in preview
    final text = _iconController.text.isNotEmpty
        ? _iconController.text
        : (_nameController.text.isNotEmpty
              ? _nameController.text.substring(0, 1)
              : '文');

    Widget displayIconWidget = Text(
      text,
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: _colors[_selectedColorIndex],
      ),
    );

    String goalText = '';
    if (_goalType == 'daily') {
      goalText = '每天打卡 $_targetValue 次';
    } else if (_goalType == 'weekly') {
      goalText = '每周打卡 $_targetValue 次';
    } else {
      goalText = '不设置目标';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80, // 增加宽度以显示"取消"
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        title: Text(
          isEditMode ? '编辑习惯' : '添加习惯',
          style: const TextStyle(
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
                backgroundColor: const Color(0xFFE581A3), // 粉色
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: const Size(60, 32), // 更小的尺寸
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                          goalText,
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

            // 图标
            const Text(
              '图标',
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
                  hintText: '或者输入文字/Emoji (1个字)',
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
                child: Center(child: displayIconWidget),
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
