import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final List<Map<String, dynamic>> settings = [
    {'icon': Icons.people_alt_outlined, 'title': '账号与安全', 'onTap': () {}},
    {'icon': Icons.color_lens, 'title': '主题设置', 'onTap': () {}},
    {'icon': Icons.font_download, 'title': '字体设置', 'onTap': () {}},
    {'icon': Icons.info, 'title': '关于我们', 'onTap': () {}},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // 设置整个页面的背景色
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF393939),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('设置'),
        titleTextStyle: TextStyle(fontSize: 16, color: const Color(0xFF393939)),
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: const Color(0xFFFAFAFA), // 设置AppBar背景为白色
        // surfaceTintColor: const Color(0xFFF4F4F4), // 设置背景色
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    //  color: Color.fromRGBO(128, 128, 128, 0.3),
                    //   spreadRadius: 2,
                    //   blurRadius: 5,
                    //   offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true, // 让ListView根据内容高度自适应
                children: settings.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  bool isLast = index == settings.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: isLast
                          ? null
                          : const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFF0F0F0)),
                              ),
                            ),
                      child: ListTile(
                        // dense: true, // 让 ListTile 更紧凑
                        leading: Icon(item['icon'], size: 22),
                        title: Text(item['title']),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFFB0B0B0),
                        ),
                        onTap: item['onTap'],
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 清除本地登录状态
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                minimumSize: const Size(
                  double.infinity,
                  44,
                ), // 设置按钮宽度为屏幕宽度，高度为44
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 圆角
                ),
                shadowColor: Colors.transparent, // 去掉阴影
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 16, color: Color(0xFF393939)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
