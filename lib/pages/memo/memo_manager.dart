import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'memo_model.dart';

/// 备忘录数据管理器
class MemoManager {
  static const String _storageKey = 'memo_records';
  static const String _customTypesKey = 'memo_custom_types';

  /// 获取所有备忘录
  static Future<List<Memo>> getAllMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Memo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取限时任务（首页用）
  static Future<List<Memo>> getTimeSensitiveMemos({int limit = 3}) async {
    final memos = await getAllMemos();
    final timeSensitive = memos
        .where((m) => m.isTimeSensitive && !m.isCompleted)
        .toList();
    // 按截止日期排序，最紧急的在前
    timeSensitive.sort((a, b) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return timeSensitive.take(limit).toList();
  }

  /// 获取临时想法
  static Future<List<Memo>> getQuickNotes() async {
    final memos = await getAllMemos();
    return memos.where((m) => !m.isTimeSensitive).toList();
  }

  /// 按类型筛选
  static Future<List<Memo>> getMemosByType(String? type) async {
    final memos = await getAllMemos();
    if (type == null || type.isEmpty) return memos;
    return memos.where((m) => m.type == type).toList();
  }

  /// 添加备忘录
  static Future<void> addMemo(Memo memo) async {
    final memos = await getAllMemos();
    memos.insert(0, memo);
    await _saveMemos(memos);
  }

  /// 更新备忘录
  static Future<void> updateMemo(Memo memo) async {
    final memos = await getAllMemos();
    final index = memos.indexWhere((m) => m.id == memo.id);
    if (index >= 0) {
      memos[index] = memo;
      await _saveMemos(memos);
    }
  }

  /// 删除备忘录
  static Future<void> deleteMemo(String id) async {
    final memos = await getAllMemos();
    memos.removeWhere((m) => m.id == id);
    await _saveMemos(memos);
  }

  /// 标记完成/未完成
  static Future<void> toggleComplete(String id) async {
    final memos = await getAllMemos();
    final index = memos.indexWhere((m) => m.id == id);
    if (index >= 0) {
      memos[index] = memos[index].copyWith(
        isCompleted: !memos[index].isCompleted,
      );
      await _saveMemos(memos);
    }
  }

  /// 保存备忘录列表
  static Future<void> _saveMemos(List<Memo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(memos.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  /// 获取自定义类型列表
  static Future<List<String>> getCustomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customTypesKey);
    if (data == null) {
      // 默认类型
      return ['购物', '任务', '提醒', '工作', '生活'];
    }
    final List<dynamic> list = jsonDecode(data);
    return list.cast<String>();
  }

  /// 保存自定义类型
  static Future<void> saveCustomTypes(List<String> types) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customTypesKey, jsonEncode(types));
  }

  /// 添加自定义类型
  static Future<void> addCustomType(String type) async {
    final types = await getCustomTypes();
    if (!types.contains(type)) {
      types.add(type);
      await saveCustomTypes(types);
    }
  }

  /// 删除自定义类型
  static Future<void> deleteCustomType(String type) async {
    final types = await getCustomTypes();
    types.remove(type);
    await saveCustomTypes(types);
  }

  /// 获取所有使用过的类型
  static Future<List<String>> getUsedTypes() async {
    final memos = await getAllMemos();
    final types = memos
        .where((m) => m.type != null && m.type!.isNotEmpty)
        .map((m) => m.type!)
        .toSet()
        .toList();
    return types;
  }

  /// 清除所有已完成的待办事项
  static Future<int> clearCompletedTasks() async {
    final memos = await getAllMemos();
    final completedCount = memos
        .where((m) => m.isTimeSensitive && m.isCompleted)
        .length;
    memos.removeWhere((m) => m.isTimeSensitive && m.isCompleted);
    await _saveMemos(memos);
    return completedCount;
  }
}
