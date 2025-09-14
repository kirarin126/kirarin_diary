import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

typedef RequestInterceptor = Future<http.BaseRequest> Function(http.BaseRequest request);
typedef ResponseInterceptor = Future<http.Response> Function(http.Response response);

class Request {

  static Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      var request = http.Request('PUT', Uri.parse(_fullUrl(url)));
      final token = await getToken();
      if (headers != null) request.headers.addAll(headers);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is Map) {
          request.body = json.encode(body);
          request.headers['Content-Type'] = 'application/json';
        }
      }
      // 请求拦截
      if (requestInterceptor != null) {
        request = await requestInterceptor!(request) as http.Request;
      }
      final streamed = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamed);
      // 响应拦截
      if (responseInterceptor != null) {
        response = await responseInterceptor!(response);
      }
      return response;
    } on TimeoutException {
      return http.Response('{"error": "请求超时"}', 504);
    } on http.ClientException catch (e) {
      return http.Response('{"error": "网络异常: ${e.message}"}', 500);
    } catch (e) {
      return http.Response('{"error": "未知错误: $e"}', 500);
    }
  }
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (_) {
      return null;
    }
  }

  static const String baseUrl = 'http://192.168.31.101:8000/api';
  static Duration timeout = const Duration(seconds: 10);
  static RequestInterceptor? requestInterceptor;
  static ResponseInterceptor? responseInterceptor;

  static String _fullUrl(String url) {
    if (url.startsWith('http')) return url;
    return baseUrl + url;
  }

  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      var request = http.Request('POST', Uri.parse(_fullUrl(url)));
      final token = await getToken();
      if (headers != null) request.headers.addAll(headers);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is Map) {
          request.body = json.encode(body);
          request.headers['Content-Type'] = 'application/json';
        }
      }
      // 请求拦截
      if (requestInterceptor != null) {
        request = await requestInterceptor!(request) as http.Request;
      }
      final streamed = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamed);
      // 响应拦截
      if (responseInterceptor != null) {
        response = await responseInterceptor!(response);
      }
      return response;
    } on TimeoutException {
      return http.Response('{"error": "请求超时"}', 504);
    } on http.ClientException catch (e) {
      return http.Response('{"error": "网络异常: ${e.message}"}', 500);
    } catch (e) {
      return http.Response('{"error": "未知错误: $e"}', 500);
    }
  }

  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      var request = http.Request('GET', Uri.parse(_fullUrl(url)));
      final token = await getToken();
      if (headers != null) request.headers.addAll(headers);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      // 请求拦截
      if (requestInterceptor != null) {
        request = await requestInterceptor!(request) as http.Request;
      }
      final streamed = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamed);
      // 响应拦截
      if (responseInterceptor != null) {
        response = await responseInterceptor!(response);
      }
      return response;
    } on TimeoutException {
      return http.Response('{"error": "请求超时"}', 504);
    } on http.ClientException catch (e) {
      return http.Response('{"error": "网络异常: ${e.message}"}', 500);
    } catch (e) {
      return http.Response('{"error": "未知错误: $e"}', 500);
    }
  }
}
