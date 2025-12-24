import 'package:flutter/material.dart';
import 'package:first/pages/memo/memo_model.dart';
import 'package:first/pages/memo/memo_manager.dart';
import 'package:first/pages/memo/memo_page.dart';

/// 首页备忘录摘要组件 - 只显示限时任务
class MemoSummarySection extends StatefulWidget {
  final VoidCallback? onMoreTap;

  const MemoSummarySection({super.key, this.onMoreTap});

  @override
  MemoSummarySectionState createState() => MemoSummarySectionState();
}

class MemoSummarySectionState extends State<MemoSummarySection> {
  List<Memo> timeSensitiveMemos = [];

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  /// 刷新数据
  Future<void> refreshData() async {
    final memos = await MemoManager.getTimeSensitiveMemos(limit: 3);
    if (!mounted) return;
    setState(() {
      timeSensitiveMemos = memos;
    });
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
                '临时备忘',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToMemoPage(),
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
          const SizedBox(height: 12),

          // 快速添加按钮 - 两个并排
          Row(
            children: [
              Expanded(child: _buildAddTaskButton()),
              const SizedBox(width: 8),
              Expanded(child: _buildAddNoteButton()),
            ],
          ),

          const SizedBox(height: 12),

          // 限时任务列表
          if (timeSensitiveMemos.isEmpty)
            _buildEmptyState()
          else
            ...timeSensitiveMemos.map((memo) => _buildMemoItem(memo)),
        ],
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return GestureDetector(
      onTap: () => _showQuickAddDialog(isTimeSensitive: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE581A3).withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE581A3).withAlpha(25),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.add_task,
                color: Color(0xFFE581A3),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '待办',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNoteButton() {
    return GestureDetector(
      onTap: () => _showQuickAddDialog(isTimeSensitive: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE581A3).withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE581A3).withAlpha(25),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFE581A3),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '想法',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无待办事项',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoItem(Memo memo) {
    final daysRemaining = memo.daysRemaining;
    final isOverdue = memo.isOverdue;
    final isDueSoon = memo.isDueSoon;
    final hasDueDate = memo.dueDate != null;

    Color statusColor;
    String? statusText;
    if (hasDueDate) {
      if (isOverdue) {
        statusColor = Colors.red;
        statusText = '已过期${-daysRemaining!}天';
      } else if (daysRemaining == 0) {
        statusColor = Colors.orange;
        statusText = '今天截止';
      } else if (isDueSoon) {
        statusColor = Colors.orange;
        statusText = '还剩${daysRemaining}天';
      } else {
        statusColor = const Color(0xFFE581A3);
        statusText = '还剩${daysRemaining}天';
      }
    } else {
      statusColor = const Color(0xFFE581A3);
      statusText = null;
    }

    return GestureDetector(
      onTap: () async {
        final wasCompleted = memo.isCompleted;
        await MemoManager.toggleComplete(memo.id);
        refreshData();

        // 显示完成提示
        if (!wasCompleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${memo.content}" 已完成',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE581A3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // 勾选框
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: memo.isCompleted ? statusColor : Colors.transparent,
                border: Border.all(color: statusColor, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: memo.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: memo.isCompleted
                          ? Colors.grey.shade400
                          : Colors.black87,
                      decoration: memo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (memo.type != null && memo.type!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            memo.type!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (statusText != null) const SizedBox(width: 8),
                      ],
                      if (statusText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMemoPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MemoPage()));
    refreshData();
  }

  Future<void> _showQuickAddDialog({required bool isTimeSensitive}) async {
    final contentController = TextEditingController();
    List<String> customTypes = await MemoManager.getCustomTypes();
    String? selectedType;
    int? dueDays; // null 表示无截止日期

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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

                    // 标题
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE581A3).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTimeSensitive
                                ? Icons.add_task
                                : Icons.lightbulb_outline,
                            color: const Color(0xFFE581A3),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isTimeSensitive ? '添加待办事项' : '记录想法',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 内容输入
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
                          TextField(
                            controller: contentController,
                            autofocus: true,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: isTimeSensitive
                                  ? '输入待办内容...'
                                  : '记录你的想法...',
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
                          ),
                          const SizedBox(height: 16),

                          // 截止时间选择（仅待办事项）
                          if (isTimeSensitive) ...[
                            const Text(
                              '截止时间（可选）',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // 无截止日期选项
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      dueDays = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dueDays == null
                                          ? const Color(0xFFE581A3)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '不限',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: dueDays == null
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                // 日期选项
                                ...[1, 3, 7, 14, 30].map((days) {
                                  final isSelected = dueDays == days;
                                  String label;
                                  if (days == 1) {
                                    label = '明天';
                                  } else if (days == 7) {
                                    label = '1周';
                                  } else if (days == 14) {
                                    label = '2周';
                                  } else if (days == 30) {
                                    label = '1月';
                                  } else {
                                    label = '$days天';
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        dueDays = days;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE581A3)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 类型选择（仅临时想法）
                          if (!isTimeSensitive) ...[
                            const Text(
                              '类型（可选）',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: customTypes.map((type) {
                                final isSelected = selectedType == type;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedType = isSelected ? null : type;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE581A3)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 按钮
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
                              final content = contentController.text.trim();
                              if (content.isEmpty) return;

                              Memo memo;
                              if (isTimeSensitive) {
                                final dueDate = dueDays != null
                                    ? DateTime.now().add(
                                        Duration(days: dueDays!),
                                      )
                                    : null;
                                memo = Memo.createTimeSensitive(
                                  content: content,
                                  type: selectedType,
                                  dueDate: dueDate,
                                );
                              } else {
                                memo = Memo.createQuickNote(
                                  content: content,
                                  type: selectedType,
                                );
                              }
                              await MemoManager.addMemo(memo);

                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              refreshData();

                              // 显示添加成功提示
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          isTimeSensitive
                                              ? Icons.add_task
                                              : Icons.lightbulb,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isTimeSensitive
                                                ? '待办事项已添加'
                                                : '想法已记录',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFFE581A3),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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
                                  '添加',
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
      },
    );
  }
}
