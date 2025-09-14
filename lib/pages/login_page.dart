import 'package:flutter/material.dart';
import '../utils/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户名和密码')),
      );
      return;
    }
 
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. 先加密密码
      final encryptResp = await ApiService.encryptPassword(password: password);
      if (encryptResp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密码加密失败: \\${encryptResp.body}')));
        setState(() { _isLoading = false; });
        return;
      }
      final encrypted = encryptResp.body;
      // 若后端返回json格式 {"password": "xxxx"}，可用如下方式：
      // final encrypted = jsonDecode(encryptResp.body)['password'];

      // 2. 登录
      http.Response response = await ApiService.login(username: username, password: encrypted);
      // 打印响应状态码和内容
      print('Response status: \\${response.statusCode}');

      if (response.statusCode == 200) {
        // 打印响应内容
        print('Response body: \\${response.body}');
       
        // 假设后端返回json: {"access_token": "..."}
        final token = response.body;
        // final token = jsonDecode(response.body)['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: \\${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录异常: \\${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}
