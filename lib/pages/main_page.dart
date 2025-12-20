import 'package:flutter/material.dart';
import 'package:first/pages/habit/habit_tracker_page.dart';
import 'package:first/pages/my_page.dart';
import 'package:first/pages/dashboard_page.dart';

/// 主页面 - 包含底部导航栏的应用主框架
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); //
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('果果'),
                accountEmail: Text('个性签名'),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://cdn.pixabay.com/photo/2025/08/23/07/17/rose-9791425_1280.jpg',
                  ),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE581A3),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://cdn.pixabay.com/photo/2025/09/04/11/33/coast-9815439_1280.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('首页'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('关于App'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('退出登录'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardPage(name: '果果'),
            HabitTrackerPage(name: '测试'),
            MyPage(),
          ],
        ),

        // floatingActionButton: FloatingActionButton(
        //   // 悬浮按钮
        //   onPressed: () async {
        //     await _dashboardKey.currentState?.getData();
        //   },
        //   backgroundColor: const Color(0xFFE581A3),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(30),
        //   ),
        //   child: const Icon(Icons.add, color: Colors.white),
        // ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '习惯',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFE581A3),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
