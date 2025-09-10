// lib/main.dart

import 'package:flutter/material.dart';
import 'package:first/pages/home_page.dart'; // ✅ 引入 home_page.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 导入

void main() async {
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}


