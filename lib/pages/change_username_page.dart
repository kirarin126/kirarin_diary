import 'package:flutter/material.dart';
import '../utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final TextEditingController usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final newUsername = usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入新用户名')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final resp = await ApiService.updateUsername(newUsername: newUsername);
      print('Response status: \\${resp.statusCode}');
      print('Response body: \\${resp.body}');
      if (resp.statusCode == 200) {
 
      //  更新本地存储的用户名
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newUsername);
        if (!mounted) return;
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: \\${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('异常: \\${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改用户名'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '新用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('提交'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
