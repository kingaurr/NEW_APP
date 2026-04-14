// lib/api_service.dart
// ==================== 宫崎骏模块 API 方法追加（2026-04-14） ====================
// 修改内容：
// 1. 新增 fetchMiyazakiDashboard() - 获取稽查中心首页数据
// 2. 新增 fetchMiyazakiEvents() - 获取异常事件列表
// 3. 新增 fetchMiyazakiEventGroups() - 获取事件组列表
// 4. 新增 fetchMiyazakiDiagnosis() - 获取诊断报告
// 5. 新增 fetchMiyazakiDiagnosisById() - 根据ID获取诊断详情
// 6. 新增 triggerMiyazakiDiagnosis() - 手动触发全面诊断
// 7. 新增 fetchMiyazakiLineage() - 获取谱系追踪记录
// 8. 新增 fetchMiyazakiLineageById() - 获取谱系记录详情
// 9. 新增 fetchMiyazakiStatistics() - 获取宫崎骏统计信息
// 所有方法均调用后端真实接口，无硬编码假数据。
// =====================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API 服务类，封装所有后端接口调用
class ApiService {
  // 使用同一个 Client 实例（用于自动管理 cookie，但 token 认证不依赖它）
  static final http.Client _client = http.Client();

  static String _baseUrl = 'http://47.108.206.221:8080/api';

  static void setBaseUrl(String url) {
    // 自动补全 /api 后缀（如果没有）
    if (!url.endsWith('/api')) {
      if (url.endsWith('/')) {
        url = '${url}api';
      } else {
        url = '$url/api';
      }
    }
    _baseUrl = url;
  }

  // ---------- Token 管理 ----------
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ===== 新增：指纹 token 管理（延迟导入避免循环依赖） =====
  static String? _fingerprintToken;
  static int _fingerprintTokenExpiry = 0;

  static void setFingerprintToken(String token, int expiresInSeconds) {
    _fingerprintToken = token;
    _fingerprintTokenExpiry = DateTime.now().millisecondsSinceEpoch + expiresInSeconds * 1000;
  }

  static String? getFingerprintToken() {
    if (_fingerprintToken != null && DateTime.now().millisecondsSinceEpoch < _fingerprintTokenExpiry) {
      return _fingerprintToken;
    }
    return null;
  }

  static void clearFingerprintToken() {
    _fingerprintToken = null;
    _fingerprintTokenExpiry = 0;
  }
  // ================================================

  // ---------- 通用请求方法（自动携带 token 和指纹 token，统一错误处理） ----------
  static Future<dynamic> httpGet(String endpoint) async {
    final url = '$_baseUrl$endpoint';
    debugPrint('GET请求: $url');
    try {
      final token = await _getToken();
      final fingerprintToken = getFingerprintToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (fingerprintToken != null) {
        headers['X-Fingerprint-Token'] = fingerprintToken;
      }
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 统一错误返回格式
        debugPrint('HTTP GET 错误: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'HTTP ${response.statusCode}', 'statusCode': response.statusCode};
      }
    } catch (e) {
      debugPrint('HTTP GET 异常: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<dynamic> httpPost(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final url = '$_baseUrl$endpoint';
    debugPrint('POST请求: $url');
    try {
      final token = await _getToken();
      final fingerprintToken = getFingerprintToken();
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
      if (fingerprintToken != null) {
        requestHeaders['X-Fingerprint-Token'] = fingerprintToken;
      }
      final response = await _client.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('HTTP POST 错误: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'HTTP ${response.statusCode}', 'statusCode': response.statusCode};
      }
    } catch (e) {
      debugPrint('HTTP POST 异常: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========== 系统状态 ==========
  static Future<Map<String, dynamic>?> getStatus() async {
    return await httpGet('/status');
  }

  // ========== 资金管理 ==========
  static Future<Map<String, dynamic>?> getFund() async {
    return await httpGet('/fund');
  }

  static Future<Map<String, dynamic>?> modifyFund(double amount,
      {String reason = ''}) async {
    return await httpPost('/fund', body: {'amount': amount, 'reason': reason});
  }

  // ========== 订单管理 ==========
  static Future<List<dynamic>?> getRecentOrders() async {
    return await httpGet('/orders/recent');
  }

  static Future<bool> cancelOrder(String orderId) async {
    final result =
        await httpPost('/orders/cancel', body: {'order_id': orderId});
    return result?['success'] ?? false;
  }

  // ========== 持仓管理 ==========
  static Future<Map<String, dynamic>?> getPositions() async {
    return await httpGet('/positions');
  }

  static Future<bool> updatePositionStopLoss(String code, double stopLoss) async {
    final result = await httpPost('/positions/stop_loss',
        body: {'code': code, 'stop_loss': stopLoss});
    return result?['success'] ?? false;
  }

  static Future<bool> updatePositionTakeProfit(
      String code, double takeProfit) async {
    final result = await httpPost('/positions/take_profit',
        body: {'code': code, 'take_profit': takeProfit});
    return result?['success'] ?? false;
  }

  static Future<bool> sellPosition(String code, {int? shares}) async {
    final result = await httpPost('/positions/sell', body: {
      'code': code,
      'shares': shares?.toString() ?? 'all',
    });
    return result?['success'] ?? false;
  }

  // ========== 成本统计 ==========
  static Future<Map<String, dynamic>?> getCosts() async {
    return await httpGet('/costs');
  }

  static Future<Map<String, dynamic>?> getCostStatus() async {
    return await httpGet('/cost/status');
  }

  // ========== AI状态 ==========
  static Future<Map<String, dynamic>?> getAIStatus() async {
    return await httpGet('/ai/status');
  }

  static Future<Map<String, dynamic>?> getRightBrainStatus() async {
    return await httpGet('/right_brain/status');
  }

  // 右脑信号列表（后端未实现，返回空列表避免404）
  static Future<List<dynamic>?> getRightBrainSignals() async {
    return [];
  }

  static Future<Map<String, dynamic>?> getLeftBrainStatus() async {
    return await httpGet('/left_brain/status');
  }

  // 左脑决策列表（后端未实现，返回空列表）
  static Future<List<dynamic>?> getLeftBrainDecisions() async {
    return [];
  }

  // ========== 策略管理 ==========
  static Future<List<dynamic>?> getStrategies() async {
    return await httpGet('/strategies');
  }

  static Future<Map<String, dynamic>?> getStrategyDetail(
      String strategyId) async {
    return await httpGet('/strategies/detail?id=$strategyId');
  }

  static Future<Map<String, dynamic>?> getStrategyDecisionTree(
      String strategyId) async {
    return await httpGet('/strategies/decision_tree?id=$strategyId');
  }

  static Future<Map<String, dynamic>?> getStrategyComparison(
      String strategyId) async {
    return await httpGet('/strategies/comparison?id=$strategyId');
  }

  // ========== 规则管理 ==========
  static Future<Map<String, dynamic>?> getRuleDetail(String ruleId) async {
    return await httpGet('/rules/detail?id=$ruleId');
  }

  static Future<List<dynamic>?> getAllRules() async {
    return await httpGet('/rules');
  }

  static Future<Map<String, dynamic>?> getRuleById(String ruleId) async {
    return await httpGet('/rules/$ruleId');
  }

  static Future<bool> disableRule(String ruleId, {String reason = ''}) async {
    final result = await httpPost('/rules/disable',
        body: {'rule_id': ruleId, 'reason': reason});
    return result?['success'] ?? false;
  }

  // 策略库规则（兼容旧接口，实际调用 /rules）
  static Future<List<dynamic>?> getStrategyLibraryRules() async {
    return await httpGet('/rules');
  }

  // ========== 外脑管理 ==========
  static Future<List<dynamic>?> getPendingRules() async {
    return await httpGet('/outer_brain/pending_rules');
  }

  static Future<bool> approveRule(String ruleId) async {
    final result = await httpPost('/outer_brain/approve_rule',
        body: {'rule_id': ruleId});
    return result?['success'] ?? false;
  }

  static Future<bool> rejectRule(String ruleId) async {
    final result = await httpPost('/outer_brain/reject_rule',
        body: {'rule_id': ruleId});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getEvolutionReport() async {
    return await httpGet('/outer_brain/evolution_report');
  }

  static Future<Map<String, dynamic>?> getOuterBrainStatus() async {
    return await httpGet('/outer_brain/status');
  }

  // ========== 建议管理 ==========
  static Future<List<dynamic>?> getPendingSuggestions() async {
    return await httpGet('/advice/pending');
  }

  // 守门员建议（兼容旧接口，实际调用 /advice/pending）
  static Future<List<dynamic>?> getGuardianSuggestions() async {
    return await httpGet('/advice/pending');
  }

  static Future<int> getPendingAdviceCount() async {
    final result = await httpGet('/advice/pending_count');
    return result?['count'] ?? 0;
  }

  static Future<bool> approveAdvice(String adviceId) async {
    final result =
        await httpPost('/advice/approve', body: {'advice_id': adviceId});
    return result?['success'] ?? false;
  }

  static Future<bool> approveAllAdvice() async {
    final result = await httpPost('/advice/approve_all');
    return result?['success'] ?? false;
  }

  static Future<bool> rejectAdvice(String adviceId, {String reason = ''}) async {
    final result = await httpPost('/advice/reject',
        body: {'advice_id': adviceId, 'reason': reason});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getAdviceDetail(String adviceId) async {
    return await httpGet('/advice/$adviceId');
  }

  static Future<List<dynamic>?> getHistoryAdvices({int limit = 50}) async {
    final result = await httpGet('/advice/history?limit=$limit');
    return result?['advices'] ?? [];
  }

  // 守门员历史建议（兼容 getHistorySuggestions 调用）
  static Future<List<dynamic>?> getHistorySuggestions({int limit = 50}) async {
    return getHistoryAdvices(limit: limit);
  }

  // 别名方法（待审核规则操作）
  static Future<bool> awaitPendingRule(String ruleId) async {
    return approveRule(ruleId);
  }

  static Future<bool> rejectPendingRule(String ruleId) async {
    return rejectRule(ruleId);
  }

  // 别名方法（守门员建议操作）
  static Future<bool> acceptSuggestion(String suggestionId) async {
    return approveAdvice(suggestionId);
  }

  // ========== 红蓝军 ==========
  static Future<Map<String, dynamic>?> getLatestWarGame() async {
    return await httpGet('/wargame/latest');
  }

  static Future<Map<String, dynamic>?> getLatestLightWarGame() async {
    return await httpGet('/war_game/light/latest');
  }

  static Future<Map<String, dynamic>?> getLatestDeepWarGame() async {
    return await httpGet('/war_game/deep/latest');
  }

  static Future<bool> applyWarGameSuggestion(String reportId) async {
    final result = await httpPost('/war_game/apply',
        body: {'report_id': reportId});
    return result?['success'] ?? false;
  }

  static Future<List<dynamic>?> getLightWarGameHistory() async {
    return await httpGet('/war_game/light/history');
  }

  static Future<List<dynamic>?> getDeepWarGameHistory() async {
    return await httpGet('/war_game/deep/history');
  }

  // ========== 影子账户 ==========
  static Future<Map<String, dynamic>?> getShadowStatus() async {
    return await httpGet('/shadow/status');
  }

  static Future<bool> applyShadowSuggestion() async {
    final result = await httpPost('/shadow/apply');
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getShadowRealtimeCompare() async {
    return await httpGet('/shadow/realtime_compare');
  }

  // ========== 熔断 ==========
  static Future<Map<String, dynamic>?> getFuseStatus() async {
    return await httpGet('/fuse/status');
  }

  // ========== 数据源健康 ==========
  static Future<Map<String, dynamic>?> getDataSourceHealth() async {
    return await httpGet('/data_source/health');
  }

  // ========== 选股池 ==========
  static Future<Map<String, dynamic>?> getTradePool() async {
    return await httpGet('/trade/pool');
  }

  // ========== 信号历史 ==========
  static Future<Map<String, dynamic>?> getSignalHistory({int limit = 50}) async {
    String url = '/signals/history';
    if (limit != 50) url += '?limit=$limit';
    return await httpGet(url);
  }

  // ========== 报告 ==========
  static Future<List<dynamic>?> getReportsList({String type = 'daily'}) async {
    return await httpGet('/reports/list?type=$type');
  }

  static Future<String?> getReportContent(String filename,
      {String type = 'daily'}) async {
    final data = await httpGet('/reports/content?type=$type&file=$filename');
    return data?['content'];
  }

  static Future<Map<String, dynamic>?> getLatestReport() async {
    return await httpGet('/reports/latest');
  }

  static Future<Map<String, dynamic>?> getLatestReportSummary() async {
    return await httpGet('/reports/latest_summary');
  }

  static Future<bool> markReportRead(String filename, String reportType) async {
    final result = await httpPost('/reports/mark_read',
        body: {'filename': filename, 'type': reportType});
    return result?['success'] ?? false;
  }

  // ========== 知识库 ==========
  static Future<Map<String, dynamic>?> getKnowledgeStats() async {
    return await httpGet('/knowledge/stats');
  }

  static Future<Map<String, dynamic>?> getKnowledgeStatsById(
      String knowledgeId) async {
    return await httpGet('/knowledge/stats/$knowledgeId');
  }

  static Future<List<dynamic>?> getKnowledgeRanking(
      {String? type, int days = 30, int limit = 20}) async {
    String url = '/knowledge/ranking?days=$days&limit=$limit';
    if (type != null) url += '&type=$type';
    return await httpGet(url);
  }

  static Future<List<dynamic>?> getCases() async {
    return await httpGet('/knowledge/cases');
  }

  static Future<Map<String, dynamic>?> getCaseDetail(String caseId) async {
    return await httpGet('/knowledge/cases/$caseId');
  }

  static Future<bool> addCase(Map<String, dynamic> caseData) async {
    final result = await httpPost('/knowledge/cases', body: caseData);
    return result?['success'] ?? false;
  }

  static Future<List<dynamic>?> getFailures() async {
    return await httpGet('/knowledge/failures');
  }

  static Future<Map<String, dynamic>?> getFailureDetail(String failureId) async {
    return await httpGet('/knowledge/failures/$failureId');
  }

  // ========== 系统监控 ==========
  static Future<Map<String, dynamic>?> getSystemMonitor() async {
    return await httpGet('/system/monitor');
  }

  static Future<Map<String, dynamic>?> getHeartSummary() async {
    return await httpGet('/heart/summary');
  }

  // ========== 版本管理 ==========
  static Future<Map<String, dynamic>?> getSystemVersion() async {
    return await httpGet('/system/version');
  }

  static Future<List<dynamic>?> getVersions() async {
    return await httpGet('/versions');
  }

  static Future<Map<String, dynamic>?> getVersionDetail(String versionId) async {
    return await httpGet('/version/$versionId');
  }

  static Future<bool> rollbackVersion(String versionId) async {
    final result =
        await httpPost('/version/rollback', body: {'version_id': versionId});
    return result?['success'] ?? false;
  }

  // ========== 备份管理 ==========
  static Future<List<dynamic>?> getBackups() async {
    final result = await httpGet('/backup/list');
    return result?['backups'] ?? [];
  }

  static Future<Map<String, dynamic>?> createBackup() async {
    return await httpPost('/backup/create');
  }

  static Future<bool> restoreBackup(String backupId) async {
    final result = await httpPost('/backup/restore',
        body: {'backup_id': backupId});
    return result?['success'] ?? false;
  }

  // ========== 告警 ==========
  static Future<Map<String, dynamic>?> getAlerts() async {
    return await httpGet('/alerts');
  }

  static Future<int> getUnreadAlertCount() async {
    final result = await httpGet('/alerts/unread_count');
    return result?['count'] ?? 0;
  }

  static Future<bool> acknowledgeAlert(String alertId) async {
    final result = await httpPost('/alerts/acknowledge', body: {'id': alertId});
    return result?['success'] ?? false;
  }

  static Future<bool> ignoreAlert(String alertId) async {
    final result = await httpPost('/alerts/ignore', body: {'id': alertId});
    return result?['success'] ?? false;
  }

  // ========== 日志 ==========
  static Future<Map<String, dynamic>?> getRecentLogs(
      {int limit = 100, String level = ''}) async {
    String url = '/logs/recent?limit=$limit';
    if (level.isNotEmpty) url += '&level=$level';
    return await httpGet(url);
  }

  // 修正审计日志解析（后端返回 {"logs": [...]}）
  static Future<List<dynamic>?> getAuditLogs({int limit = 50}) async {
    final result = await httpGet('/logs/audit?limit=$limit');
    if (result != null && result is Map && result['logs'] is List) {
      return result['logs'] as List;
    }
    return null;
  }

  // ========== 模式切换 ==========
  static Future<Map<String, dynamic>?> getMode() async {
    return await httpGet('/mode');
  }

  static Future<Map<String, dynamic>?> setMode(String mode) async {
    return await httpPost('/mode', body: {'mode': mode});
  }

  // ========== 配置 ==========
  static Future<Map<String, dynamic>?> getPublicConfig() async {
    return await httpGet('/config');
  }

  static Future<Map<String, dynamic>?> getSystemConfig() async {
    return await httpGet('/system/config');
  }

  // ========== 健康检查 ==========
  static Future<Map<String, dynamic>?> healthCheck() async {
    return await httpGet('/health');
  }

  static Future<Map<String, dynamic>?> healthDetailed() async {
    return await httpGet('/health/detailed');
  }

  // ========== 认证 ==========
  static Future<Map<String, dynamic>?> authPassword(String password) async {
    final result = await httpPost('/auth/password', body: {'password': password});
    if (result != null && result['success'] == true && result['token'] != null) {
      await _saveToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>?> authLogout() async {
    final result = await httpPost('/auth/logout');
    await clearToken();
    return result;
  }

  static Future<Map<String, dynamic>?> verifyToken() async {
    return await httpGet('/auth/verify');
  }

  // ========== 短信验证 ==========
  static Future<Map<String, dynamic>?> smsSend(String phone) async {
    return await httpPost('/sms/send', body: {'phone': phone});
  }

  static Future<Map<String, dynamic>?> smsVerify(String code) async {
    final result = await httpPost('/sms/verify', body: {'code': code});
    if (result != null && result['success'] == true && result['token'] != null) {
      await _saveToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>?> smsLogout() async {
    return await httpPost('/sms/logout');
  }

  // ========== 降级管理 ==========
  static Future<Map<String, dynamic>?> getDegradePending() async {
    return await httpGet('/degrade/pending');
  }

  static Future<bool> postDegradeResolve(String requestId, String decision,
      {String reason = ''}) async {
    final result = await httpPost('/degrade/resolve', body: {
      'request_id': requestId,
      'decision': decision,
      'reason': reason,
    });
    return result?['success'] ?? false;
  }

  // ========== 学习进度 ==========
  static Future<Map<String, dynamic>?> getLearningProgress() async {
    return await httpGet('/learning/progress');
  }

  // ========== 一键清仓 ==========
  static Future<bool> clearAllPositions() async {
    final result = await httpPost('/real/clear_position');
    return result?['success'] ?? false;
  }

  // ========== 压力测试 ==========
  static Future<Map<String, dynamic>?> getStressTestLatest() async {
    return await httpGet('/stress_test/latest');
  }

  // ========== 券商管理 ==========
  static Future<Map<String, dynamic>?> getBrokerStatus() async {
    return await httpGet('/broker/status');
  }

  static Future<bool> testBrokerConnection() async {
    final result = await httpPost('/broker/test');
    return result?['success'] ?? false;
  }

  // ========== 实战目标 ==========
  static Future<Map<String, dynamic>?> getCombatTarget() async {
    return await httpGet('/combat/target');
  }

  static Future<bool> updateCombatTarget(Map<String, dynamic> target) async {
    final result = await httpPost('/combat/target', body: target);
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getCombatProgress() async {
    return await httpGet('/combat/progress');
  }

  // ========== 预算配置 ==========
  static Future<Map<String, dynamic>?> getBudgetConfig() async {
    return await httpGet('/settings/budget');
  }

  static Future<bool> updateBudgetConfig(Map<String, dynamic> config) async {
    final result = await httpPost('/settings/budget', body: config);
    return result?['success'] ?? false;
  }

  // ========== 风控基准 ==========
  static Future<Map<String, dynamic>?> getRiskBaseFund() async {
    return await httpGet('/settings/risk_base_fund');
  }

  static Future<bool> updateRiskBaseFund(double amount) async {
    final result = await httpPost('/settings/risk_base_fund',
        body: {'risk_base_fund': amount});
    return result?['success'] ?? false;
  }

  // ========== 语音增强 ==========
  static Future<Map<String, dynamic>?> getVoiceDashboard() async {
    return await httpGet('/voice/dashboard');
  }

  static Future<Map<String, dynamic>?> rootCauseAnalysis(String question) async {
    return await httpPost('/voice/root_cause', body: {'question': question});
  }

  static Future<List<dynamic>?> getVoiceSuggestions() async {
    final result = await httpGet('/voice/suggestion');
    return result?['suggestions'] ?? [];
  }

  static Future<Map<String, dynamic>?> getVoiceSettings() async {
    return await httpGet('/voice/settings');
  }

  static Future<bool> updateVoiceSettings(Map<String, dynamic> settings) async {
    final result = await httpPost('/voice/settings', body: settings);
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getAlertSettings() async {
    return await httpGet('/voice/alert/settings');
  }

  static Future<bool> updateAlertSettings(Map<String, dynamic> settings) async {
    final result = await httpPost('/voice/alert/settings', body: settings);
    return result?['success'] ?? false;
  }

  static Future<bool> testAlert(String message) async {
    final result = await httpPost('/voice/alert/test', body: {'message': message});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getCommandHistory({int limit = 50}) async {
    return await httpGet('/voice/history?limit=$limit');
  }

  static Future<Map<String, dynamic>?> voiceExtractFeatures(
      List<int> audioBytes) async {
    return await httpPost('/voice/extract_features', body: {'audio': audioBytes});
  }

  static Future<Map<String, dynamic>?> getEvidence(String transactionId) async {
    return await httpGet('/voice/evidence/$transactionId');
  }

  static Future<Map<String, dynamic>?> verifyCommand(String command) async {
    return await httpGet('/voice/verify/$command');
  }

  static Future<Map<String, dynamic>> voiceAsk(String text,
      {String mode = 'auto'}) async {
    return await httpPost('/voice/ask', body: {'text': text, 'mode': mode});
  }

  // ========== 实战经验 ==========
  static Future<List<dynamic>?> getExperienceLogs({int limit = 20}) async {
    final result = await httpGet('/voice/experience?limit=$limit');
    return result?['logs'] ?? [];
  }

  static Future<bool> addExperienceLog(Map<String, dynamic> log) async {
    final result = await httpPost('/voice/experience/add', body: log);
    return result?['success'] ?? false;
  }

  // ========== 声纹验证 ==========
  static Future<Map<String, dynamic>?> voiceRegister(
      String userId, String userName, List<double> features) async {
    return await httpPost('/voice/register', body: {
      'user_id': userId,
      'user_name': userName,
      'features': features,
    });
  }

  static Future<Map<String, dynamic>?> voiceVerify(
      String userId, List<double> features) async {
    return await httpPost('/voice/verify', body: {
      'user_id': userId,
      'features': features,
    });
  }

  static Future<Map<String, dynamic>?> voiceIdentify(List<double> features) async {
    return await httpPost('/voice/identify', body: {'features': features});
  }

  static Future<Map<String, dynamic>?> voiceGetUsers() async {
    return await httpGet('/voice/users');
  }

  static Future<Map<String, dynamic>?> voiceDelete(String userId) async {
    return await httpPost('/voice/delete', body: {'user_id': userId});
  }

  // ========== 指纹验证 ==========
  static Future<Map<String, dynamic>?> fingerprintRegister() async {
    return await httpPost('/fingerprint/register');
  }

  static Future<Map<String, dynamic>?> fingerprintVerify(String operation) async {
    return await httpPost('/fingerprint/verify', body: {'operation': operation});
  }

  static Future<Map<String, dynamic>?> fingerprintInfo() async {
    return await httpGet('/fingerprint/info');
  }

  static Future<Map<String, dynamic>?> fingerprintDelete() async {
    return await httpPost('/fingerprint/delete');
  }

  // ========== 权限管理 ==========
  static Future<Map<String, dynamic>?> permissionCheck(
      String userId, String operation) async {
    return await httpPost('/permission/check', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  static Future<Map<String, dynamic>?> permissionAuthorize(
      String userId, String operation, List<String> authMethods) async {
    return await httpPost('/permission/authorize', body: {
      'user_id': userId,
      'operation': operation,
      'auth_methods': authMethods,
    });
  }

  static Future<Map<String, dynamic>?> permissionUsers() async {
    return await httpGet('/permission/users');
  }

  static Future<Map<String, dynamic>?> permissionUpdate(
      String userId, String level) async {
    return await httpPost('/permission/update', body: {
      'user_id': userId,
      'level': level,
    });
  }

  // ========== 指令守卫 ==========
  static Future<Map<String, dynamic>?> commandExecute(String command,
      String userId,
      {String? bypassToken, bool skipAuth = false}) async {
    return await httpPost('/command/execute', body: {
      'command': command,
      'user_id': userId,
      'bypass_token': bypassToken,
      'skip_auth': skipAuth,
    });
  }

  static Future<Map<String, dynamic>?> commandParse(String command) async {
    return await httpPost('/command/parse', body: {'command': command});
  }

  // ========== 频率限制 ==========
  static Future<Map<String, dynamic>?> rateLimitCheck(
      String userId, String operation) async {
    return await httpPost('/rate_limit/check', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  static Future<Map<String, dynamic>?> rateLimitStatus(
      String userId, String operation) async {
    return await httpPost('/rate_limit/status', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  // ========== IP白名单 ==========
  static Future<Map<String, dynamic>?> ipWhitelistCheck(String ip) async {
    return await httpPost('/ip_whitelist/check', body: {'ip': ip});
  }

  static Future<Map<String, dynamic>?> ipWhitelistAdd(String pattern,
      {String? reason}) async {
    return await httpPost('/ip_whitelist/add', body: {
      'pattern': pattern,
      'reason': reason,
    });
  }

  static Future<Map<String, dynamic>?> ipWhitelistRemove(String pattern) async {
    return await httpPost('/ip_whitelist/remove', body: {'pattern': pattern});
  }

  static Future<Map<String, dynamic>?> ipWhitelistList() async {
    return await httpGet('/ip_whitelist/list');
  }

  static Future<bool> ipWhitelistSetMode(String mode) async {
    final result = await httpPost('/ip_whitelist/mode', body: {'mode': mode});
    return result?['success'] ?? false;
  }

  static Future<bool> ipWhitelistSetStrictMode(bool strict) async {
    final result = await httpPost('/ip_whitelist/strict_mode',
        body: {'strict_mode': strict});
    return result?['success'] ?? false;
  }

  static Future<bool> ipWhitelistSetEnabled(bool enabled) async {
    final result = await httpPost('/ip_whitelist/enabled',
        body: {'enabled': enabled});
    return result?['success'] ?? false;
  }

  // ========== 紧急停止 ==========
  static Future<Map<String, dynamic>?> emergencyStop(String reason) async {
    return await httpPost('/emergency/stop', body: {'reason': reason});
  }

  static Future<Map<String, dynamic>?> emergencyRecover(
      {String? reason}) async {
    return await httpPost('/emergency/recover', body: {'reason': reason});
  }

  static Future<Map<String, dynamic>?> emergencyPause(
      String reason, int duration) async {
    return await httpPost('/emergency/pause', body: {
      'reason': reason,
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>?> emergencyStatus() async {
    return await httpGet('/emergency/status');
  }

  // ========== 审计日志 ==========
  // 已在上方定义 getAuditLogs，此处不再重复

  static Future<Map<String, dynamic>?> auditStatistics({int days = 7}) async {
    return await httpGet('/audit/statistics?days=$days');
  }

  // ========== 安全中心 ==========
  static Future<Map<String, dynamic>?> securityStatus() async {
    return await httpGet('/security/status');
  }

  static Future<Map<String, dynamic>?> securityReport({int days = 7}) async {
    return await httpGet('/security/report?days=$days');
  }

  static Future<Map<String, dynamic>?> securityLevelSet(String level) async {
    return await httpPost('/security/level', body: {'level': level});
  }

  static Future<Map<String, dynamic>?> securityHealthCheck() async {
    return await httpGet('/security/health');
  }

  static Future<Map<String, dynamic>?> securityBypassToken(
      {int duration = 300, String? ip}) async {
    return await httpPost('/security/bypass_token', body: {
      'duration': duration,
      'ip': ip,
    });
  }

  // ========== 系统统计 ==========
  static Future<Map<String, dynamic>?> getSystemStats() async {
    return await httpGet('/system/stats');
  }

  // ========== 系统重启 ==========
  static Future<bool> systemRestart() async {
    final result = await httpPost('/system/restart');
    return result?['success'] ?? false;
  }

  // ========== 股票详情 ==========
  static Future<Map<String, dynamic>?> getStockDetail(String code) async {
    return await httpGet('/stock/detail?code=$code');
  }

  // ========== 首页聚合 ==========
  static Future<Map<String, dynamic>?> getDashboard() async {
    return await httpGet('/dashboard');
  }

  static Future<Map<String, dynamic>?> getMarketStatus() async {
    return await httpGet('/market/status');
  }

  static Future<Map<String, dynamic>?> getRiskStatus() async {
    return await httpGet('/risk/status');
  }

  // ========== 登录兼容 ==========
  static Future<Map<String, dynamic>?> login(String password) async {
    return await authPassword(password);
  }

  // ========== 补充缺失方法（供组件调用） ==========
  static Future<bool> executeCommand(String command, String userId) async {
    final result = await commandExecute(command, userId);
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getStressTestReport() async {
    return await getStressTestLatest();
  }

  static Future<bool> buyStock(String code, int shares, double price) async {
    final result = await httpPost('/positions/buy',
        body: {'code': code, 'shares': shares, 'price': price});
    return result?['success'] ?? false;
  }

  static Future<bool> executeSignal(String signalId) async {
    final result = await httpPost('/signals/execute',
        body: {'signal_id': signalId});
    return result?['success'] ?? false;
  }

  static Future<bool> updateStrategyStatus(
      String strategyId, bool enable) async {
    final result = await httpPost('/strategies/update_status',
        body: {'strategy_id': strategyId, 'enabled': enable});
    return result?['success'] ?? false;
  }

  static Future<bool> updateCombatPriority(String priority) async {
    final result = await httpPost('/combat/priority', body: {'priority': priority});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getRiskSettings() async {
    final fuse = await getFuseStatus();
    final params = await getPublicConfig();
    final base = await getRiskBaseFund();
    final fund = await getFund();
    return {
      'stop_loss_ratio': params?['risk']?['stop_loss_ratio'] ?? 0.03,
      'take_profit_ratio': params?['risk']?['take_profit_ratio'] ?? 0.05,
      'max_position_ratio': params?['trading']?['max_position_ratio'] ?? 0.2,
      'risk_base_fund': base?['risk_base_fund'] ?? 200000.0,
      'current_fund': fund?['current_fund'] ?? 0.0,
      'alert_level': fuse?['alert_level'] ?? 'none',
      'fuse_status': fuse?['triggered'] ?? false,
    };
  }

  static Future<bool> updateStopLossRatio(double ratio) async {
    final result = await httpPost('/settings/risk_params',
        body: {'stop_loss_ratio': ratio});
    return result?['success'] ?? false;
  }

  static Future<bool> updateTakeProfitRatio(double ratio) async {
    final result = await httpPost('/settings/risk_params',
        body: {'take_profit_ratio': ratio});
    return result?['success'] ?? false;
  }

  static Future<bool> updateMaxPositionRatio(double ratio) async {
    final result = await httpPost('/settings/risk_params',
        body: {'max_position_ratio': ratio});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> updateStrategyWeight(
      String strategyId, double weight) async {
    return await httpPost('/strategies/update_weight', body: {
      'strategy_id': strategyId,
      'weight': weight,
    });
  }

  static Future<Map<String, dynamic>?> killStrategy(String strategyId) async {
    return await httpPost('/strategies/kill', body: {
      'strategy_id': strategyId,
    });
  }

  static Future<bool> updateRiskParams(
      double stopLossRatio, double takeProfitRatio, double maxPositionRatio) async {
    final result = await httpPost('/settings/risk_params', body: {
      'stop_loss_ratio': stopLossRatio,
      'take_profit_ratio': takeProfitRatio,
      'max_position_ratio': maxPositionRatio,
    });
    return result?['success'] ?? false;
  }

  static Future<bool> updateStopLoss(String code, double stopLoss) async {
    return updatePositionStopLoss(code, stopLoss);
  }

  static Future<bool> updateTakeProfit(String code, double takeProfit) async {
    return updatePositionTakeProfit(code, takeProfit);
  }

  static Future<bool> sellPositionSimple(String code) async {
    return sellPosition(code);
  }

  static List<dynamic> extractList(dynamic result, {String key = 'items'}) {
    if (result == null) return [];
    if (result is List) return result;
    if (result is Map && result.containsKey(key) && result[key] is List) {
      return result[key] as List;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> approveSuggestion(
      String suggestionId) async {
    final result = await httpPost('/guardian/approve',
        body: {'suggestion_id': suggestionId});
    return result;
  }

  static Future<Map<String, dynamic>?> rejectSuggestion(
      String suggestionId) async {
    final result = await httpPost('/guardian/reject',
        body: {'suggestion_id': suggestionId});
    return result;
  }

  // ========== 实盘页面兼容方法（解决 /api/real/* 404） ==========
  /// 获取实盘持仓（实际调用 /positions）
  static Future<Map<String, dynamic>?> getRealPositions() => getPositions();

  /// 获取实盘交易池（实际调用 /trade/pool）
  static Future<Map<String, dynamic>?> getRealTradePool() => getTradePool();

  /// 获取实盘信号记录（实际调用 /signals/history）
  static Future<Map<String, dynamic>?> getRealSignals() => getSignalHistory();

  /// 获取实盘资金（实际调用 /fund）
  static Future<Map<String, dynamic>?> getRealFund() => getFund();

  // ========== 新增接口（外脑中心、日志、仲裁、系统升级、IPO等） ==========
  // 外脑中心
  static Future<Map<String, dynamic>?> getOuterBrainStatusV2() async {
    return await httpGet('/outer_brain/status');
  }

  static Future<List<dynamic>> getPendingRulesV2({int limit = 5, int page = 1}) async {
    final result = await httpGet('/outer_brain/pending_rules?limit=$limit');
    if (result is List) return result;
    if (result is Map && result['rules'] is List) return result['rules'];
    return [];
  }

  static Future<Map<String, dynamic>> getUpcomingIpo({int page = 1, int pageSize = 20}) async {
    return await httpGet('/ipo/upcoming?page=$page&pageSize=$pageSize');
  }

  static Future<Map<String, dynamic>> getStrategyAlchemyStatus() async {
    return await httpGet('/strategy_library/status');
  }

  static Future<Map<String, dynamic>> terminateInternship(String strategyId) async {
    return await httpPost('/strategy_library/terminate_internship', body: {'strategy_id': strategyId});
  }

  static Future<Map<String, dynamic>> adjustGrayWeight(String strategyId, double weight) async {
    return await httpPost('/strategy_library/adjust_gray_weight', body: {'strategy_id': strategyId, 'weight': weight});
  }

  // IPO
  static Future<Map<String, dynamic>> getIpoAnalysis(String stockCode) async {
    return await httpGet('/ipo/analysis?stock_code=$stockCode');
  }

  static Future<Map<String, dynamic>> participateIpo(String stockCode) async {
    return await httpPost('/ipo/participate', body: {'stock_code': stockCode});
  }

  // 红蓝军
  static Future<Map<String, dynamic>> runLightWarGame() async {
    return await httpPost('/war_game/run_light');
  }

  static Future<Map<String, dynamic>> runDeepWarGame() async {
    return await httpPost('/war_game/run_deep');
  }

  // 日志
  static Future<Map<String, dynamic>> searchLogs({
    String? module,
    String? level,
    String? keyword,
    int days = 7,
    int page = 1,
    int pageSize = 50,
  }) async {
    return await httpPost('/logs/search', body: {
      'module': module,
      'level': level,
      'keyword': keyword,
      'days': days,
      'page': page,
      'page_size': pageSize,
    });
  }

  static Future<Map<String, dynamic>> exportLogs({
    String? module,
    String? level,
    String? keyword,
    int days = 7,
  }) async {
    return await httpGet('/logs/export?module=${module ?? ''}&level=${level ?? ''}&keyword=${keyword ?? ''}&days=$days');
  }

  static Future<Map<String, dynamic>> uploadLogs(String filePath) async {
    // 注意：此方法需要 multipart 上传，简化实现暂不提供完整代码，可后续补充
    return {'success': false, 'message': '上传功能暂未实现'};
  }

  // 仲裁
  static Future<Map<String, dynamic>> getLatestArbitration() async {
    return await httpGet('/arbitration/latest');
  }

  static Future<Map<String, dynamic>> getArbitrationHistory({int page = 1, int limit = 20}) async {
    return await httpGet('/arbitration/history?page=$page&limit=$limit');
  }

  // 系统升级
  static Future<Map<String, dynamic>> getSystemUpgradeStatus() async {
    return await httpGet('/system/upgrade_status');
  }

  static Future<Map<String, dynamic>> systemUpgrade() async {
    return await httpPost('/system/upgrade');
  }

  // 语音反馈
  static Future<Map<String, dynamic>> voiceFeedback(String command, {String? error, String? feedback}) async {
    return await httpPost('/voice/feedback', body: {
      'command': command,
      'error': error,
      'feedback': feedback,
    });
  }

  // 一键修复
  static Future<Map<String, dynamic>> oneClickFix() async {
    return await httpPost('/code/fix', body: {'operation': 'apply_patch', 'fingerprint_verified': true});
  }

  // ========== 获取指定类型的待审批建议 ==========
  static Future<List<dynamic>> getPendingAdviceByType(String type) async {
    try {
      final result = await httpGet('/advice/pending?type=$type');
     
      // 直接返回数组的情况
      if (result is List) {
        debugPrint('getPendingAdviceByType($type): 返回数组，长度 ${result.length}');
        return result;
      }
     
      // 返回对象且包含 advices 字段的情况
      if (result is Map) {
        final advices = result['advices'];
        if (advices is List) {
          debugPrint('getPendingAdviceByType($type): 从 advices 字段提取数组，长度 ${advices.length}');
          return advices;
        }
        // 兼容其他可能的字段名
        final items = result['items'];
        if (items is List) {
          debugPrint('getPendingAdviceByType($type): 从 items 字段提取数组，长度 ${items.length}');
          return items;
        }
        final data = result['data'];
        if (data is List) {
          debugPrint('getPendingAdviceByType($type): 从 data 字段提取数组，长度 ${data.length}');
          return data;
        }
      }
     
      // 请求失败或格式未知
      debugPrint('getPendingAdviceByType($type): 返回格式未知或为空，返回空数组');
      return [];
    } catch (e) {
      debugPrint('getPendingAdviceByType($type): 异常 $e');
      return [];
    }
  }

  // ========== 获取待审批代码修改数量 ==========
  static Future<int> getPendingCodeFixCount() async {
    final list = await getPendingAdviceByType('code_fix');
    return list.length;
  }

  // ========== 交易信号池接口 ==========
  /// 获取交易信号池数据（包括交易池和影子池）
  static Future<Map<String, dynamic>?> getTradingSignals() async {
    return await httpGet('/trading_signals');
  }

  /// 从交易信号池中剔除股票
  static Future<Map<String, dynamic>> removeFromTradingSignals(String stockCode) async {
    final result = await httpPost('/trading_signals/remove', body: {'stock_code': stockCode});
    return result ?? {'success': false, 'message': '请求失败'};
  }

  /// 将影子池中的股票提升到交易信号池
  static Future<Map<String, dynamic>> promoteToTradingSignals(String stockCode) async {
    final result = await httpPost('/trading_signals/promote', body: {'stock_code': stockCode});
    return result ?? {'success': false, 'message': '请求失败'};
  }

  // ========== 外脑一键批准所有待审核规则 ==========
  /// 一键批准所有待审核规则（需指纹验证）
  static Future<Map<String, dynamic>> approveAllPendingRules() async {
    final result = await httpPost('/outer_brain/approve_all');
    return result ?? {'success': false, 'message': '请求失败'};
  }

  // ========== 日报/周报/月报接口 ==========
  /// 获取最新日报
  static Future<Map<String, dynamic>?> getDailyReportLatest() async {
    return await httpGet('/reports/daily/latest');
  }

  /// 获取最新周报
  static Future<Map<String, dynamic>?> getWeeklyReportLatest() async {
    return await httpGet('/reports/weekly/latest');
  }

  /// 获取最新月报
  static Future<Map<String, dynamic>?> getMonthlyReportLatest() async {
    return await httpGet('/reports/monthly/latest');
  }

  /// 获取指定日期的日报（格式 YYYY-MM-DD）
  static Future<Map<String, dynamic>?> getDailyReportByDate(String date) async {
    return await httpGet('/reports/daily/$date');
  }

  // ========== 日报/周报/月报完整接口（补充） ==========
  /// 获取最新日报（兼容旧命名，返回完整数据）
  static Future<Map<String, dynamic>?> getDailyReport() async {
    final result = await httpGet('/reports/latest');
    if (result != null && result is Map && result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// 获取最新周报
  static Future<Map<String, dynamic>?> getWeeklyReport() async {
    final result = await httpGet('/reports/weekly/latest');
    if (result != null && result is Map && result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// 获取最新月报
  static Future<Map<String, dynamic>?> getMonthlyReport() async {
    final result = await httpGet('/reports/monthly/latest');
    if (result != null && result is Map && result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ========== 待办事项接口 ==========
  /// 获取当前待办事项列表
  static Future<List<dynamic>> getActionItems() async {
    final result = await httpGet('/reports/action_items');
    if (result != null && result is Map && result['success'] == true) {
      return result['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  /// 标记待办事项为已完成（需指纹验证）
  static Future<bool> completeActionItem(String itemId) async {
    final result = await httpPost('/reports/action_items/$itemId/complete');
    return result?['success'] ?? false;
  }

  // ========== 交易池操作接口（补充降级） ==========
  /// 将股票从交易池降级到影子池（需指纹验证）
  static Future<Map<String, dynamic>> demoteToShadowPool(String stockCode) async {
    final result = await httpPost('/trading_signals/demote', body: {'stock_code': stockCode});
    return result ?? {'success': false, 'message': '请求失败'};
  }

  // ========== 影子账户接口 ==========
  /// 获取影子账户今日虚拟成交记录
  static Future<List<dynamic>> getShadowOrders({int limit = 50}) async {
    final result = await httpGet('/shadow/orders?limit=$limit');
    if (result != null && result is List) return result;
    if (result != null && result is Map && result['orders'] is List) {
      return result['orders'] as List;
    }
    return [];
  }

  // ==================== 宫崎骏模块 API 接口（2026-04-14 追加） ====================

  /// 获取宫崎骏稽查中心首页数据
  /// 返回：健康评分、活跃事件组数、待处理建议数、今日诊断摘要等
  static Future<Map<String, dynamic>?> fetchMiyazakiDashboard() async {
    return await httpGet('/miyazaki/dashboard');
  }

  /// 获取宫崎骏异常事件列表
  /// [limit] 返回条数，默认50
  /// [page] 页码，默认1
  /// [minSeverity] 最低严重程度（1-5），可选
  static Future<Map<String, dynamic>?> fetchMiyazakiEvents({
    int limit = 50,
    int page = 1,
    int? minSeverity,
  }) async {
    String url = '/miyazaki/events?limit=$limit&page=$page';
    if (minSeverity != null) {
      url += '&min_severity=$minSeverity';
    }
    return await httpGet(url);
  }

  /// 获取宫崎骏事件组列表（聚合后的事件组）
  static Future<List<dynamic>?> fetchMiyazakiEventGroups() async {
    final result = await httpGet('/miyazaki/event_groups');
    if (result != null && result is Map && result['groups'] is List) {
      return result['groups'] as List;
    }
    return null;
  }

  /// 获取宫崎骏诊断报告
  /// [date] 指定日期（YYYY-MM-DD），不传则返回最新
  static Future<Map<String, dynamic>?> fetchMiyazakiDiagnosis({
    String? date,
  }) async {
    if (date != null && date.isNotEmpty) {
      return await httpGet('/miyazaki/diagnosis?date=$date');
    }
    return await httpGet('/miyazaki/diagnosis');
  }

  /// 根据诊断ID获取诊断报告详情
  static Future<Map<String, dynamic>?> fetchMiyazakiDiagnosisById(String id) async {
    return await httpGet('/miyazaki/diagnosis/$id');
  }

  /// 手动触发一次全面诊断（需指纹验证）
  static Future<bool> triggerMiyazakiDiagnosis() async {
    final result = await httpPost('/miyazaki/diagnosis/run');
    return result?['success'] ?? false;
  }

  /// 获取谱系追踪记录列表
  /// [limit] 返回条数，默认20
  /// [impactLevel] 按影响等级过滤（positive/neutral/negative/critical），可选
  static Future<Map<String, dynamic>?> fetchMiyazakiLineage({
    int limit = 20,
    String? impactLevel,
  }) async {
    String url = '/miyazaki/lineage?limit=$limit';
    if (impactLevel != null && impactLevel.isNotEmpty) {
      url += '&impact_level=$impactLevel';
    }
    return await httpGet(url);
  }

  /// 根据记录ID获取单条谱系记录详情
  static Future<Map<String, dynamic>?> fetchMiyazakiLineageById(String id) async {
    return await httpGet('/miyazaki/lineage/$id');
  }

  /// 获取宫崎骏模块运行统计信息
  static Future<Map<String, dynamic>?> fetchMiyazakiStatistics() async {
    return await httpGet('/miyazaki/statistics');
  }

  // ==================== 影子账户别名方法（兼容 fetchShadowRealtimeCompare） ====================
   /// 获取影子与实盘实时对比（别名，兼容 fetchShadowRealtimeCompare 调用）
  static Future<Map<String, dynamic>?> fetchShadowRealtimeCompare() async {
    return await getShadowRealtimeCompare();
  }
}