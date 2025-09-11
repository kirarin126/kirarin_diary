import 'package:flutter/material.dart';
import 'package:first/pages/system/setting.dart';



class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: const Color.fromARGB(255, 78, 76, 76),
        ),
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F4F4),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 20.0,
            color: const Color.fromARGB(255, 114, 103, 103),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('这是我的页面')),
    );
  }
}
