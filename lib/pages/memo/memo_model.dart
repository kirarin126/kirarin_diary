/// 备忘录数据模型
class Memo {
  final String id;
  final String content;
  final String? type; // 自定义类型
  final bool isTimeSensitive; // 是否限时任务
  final DateTime? dueDate; // 截止日期（仅限时任务）
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted; // 是否已完成

  Memo({
    required this.id,
    required this.content,
    this.type,
    required this.isTimeSensitive,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  /// 创建限时任务（截止日期可选）
  factory Memo.createTimeSensitive({
    required String content,
    String? type,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Memo(
      id: now.millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      isTimeSensitive: true,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 创建临时想法
  factory Memo.createQuickNote({required String content, String? type}) {
    final now = DateTime.now();
    return Memo(
      id: now.millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      isTimeSensitive: false,
      dueDate: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON转换
  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'] as String,
      content: json['content'] as String,
      type: json['type'] as String?,
      isTimeSensitive: json['isTimeSensitive'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'isTimeSensitive': isTimeSensitive,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  /// 复制并修改
  Memo copyWith({
    String? content,
    String? type,
    bool? isTimeSensitive,
    DateTime? dueDate,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return Memo(
      id: id,
      content: content ?? this.content,
      type: type ?? this.type,
      isTimeSensitive: isTimeSensitive ?? this.isTimeSensitive,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 剩余天数（仅限时任务）
  int? get daysRemaining {
    if (!isTimeSensitive || dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  /// 是否已过期
  bool get isOverdue {
    final remaining = daysRemaining;
    return remaining != null && remaining < 0;
  }

  /// 是否即将到期（3天内）
  bool get isDueSoon {
    final remaining = daysRemaining;
    return remaining != null && remaining >= 0 && remaining <= 3;
  }
}
