// lib/main.dart

import 'package:flutter/material.dart';
import 'package:first/pages/home_page.dart'; // ✅ 引入 home_page.dart
import 'package:intl/date_symbol_data_local.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}


