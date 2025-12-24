import 'package:flutter/material.dart';
import 'package:first/pages/memo/memo_model.dart';
import 'package:first/pages/memo/memo_manager.dart';

/// 备忘录详情页面 - 支持待办事项和临时想法
class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage>
    with SingleTickerProviderStateMixin {
  List<Memo> memos = [];
  List<String> customTypes = [];
  String? selectedType;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final allMemos = await MemoManager.getAllMemos();
    final types = await MemoManager.getCustomTypes();

    if (!mounted) return;
    setState(() {
      memos = allMemos;
      customTypes = types;
    });
  }

  List<Memo> get timeSensitiveMemos {
    var list = memos.where((m) => m.isTimeSensitive).toList();
    if (selectedType != null) {
      list = list.where((m) => m.type == selectedType).toList();
    }
    // 未完成在前，按截止日期排序
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return list;
  }

  List<Memo> get quickNotes {
    var list = memos.where((m) => !m.isTimeSensitive).toList();
    if (selectedType != null) {
      list = list.where((m) => m.type == selectedType).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('备忘录'),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 78, 76, 76),
        ),
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 78, 76, 76),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: const Color.fromARGB(255, 78, 76, 76),
            onPressed: () => _showTypeManageDialog(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFE581A3),
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '待办事项'),
                Tab(text: '临时想法'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEEF3), Color(0xFFFFF5F8), Colors.white],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 类型筛选（仅临时想法 tab）
              if (_tabController.index == 1) _buildTypeFilter(),

              // Tab内容
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildTimeSensitiveList(), _buildQuickNotesList()],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: const Color(0xFFE581A3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTypeFilter() {
    final usedTypes = memos
        .where((m) => m.type != null && m.type!.isNotEmpty)
        .map((m) => m.type!)
        .toSet()
        .toList();

    if (usedTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('全部', null),
            const SizedBox(width: 8),
            ...usedTypes.map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(type, type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? const Color(0xFFE581A3)
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE581A3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSensitiveList() {
    if (timeSensitiveMemos.isEmpty) {
      return _buildEmptyState('暂无待办事项');
    }

    final hasCompleted = timeSensitiveMemos.any((m) => m.isCompleted);

    return Column(
      children: [
        // 清除已完成按钮
        if (hasCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showClearCompletedDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cleaning_services_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '一键清除',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: timeSensitiveMemos.length,
            itemBuilder: (context, index) {
              return _buildTimeSensitiveCard(timeSensitiveMemos[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showClearCompletedDialog() async {
    final completedCount = timeSensitiveMemos
        .where((m) => m.isCompleted)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('清除已完成'),
        content: Text('确定要清除 $completedCount 个已完成的待办事项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE581A3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await MemoManager.clearCompletedTasks();
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('已清除 $count 个完成项'),
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
    }
  }

  Widget _buildQuickNotesList() {
    if (quickNotes.isEmpty) {
      return _buildEmptyState('暂无临时想法');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quickNotes.length,
      itemBuilder: (context, index) {
        return _buildQuickNoteCard(quickNotes[index]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSensitiveCard(Memo memo) {
    final daysRemaining = memo.daysRemaining;
    final isOverdue = memo.isOverdue;
    final isDueSoon = memo.isDueSoon;

    Color statusColor;
    String statusText;
    if (memo.isCompleted) {
      statusColor = Colors.green;
      statusText = '已完成';
    } else if (isOverdue) {
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

    return Dismissible(
      key: Key(memo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmDialog(memo),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => _showAddEditDialog(memo),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 勾选框
              GestureDetector(
                onTap: () async {
                  await MemoManager.toggleComplete(memo.id);
                  _loadData();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: memo.isCompleted ? statusColor : Colors.transparent,
                    border: Border.all(color: statusColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: memo.isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: memo.isCompleted
                            ? Colors.grey.shade400
                            : Colors.black87,
                        decoration: memo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
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

              Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNoteCard(Memo memo) {
    return Dismissible(
      key: Key(memo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmDialog(memo),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => _showAddEditDialog(memo),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFE581A3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (memo.type != null && memo.type!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              memo.type!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(memo.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final memoDate = DateTime(time.year, time.month, time.day);

    if (memoDate == today) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (memoDate == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else if (time.year == now.year) {
      return '${time.month}月${time.day}日';
    } else {
      return '${time.year}/${time.month}/${time.day}';
    }
  }

  Future<bool> _showDeleteConfirmDialog(Memo memo) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('确认删除'),
            content: Text('确定要删除这条备忘吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  '取消',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await MemoManager.deleteMemo(memo.id);
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE581A3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showTypeManageDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '管理类型',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 添加新类型
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '输入新类型名称...',
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (value) async {
                              if (value.trim().isNotEmpty) {
                                await MemoManager.addCustomType(value.trim());
                                final types =
                                    await MemoManager.getCustomTypes();
                                setModalState(() {
                                  customTypes = types;
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 类型列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customTypes.length,
                      itemBuilder: (context, index) {
                        final type = customTypes[index];
                        return ListTile(
                          title: Text(type),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await MemoManager.deleteCustomType(type);
                              final types = await MemoManager.getCustomTypes();
                              setModalState(() {
                                customTypes = types;
                              });
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _loadData();
  }

  Future<void> _showAddEditDialog(Memo? memo) async {
    final isEdit = memo != null;
    final contentController = TextEditingController(text: memo?.content ?? '');
    String? selectedType = memo?.type;
    bool isTimeSensitive = memo?.isTimeSensitive ?? (_tabController.index == 0);
    int dueDays = 3;
    if (memo?.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        memo!.dueDate!.year,
        memo.dueDate!.month,
        memo.dueDate!.day,
      );
      dueDays = due.difference(today).inDays;
      if (dueDays < 1) dueDays = 1;
    }

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
                child: SingleChildScrollView(
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
                              isEdit
                                  ? Icons.edit_outlined
                                  : Icons.note_add_outlined,
                              color: const Color(0xFFE581A3),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? '编辑备忘' : '添加备忘',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 类型切换
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    isTimeSensitive = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTimeSensitive
                                        ? const Color(0xFFE581A3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '待办事项',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isTimeSensitive
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    isTimeSensitive = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isTimeSensitive
                                        ? const Color(0xFFE581A3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '临时想法',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: !isTimeSensitive
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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
                              autofocus: !isEdit,
                              maxLines: 3,
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

                            // 截止时间（仅待办事项）
                            if (isTimeSensitive) ...[
                              const SizedBox(height: 16),
                              const Text(
                                '截止时间',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [1, 3, 7, 14, 30].map((days) {
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
                                }).toList(),
                              ),
                            ],

                            // 类型选择（仅临时想法）
                            if (!isTimeSensitive) ...[
                              const SizedBox(height: 16),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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

                                if (isEdit) {
                                  final updated = memo.copyWith(
                                    content: content,
                                    type: selectedType,
                                    isTimeSensitive: isTimeSensitive,
                                    dueDate: isTimeSensitive
                                        ? DateTime.now().add(
                                            Duration(days: dueDays),
                                          )
                                        : null,
                                  );
                                  await MemoManager.updateMemo(updated);
                                } else {
                                  Memo newMemo;
                                  if (isTimeSensitive) {
                                    newMemo = Memo.createTimeSensitive(
                                      content: content,
                                      type: selectedType,
                                      dueDate: DateTime.now().add(
                                        Duration(days: dueDays),
                                      ),
                                    );
                                  } else {
                                    newMemo = Memo.createQuickNote(
                                      content: content,
                                      type: selectedType,
                                    );
                                  }
                                  await MemoManager.addMemo(newMemo);
                                }

                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                _loadData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE581A3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? '保存' : '添加',
                                    style: const TextStyle(
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
              ),
            );
          },
        );
      },
    );
  }
}
