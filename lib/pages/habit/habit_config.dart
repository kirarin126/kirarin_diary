import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  int
  weeklyGoal; // Keep for backward compatibility or migration? Let's keep it but prioritize new fields.
  String goalType; // 'daily', 'weekly', 'none'
  int targetValue; // times

  HabitConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isEnabled = true,
    this.sortOrder = 0,
    this.weeklyGoal = 7,
    this.goalType = 'daily',
    this.targetValue = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color.value,
    'isEnabled': isEnabled,
    'sortOrder': sortOrder,
    'weeklyGoal': weeklyGoal,
    'goalType': goalType,
    'targetValue': targetValue,
  };

  factory HabitConfig.fromJson(Map<String, dynamic> json) => HabitConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: Color(json['color'] as int),
    isEnabled: json['isEnabled'] as bool? ?? true,
    sortOrder: json['sortOrder'] as int? ?? 0,
    weeklyGoal: json['weeklyGoal'] as int? ?? 7,
    goalType: json['goalType'] as String? ?? 'daily',
    targetValue: json['targetValue'] as int? ?? 1,
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

  // Update Habit (existing)
  static Future<void> updateHabit(HabitConfig habit) async {
    final configs = await loadConfigs();
    final index = configs.indexWhere((c) => c.id == habit.id);
    if (index >= 0) {
      configs[index] = habit;
      await saveConfigs(configs);
    }
  }

  // --- Icon Helpers ---

  static String serializeIcon(IconData icon) {
    return jsonEncode({
      'codePoint': icon.codePoint,
      'fontFamily': icon.fontFamily,
      'fontPackage': icon.fontPackage,
    });
  }

  static IconData? deserializeIcon(String iconStr) {
    try {
      if (!iconStr.trim().startsWith('{')) return null;
      final Map<String, dynamic> map = jsonDecode(iconStr);
      return IconData(
        map['codePoint'] as int,
        fontFamily: map['fontFamily'] as String?,
        fontPackage: map['fontPackage'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// 彩色图标集前缀列表
  static const List<String> _colorfulPrefixes = [
    'fluent-emoji',
    'fluent-emoji-flat',
    'fluent-emoji-high-contrast',
    'noto',
    'noto-v1',
    'twemoji',
    'openmoji',
    'emojione',
    'emojione-v1',
    'fxemoji',
    'logos',
    'skill-icons',
    'vscode-icons',
    'file-icons',
    'devicon',
    'catppuccin',
  ];

  /// 判断是否是彩色图标
  static bool _isColorfulIcon(String iconName) {
    final prefix = iconName.split(':').first;
    return _colorfulPrefixes.any((p) => prefix.startsWith(p));
  }

  static Widget getIconWidget(String iconStr, {double? size, Color? color}) {
    // Iconify icon format: "prefix:name" (e.g., "mdi:heart")
    if (iconStr.contains(':')) {
      final parts = iconStr.split(':');
      if (parts.length == 2) {
        final url = 'https://api.iconify.design/${parts[0]}/${parts[1]}.svg';
        final isColorful = _isColorfulIcon(iconStr);
        return SvgPicture.network(
          url,
          width: size ?? 24,
          height: size ?? 24,
          // 彩色图标不应用颜色滤镜
          colorFilter: (color != null && !isColorful)
              ? ColorFilter.mode(color, BlendMode.srcIn)
              : null,
          placeholderBuilder: (context) => SizedBox(
            width: size ?? 24,
            height: size ?? 24,
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
        );
      }
    }

    // Check if it's old serialized IconData format (JSON)
    final iconData = deserializeIcon(iconStr);
    if (iconData != null) {
      return Icon(iconData, size: size, color: color);
    }

    // Fallback to text (emoji/char)
    return Text(
      iconStr,
      style: TextStyle(
        fontSize: size ?? 24,
        color: color,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
