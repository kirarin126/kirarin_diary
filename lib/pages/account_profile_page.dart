import 'package:flutter/material.dart';
import '../utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_username_page.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  String? username;
  bool _loading = true;

  Future<void> _loadLocalUsername() async {
    setState(() { _loading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('username');
      if (localName != null && localName.isNotEmpty) {
        setState(() {
          username = localName;
          _loading = false;
        });
      } else {
        // await _fetchProfile();
      }
    } catch (_) {
      // await _fetchProfile();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocalUsername();
  }

  Future<void> _fetchProfile() async {
    setState(() { _loading = true; });
    try {
      // 假设有 /users/profile 接口
      final resp = await ApiService.getProfile();
      if (resp.statusCode == 200) {
        // final data = jsonDecode(resp.body);
        // setState(() { username = data['username']; });
        setState(() { username = resp.body; }); // 演示用
      } else {
        setState(() { username = '获取失败'; });
      }
    } catch (_) {
      setState(() { username = '获取失败'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号资料'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('用户名'),
                        subtitle: Text(username ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChangeUsernamePage()),
                          );
                          _loadLocalUsername();
                        },
                      ),
                      // 可扩展更多资料项
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showResetPasswordDialog(),
                      child: const Text('重置密码'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showResetPasswordDialog() {
    final TextEditingController inviteCodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置密码'),
          content: TextField(
            controller: inviteCodeController,
            decoration: const InputDecoration(
              labelText: '邀请码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = inviteCodeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入邀请码')));
                  return;
                }
                Navigator.pop(context);
                await _resetPassword(code);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword(String inviteCode) async {
    try {
      // 假设有 /users/reset-password 接口
        final resp = await ApiService.resetPassword(username: username ?? '', inviteCode: inviteCode);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('重置密码成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: \\${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('异常: \\${e.toString()}')));
    }
  }
}
