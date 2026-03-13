// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 默认服务器地址（可在登录页动态修改）
  static String baseUrl = 'http://47.108.206.221:8080';

  // 设置服务器地址（登录页调用）
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  // 密码登录
  static Future<Map<String, dynamic>> login(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('登录失败: ${response.statusCode}');
    }
  }

  // 获取系统状态
  static Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/status'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('获取状态失败: ${response.statusCode}');
    }
  }

  // 紧急停机
  static Future<bool> emergencyStop() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/emergency_stop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    return response.statusCode == 200;
  }

  // 获取最近告警（暂时返回空，后端接口可按需扩展）
  static Future<List<String>> getRecentAlerts() async {
    return [];
  }
}