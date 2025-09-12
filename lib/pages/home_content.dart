// 首页内容
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './home_calendar.dart';

Dio dio = Dio();

class HomeContent extends StatefulWidget {
  // 接受一个name参数
  final String name;

  const HomeContent({super.key, required this.name});

  @override
  HomeContentState createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: const Color.fromARGB(255, 78, 76, 76),
        ),
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F4F4),
        actions: [],
      ),
      body: const Center(child: Text('功能开发中,敬请期待!')),
    );
  }

  getData() async {
    try {
      debugPrint('Hello 果果2');
      debugPrint('这里是调试信息');
      Response response = await dio.get('http://10.144.144.3:8000/api/users/');
      // 打印响应数据
      debugPrint('接口返回的数据=是这个: ${response.data}');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
