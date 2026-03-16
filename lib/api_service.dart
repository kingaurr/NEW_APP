// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API 服务类，封装所有后端接口调用
class ApiService {
  static String _baseUrl = 'http://47.108.206.221:8080/api'; // 已修改为您的服务器IP

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

  // 主页告警和AI建议
  static Future<List<String>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ['数据源新浪财经连接超时', '内存使用率超过85%'];
  }

  static Future<bool> hasNewAiAdvice() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // AI优化建议中心
  static Future<List<dynamic>> getPendingAdvices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'id': 'adv_001',
        'type': '规则',
        'summary': '提高均线突破策略的置信度阈值',
        'expected_profit': '+2.3%',
        'confidence': 0.85,
        'created_at': '10:23',
      },
      {
        'id': 'adv_002',
        'type': '参数',
        'summary': '降低RSI超卖策略的买入仓位',
        'expected_profit': '+1.1%',
        'confidence': 0.72,
        'created_at': '09:15',
      },
      {
        'id': 'adv_003',
        'type': '策略',
        'summary': '新增“放量突破后回调”策略',
        'expected_profit': '+3.5%',
        'confidence': 0.91,
        'created_at': '昨天',
      },
    ];
  }

  static Future<List<dynamic>> getHistoryAdvices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'id': 'adv_000',
        'type': '规则',
        'summary': '优化止损比例',
        'result': '执行后胜率+1.5%',
        'executed_at': '2025-03-14',
      },
    ];
  }

  static Future<bool> resolveAdvice(String adviceId, String decision) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('处理建议 $adviceId，决策：$decision');
    return true;
  }

  // 知识库各标签页
  static Future<List<dynamic>> getRules() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'id': 'R001', 'desc': 'if ma5 > ma20 then buy', 'winRate': '胜率 68%', 'status': '生效'},
      {'id': 'R002', 'desc': 'if rsi < 30 then buy', 'winRate': '胜率 55%', 'status': '生效'},
      {'id': 'R003', 'desc': 'if volume > volume_ma5*1.5 then buy', 'winRate': '胜率 42%', 'status': '冲突'},
      {'id': 'R004', 'desc': 'if close < boll_lower then buy', 'winRate': '胜率 71%', 'status': '生效'},
    ];
  }

  static Future<List<dynamic>> getCases() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'title': '贵州茅台 (600519)', 'date': '2025-01-15', 'desc': '放量突破前高，后续涨幅30%', 'type': 'good'},
      {'title': '宁德时代 (300750)', 'date': '2025-02-03', 'desc': 'MACD底背离，反弹20%', 'type': 'good'},
      {'title': '东方财富 (300059)', 'date': '2025-02-28', 'desc': '高位放量滞涨，后续跌15%', 'type': 'bad'},
      {'title': '中国平安 (601318)', 'date': '2025-03-01', 'desc': '跌破年线后加速下跌', 'type': 'bad'},
    ];
  }

  static Future<List<dynamic>> getFailures() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'code': '000001', 'date': '2025-03-10', 'reason': '追高被套', 'loss': 1234, 'similar': '当前持仓中 000858 形态与失败案例 000001 相似，建议谨慎'},
      {'code': '600036', 'date': '2025-03-09', 'reason': '卖飞牛股', 'loss': -2345},
      {'code': '601318', 'date': '2025-03-08', 'reason': '震荡市追涨', 'loss': 567},
    ];
  }

  static Future<Map<String, dynamic>> getConfig() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'experts': [
        {'name': '张三', 'detail': '趋势交易', 'status': '已启用'},
        {'name': '李四', 'detail': '量化模型', 'status': '已启用'},
        {'name': '王五', 'detail': '宏观分析', 'status': '未启用'},
      ],
      'books': [
        {'name': '海龟交易法则', 'detail': '规则数: 12', 'status': '已导入'},
        {'name': '股票大作手', 'detail': '规则数: 8', 'status': '已导入'},
      ],
      'keywords': [
        {'name': '震荡市', 'detail': '低吸 +5%, 追高 -3%', 'weight': 0.8},
        {'name': '牛市', 'detail': '追涨 +8%', 'weight': 1.2},
      ],
    };
  }

  // ---------- 新增：一键平仓 ----------
  static Future<bool> liquidateAll() async {
    // 模拟一键平仓
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('一键平仓指令已发送（模拟）');
    return true;
  }
}