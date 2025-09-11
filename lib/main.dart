// lib/main.dart

import 'package:flutter/material.dart';
import 'package:first/pages/home_page.dart'; // ✅ 引入 home_page.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 导入
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保绑定已初始化

  // 4. 设置首选的屏幕方向
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 5. 在方向设置完成后再运行 App
  await initializeDateFormatting('zh_CN');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kirarin',
      // 添加本地化代理和配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', 'CN'), // Chinese (Mainland)
        Locale('zh', 'TW'), // Chinese (Taiwan)
        // ... 其他支持的语言
      ],
      locale: const Locale('zh', 'CN'), // 设置默认语言为简体中文
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xFFE581A3,
          <int, Color>{
            50: Color(0xFFE581A3),
            100: Color(0xFFE581A3),
            200: Color(0xFFE581A3),
            300: Color(0xFFE581A3),
            400: Color(0xFFE581A3),
            500: Color(0xFFE581A3),
            600: Color(0xFFE581A3),
            700: Color(0xFFE581A3),
            800: Color(0xFFE581A3),
            900: Color(0xFFE581A3),
          },
        ), // 设置主题颜色
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // 设置全局背景色为白色
      ),
      home: const HomePage(),
    );
  }
}
