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
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, index) {
        return InkWell(
          // 👈 推荐用 InkWell（有水波纹效果）
          onTap: () {
            // 👇 点击跳转到详情页
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeCalendar(name: '宝宝${index + 1}'),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(children: [Text('这是${widget.name}的第 $index 条数据')]),
          ),
        );
      },
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
