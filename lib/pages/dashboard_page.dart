// 仪表盘页面 - 首页内容展示
import 'package:flutter/material.dart';
import 'package:first/pages/widgets/habit_summary_section.dart';
import 'package:first/pages/habit/habit_tracker_page.dart';

/// 仪表盘页面 - 应用首页内容展示
class DashboardPage extends StatefulWidget {
  // 接受一个name参数
  final String name;

  const DashboardPage({super.key, required this.name});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  // GlobalKey 用于访问 HabitSummarySectionState
  final GlobalKey<HabitSummarySectionState> _habitSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToHabitPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HabitTrackerPage(name: '习惯追踪'),
      ),
    );
    // 返回后刷新健康习惯模块的数据
    _habitSectionKey.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 78, 76, 76),
        ),
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F4F4),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 健康习惯模块
            HabitSummarySection(
              key: _habitSectionKey,
              onMoreTap: _navigateToHabitPage,
            ),

            // 其他功能模块可以在这里添加
            // ...
          ],
        ),
      ),
    );
  }
}
