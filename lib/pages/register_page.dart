import 'package:flutter/material.dart';
import '../utils/api.dart';
import 'dart:convert';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _register() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmController.text;
    final inviteCode = inviteCodeController.text.trim();
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty || inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写所有字段')));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
    

      // 若后端返回json格式 {"password": "xxxx"}，可用如下方式：
      // final encrypted = jsonDecode(encryptResp.body)['password'];

      // 2. 注册
      final regResp = await ApiService.register(
        username: username,
        password: password,
        inviteCode: inviteCode,
      );
      
      final body = regResp.body;
      final Map<String, dynamic> jsonMap = json.decode(body);
      
      if (jsonMap['code'] == 200) {
        // 注册成功
        final message = jsonMap['message'] ?? '注册成功';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pop(context);
      } else {
        // 注册失败
        final error = jsonMap['error'] ?? '未知错误';
        final message = jsonMap['message'] ?? '注册失败';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('异常: \\${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: inviteCodeController,
              decoration: const InputDecoration(
                labelText: '邀请码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: '确认密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('注册'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('已有账号？去登录'),
            ),
          ],
        ),
      ),
    );
  }
}
