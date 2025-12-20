import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 习惯数据模型
class HabitConfig {
  String id;
  String name;
  String icon;
  Color color;
  bool isEnabled;
  int sortOrder;
  int weeklyGoal; // 每周打卡目标天数

  HabitConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isEnabled = true,
    this.sortOrder = 0,
    this.weeklyGoal = 7,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color.value,
    'isEnabled': isEnabled,
    'sortOrder': sortOrder,
    'weeklyGoal': weeklyGoal,
  };

  factory HabitConfig.fromJson(Map<String, dynamic> json) => HabitConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: Color(json['color'] as int),
    isEnabled: json['isEnabled'] as bool? ?? true,
    sortOrder: json['sortOrder'] as int? ?? 0,
    weeklyGoal: json['weeklyGoal'] as int? ?? 7,
  );
}

/// 习惯配置管理器
class HabitConfigManager {
  static const String _configKey = 'habit_configs';

  // 默认习惯列表
  static List<HabitConfig> get defaultHabits => [
    HabitConfig(
      id: 'poop',
      name: '便便',
      icon: '💩',
      color: const Color(0xFF795548),
      isEnabled: true,
      sortOrder: 0,
    ),
    HabitConfig(
      id: 'wash_hair',
      name: '洗头',
      icon: '洗',
      color: const Color(0xFFE581A3),
      isEnabled: true,
      sortOrder: 1,
    ),
    HabitConfig(
      id: 'period',
      name: '生理期',
      icon: '🩸',
      color: const Color(0xFFE581A3),
      isEnabled: true,
      sortOrder: 2,
    ),
    HabitConfig(
      id: 'exercise',
      name: '简单练',
      icon: '🏃',
      color: const Color(0xFF4CAF50),
      isEnabled: false,
      sortOrder: 3,
    ),
    HabitConfig(
      id: 'early_rise',
      name: '早起',
      icon: '☀️',
      color: const Color(0xFFFFEB3B),
      isEnabled: false,
      sortOrder: 4,
    ),
    HabitConfig(
      id: 'early_sleep',
      name: '早睡',
      icon: '🌙',
      color: const Color(0xFF673AB7),
      isEnabled: false,
      sortOrder: 5,
    ),
  ];

  // 加载习惯配置
  static Future<List<HabitConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_configKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      final configs = list.map((e) => HabitConfig.fromJson(e)).toList();
      configs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return configs;
    }
    // 首次使用，保存默认配置
    await saveConfigs(defaultHabits);
    return defaultHabits;
  }

  // 保存习惯配置
  static Future<void> saveConfigs(List<HabitConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _configKey,
      jsonEncode(configs.map((e) => e.toJson()).toList()),
    );
  }

  // 获取启用的习惯列表
  static Future<List<HabitConfig>> getEnabledHabits() async {
    final configs = await loadConfigs();
    return configs.where((c) => c.isEnabled).toList();
  }

  // 添加习惯
  static Future<void> addHabit(HabitConfig habit) async {
    final configs = await loadConfigs();
    habit.sortOrder = configs.length;
    configs.add(habit);
    await saveConfigs(configs);
  }

  // 删除习惯
  static Future<void> deleteHabit(String id) async {
    final configs = await loadConfigs();
    configs.removeWhere((c) => c.id == id);
    // 重新排序
    for (int i = 0; i < configs.length; i++) {
      configs[i].sortOrder = i;
    }
    await saveConfigs(configs);
  }
}
