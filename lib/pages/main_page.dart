import 'package:flutter/material.dart';
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
      length: 2,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text('果果'),
                accountEmail: const Text('个性签名'),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://cdn.pixabay.com/photo/2025/08/23/07/17/rose-9791425_1280.jpg',
                  ),
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFE581A3),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://cdn.pixabay.com/photo/2025/09/04/11/33/coast-9815439_1280.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('首页'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于App'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('退出登录'),
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
            MyPage(),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
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
