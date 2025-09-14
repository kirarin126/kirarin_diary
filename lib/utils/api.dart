import 'package:http/http.dart' as http;
import 'request.dart';

class ApiService {
  // 用户注册
  static Future<http.Response> register({
    required String username,
    required String password,
    required String inviteCode,
  }) async {
    return await Request.post(
      '/users/register',
      body: {
        'username': username,
        'password': password,
        'invite_code': inviteCode,
      },
    );
  }

  // 用户密码加密
  static Future<http.Response> encryptPassword({
    required String password,
  }) async {
    return await Request.post(
      '/users/encrypt-password',
      body: {'password': password},
    );
  }

  // 用户登录
  static Future<http.Response> login({
    required String username,
    required String password,
  }) async {
    return await Request.post(
      '/users/login',
      body: {'username': username, 'password': password},
    );
  }

  // 更新用户名
  static Future<http.Response> updateUsername({
    required String newUsername,
  }) async {
    return await Request.put(
      '/users/update-username',
      body: {'newUsername': newUsername},
    );
  }

  // 更新密码
  static Future<http.Response> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await Request.put(
      '/users/update-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  // 重置密码
  static Future<http.Response> resetPassword({
    required String adminPassword,
    required String newPassword,
  }) async {
    return await Request.post(
      '/users/reset-password',
      body: {'admin_password': adminPassword, 'new_password': newPassword},
    );
  }
}
