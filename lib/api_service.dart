// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API 服务类，封装所有后端接口调用
class ApiService {
  static String _baseUrl = 'http://192.168.1.100:8080/api'; // 默认值

  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  // 通用 GET 请求
  static Future<dynamic> httpGet(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('HTTP GET 错误: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('HTTP GET 异常: $e');
      return null;
    }
  }

  // 通用 POST 请求，支持自定义 headers
  static Future<dynamic> httpPost(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('HTTP POST 错误: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('HTTP POST 异常: $e');
      return null;
    }
  }

  // ---------- 已有接口 ----------
  static Future<Map<String, dynamic>?> getStatus() async {
    return await httpGet('/status');
  }

  static Future<Map<String, dynamic>?> getFund() async {
    return await httpGet('/fund');
  }

  static Future<List<dynamic>?> getRecentOrders() async {
    return await httpGet('/orders/recent');
  }

  static Future<Map<String, dynamic>?> getPositions() async {
    return await httpGet('/positions');
  }

  static Future<Map<String, dynamic>?> getCosts() async {
    return await httpGet('/costs');
  }

  static Future<List<dynamic>?> getReportsList({String type = 'daily'}) async {
    return await httpGet('/reports/list?type=$type');
  }

  static Future<String?> getReportContent(String filename, {String type = 'daily'}) async {
    final data = await httpGet('/reports/content?type=$type&file=$filename');
    return data?['content'];
  }

  static Future<Map<String, dynamic>?> getKnowledgeStatsById(String knowledgeId) async {
    return await httpGet('/knowledge/stats/$knowledgeId');
  }

  static Future<List<dynamic>?> getKnowledgeRanking({String? type, int days = 30, int limit = 20}) async {
    String url = '/knowledge/ranking?days=$days&limit=$limit';
    if (type != null) url += '&type=$type';
    return await httpGet(url);
  }

  static Future<Map<String, dynamic>?> getDegradePending() async {
    return await httpGet('/degrade/pending');
  }

  static Future<bool> postDegradeResolve(String requestId, String decision, {String reason = ''}) async {
    final result = await httpPost('/degrade/resolve', body: {
      'request_id': requestId,
      'decision': decision,
      'reason': reason,
    });
    return result?['success'] ?? false;
  }

  // 短信认证
  static Future<Map<String, dynamic>?> smsSend(String phone) async {
    return await httpPost('/sms/send', body: {'phone': phone});
  }

  static Future<Map<String, dynamic>?> smsVerify(String code) async {
    return await httpPost('/sms/verify', body: {'code': code});
  }

  static Future<Map<String, dynamic>?> smsLogout() async {
    return await httpPost('/sms/logout');
  }

  // 密码认证
  static Future<Map<String, dynamic>?> authPassword(String password) async {
    return await httpPost('/auth/password', body: {'password': password});
  }

  static Future<Map<String, dynamic>?> authLogout() async {
    return await httpPost('/auth/logout');
  }

  // 模式切换
  static Future<Map<String, dynamic>?> getMode() async {
    return await httpGet('/mode');
  }

  static Future<Map<String, dynamic>?> setMode(String mode) async {
    return await httpPost('/mode', body: {'mode': mode});
  }

  // 日志
  static Future<Map<String, dynamic>?> getRecentLogs({int limit = 100, String level = ''}) async {
    String url = '/logs/recent?limit=$limit';
    if (level.isNotEmpty) url += '&level=$level';
    return await httpGet(url);
  }

  static Future<Map<String, dynamic>?> getAuditLogs({int limit = 50}) async {
    return await httpGet('/logs/audit?limit=$limit');
  }

  // 配置
  static Future<Map<String, dynamic>?> getPublicConfig() async {
    return await httpGet('/config');
  }

  // 健康检查
  static Future<Map<String, dynamic>?> healthCheck() async {
    return await httpGet('/health');
  }

  // 候选股票
  static Future<Map<String, dynamic>?> getCandidates() async {
    return await httpGet('/candidates');
  }

  // ---------- 新增接口 ----------
  static Future<Map<String, dynamic>?> getAIStatus() async {
    return await httpGet('/ai/status');
  }

  static Future<Map<String, dynamic>?> getLearningProgress() async {
    return await httpGet('/learning/progress');
  }

  static Future<List<dynamic>?> getStrategies() async {
    return await httpGet('/strategies');
  }

  static Future<Map<String, dynamic>?> getLatestWarGame() async {
    return await httpGet('/wargame/latest');
  }

  static Future<Map<String, dynamic>?> getKnowledgeStats() async {
    return await httpGet('/knowledge/stats');
  }

  // 修改资金（需认证）
  static Future<Map<String, dynamic>?> modifyFund(double amount, {String reason = ''}) async {
    return await httpPost('/fund', body: {'amount': amount, 'reason': reason});
  }

  // 登录（兼容 auth_page.dart 调用）
  static Future<Map<String, dynamic>?> login(String password) async {
    return await authPassword(password);
  }
}