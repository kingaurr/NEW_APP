// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API 服务类，封装所有后端接口调用
class ApiService {
  static String _baseUrl = 'http://47.108.206.221:8080/api';

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

  // 通用 POST 请求
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

  // ========== 系统状态 ==========
  static Future<Map<String, dynamic>?> getStatus() async {
    return await httpGet('/status');
  }

  // ========== 资金管理 ==========
  static Future<Map<String, dynamic>?> getFund() async {
    return await httpGet('/fund');
  }

  static Future<Map<String, dynamic>?> modifyFund(double amount, {String reason = ''}) async {
    return await httpPost('/fund', body: {'amount': amount, 'reason': reason});
  }

  // ========== 订单管理 ==========
  static Future<List<dynamic>?> getRecentOrders() async {
    return await httpGet('/orders/recent');
  }

  static Future<bool> cancelOrder(String orderId) async {
    final result = await httpPost('/orders/cancel', body: {'order_id': orderId});
    return result?['success'] ?? false;
  }

  // ========== 持仓管理 ==========
  static Future<Map<String, dynamic>?> getPositions() async {
    return await httpGet('/positions');
  }

  static Future<bool> updatePositionStopLoss(String code, double stopLoss) async {
    final result = await httpPost('/positions/stop_loss', body: {'code': code, 'stop_loss': stopLoss});
    return result?['success'] ?? false;
  }

  static Future<bool> updatePositionTakeProfit(String code, double takeProfit) async {
    final result = await httpPost('/positions/take_profit', body: {'code': code, 'take_profit': takeProfit});
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

  static Future<List<dynamic>?> getRightBrainSignals() async {
    return await httpGet('/right_brain/signals');
  }

  static Future<Map<String, dynamic>?> getLeftBrainStatus() async {
    return await httpGet('/left_brain/status');
  }

  static Future<List<dynamic>?> getLeftBrainDecisions() async {
    return await httpGet('/left_brain/decisions');
  }

  // ========== 策略管理 ==========
  static Future<List<dynamic>?> getStrategies() async {
    return await httpGet('/strategies');
  }

  static Future<Map<String, dynamic>?> getStrategyDetail(String strategyId) async {
    return await httpGet('/strategies/detail?id=$strategyId');
  }

  static Future<Map<String, dynamic>?> getStrategyDecisionTree(String strategyId) async {
    return await httpGet('/strategies/decision_tree?id=$strategyId');
  }

  static Future<Map<String, dynamic>?> getStrategyComparison(String strategyId) async {
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
    final result = await httpPost('/rules/disable', body: {'rule_id': ruleId, 'reason': reason});
    return result?['success'] ?? false;
  }

  // ========== 外脑管理 ==========
  static Future<List<dynamic>?> getPendingRules() async {
    return await httpGet('/outer_brain/pending_rules');
  }

  static Future<bool> approveRule(String ruleId) async {
    final result = await httpPost('/outer_brain/approve_rule', body: {'rule_id': ruleId});
    return result?['success'] ?? false;
  }

  static Future<bool> rejectRule(String ruleId) async {
    final result = await httpPost('/outer_brain/reject_rule', body: {'rule_id': ruleId});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getEvolutionReport() async {
    return await httpGet('/outer_brain/evolution_report');
  }

  // ========== 建议管理 ==========
  static Future<List<dynamic>?> getPendingSuggestions() async {
    return await httpGet('/advice/pending');
  }

  static Future<int> getPendingAdviceCount() async {
    final result = await httpGet('/advice/pending_count');
    return result?['count'] ?? 0;
  }

  static Future<bool> approveAdvice(String adviceId) async {
    final result = await httpPost('/advice/approve', body: {'advice_id': adviceId});
    return result?['success'] ?? false;
  }

  static Future<bool> approveAllAdvice() async {
    final result = await httpPost('/advice/approve_all');
    return result?['success'] ?? false;
  }

  static Future<bool> rejectAdvice(String adviceId, {String reason = ''}) async {
    final result = await httpPost('/advice/reject', body: {'advice_id': adviceId, 'reason': reason});
    return result?['success'] ?? false;
  }

  static Future<Map<String, dynamic>?> getAdviceDetail(String adviceId) async {
    return await httpGet('/advice/$adviceId');
  }

  static Future<List<dynamic>?> getHistoryAdvices({int limit = 50}) async {
    final result = await httpGet('/advice/history?limit=$limit');
    return result?['advices'] ?? [];
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
    final result = await httpPost('/war_game/apply', body: {'report_id': reportId});
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
  static Future<Map<String, dynamic>?> getCandidates() async {
    return await httpGet('/candidates');
  }

  static Future<List<dynamic>?> getTradePool() async {
    return await httpGet('/trade/pool');
  }

  // ========== 信号历史 ==========
  static Future<List<dynamic>?> getSignalHistory() async {
    return await httpGet('/signals/history');
  }

  // ========== 报告 ==========
  static Future<List<dynamic>?> getReportsList({String type = 'daily'}) async {
    return await httpGet('/reports/list?type=$type');
  }

  static Future<String?> getReportContent(String filename, {String type = 'daily'}) async {
    final data = await httpGet('/reports/content?type=$type&file=$filename');
    return data?['content'];
  }

  static Future<Map<String, dynamic>?> getLatestReport() async {
    return await httpGet('/reports/latest');
  }

  static Future<Map<String, dynamic>?> getLatestReportSummary() async {
    return await httpGet('/reports/latest_summary');
  }

  static Future<bool> markReportRead(String filename, {String type = 'daily'}) async {
    final result = await httpPost('/reports/mark_read', body: {'filename': filename, 'type': type});
    return result?['success'] ?? false;
  }

  // ========== 知识库 ==========
  static Future<Map<String, dynamic>?> getKnowledgeStats() async {
    return await httpGet('/knowledge/stats');
  }

  static Future<Map<String, dynamic>?> getKnowledgeStatsById(String knowledgeId) async {
    return await httpGet('/knowledge/stats/$knowledgeId');
  }

  static Future<List<dynamic>?> getKnowledgeRanking({String? type, int days = 30, int limit = 20}) async {
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
    final result = await httpPost('/version/rollback', body: {'version_id': versionId});
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
    final result = await httpPost('/backup/restore', body: {'backup_id': backupId});
    return result?['success'] ?? false;
  }

  // ========== 告警 ==========
  static Future<Map<String, dynamic>?> getAlerts() async {
    return await httpGet('/alerts/unread_count');
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
  static Future<Map<String, dynamic>?> getRecentLogs({int limit = 100, String level = ''}) async {
    String url = '/logs/recent?limit=$limit';
    if (level.isNotEmpty) url += '&level=$level';
    return await httpGet(url);
  }

  static Future<Map<String, dynamic>?> getAuditLogs({int limit = 50}) async {
    return await httpGet('/logs/audit?limit=$limit');
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
    return await httpPost('/auth/password', body: {'password': password});
  }

  static Future<Map<String, dynamic>?> authLogout() async {
    return await httpPost('/auth/logout');
  }

  static Future<Map<String, dynamic>?> verifyToken() async {
    return await httpGet('/auth/verify');
  }

  // ========== 短信验证 ==========
  static Future<Map<String, dynamic>?> smsSend(String phone) async {
    return await httpPost('/sms/send', body: {'phone': phone});
  }

  static Future<Map<String, dynamic>?> smsVerify(String code) async {
    return await httpPost('/sms/verify', body: {'code': code});
  }

  static Future<Map<String, dynamic>?> smsLogout() async {
    return await httpPost('/sms/logout');
  }

  // ========== 降级管理 ==========
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
  static Future<Map<String, dynamic>?> getBudgetSettings() async {
    return await httpGet('/settings/budget');
  }

  static Future<bool> updateBudgetSettings(Map<String, dynamic> settings) async {
    final result = await httpPost('/settings/budget', body: settings);
    return result?['success'] ?? false;
  }

  // ========== 风控基准 ==========
  static Future<Map<String, dynamic>?> getRiskBaseFund() async {
    return await httpGet('/settings/risk_base_fund');
  }

  static Future<bool> updateRiskBaseFund(double amount) async {
    final result = await httpPost('/settings/risk_base_fund', body: {'risk_base_fund': amount});
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

  static Future<List<dynamic>?> getCommandHistory() async {
    final result = await httpGet('/voice/history');
    return result?['history'] ?? [];
  }

  static Future<Map<String, dynamic>?> voiceExtractFeatures(List<int> audioBytes) async {
    return await httpPost('/voice/extract_features', body: {'audio': audioBytes});
  }

  static Future<Map<String, dynamic>?> getEvidence(String transactionId) async {
    return await httpGet('/voice/evidence/$transactionId');
  }

  static Future<Map<String, dynamic>?> verifyCommand(String command) async {
    return await httpGet('/voice/verify/$command');
  }

  static Future<Map<String, dynamic>?> voiceAsk(String text) async {
    return await httpPost('/voice/ask', body: {'text': text});
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
  static Future<Map<String, dynamic>?> voiceRegister(String userId, String userName, List<double> features) async {
    return await httpPost('/voice/register', body: {
      'user_id': userId,
      'user_name': userName,
      'features': features,
    });
  }

  static Future<Map<String, dynamic>?> voiceVerify(String userId, List<double> features) async {
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
  static Future<Map<String, dynamic>?> permissionCheck(String userId, String operation) async {
    return await httpPost('/permission/check', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  static Future<Map<String, dynamic>?> permissionAuthorize(String userId, String operation, List<String> authMethods) async {
    return await httpPost('/permission/authorize', body: {
      'user_id': userId,
      'operation': operation,
      'auth_methods': authMethods,
    });
  }

  static Future<Map<String, dynamic>?> permissionUsers() async {
    return await httpGet('/permission/users');
  }

  static Future<Map<String, dynamic>?> permissionUpdate(String userId, String level) async {
    return await httpPost('/permission/update', body: {
      'user_id': userId,
      'level': level,
    });
  }

  // ========== 指令守卫 ==========
  static Future<Map<String, dynamic>?> commandExecute(String command, String userId, {String? bypassToken, bool skipAuth = false}) async {
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
  static Future<Map<String, dynamic>?> rateLimitCheck(String userId, String operation) async {
    return await httpPost('/rate_limit/check', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  static Future<Map<String, dynamic>?> rateLimitStatus(String userId, String operation) async {
    return await httpPost('/rate_limit/status', body: {
      'user_id': userId,
      'operation': operation,
    });
  }

  // ========== IP白名单 ==========
  static Future<Map<String, dynamic>?> ipWhitelistCheck(String ip) async {
    return await httpPost('/ip_whitelist/check', body: {'ip': ip});
  }

  static Future<Map<String, dynamic>?> ipWhitelistAdd(String pattern, {String? reason}) async {
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

  // ========== 紧急停止 ==========
  static Future<Map<String, dynamic>?> emergencyStop(String reason) async {
    return await httpPost('/emergency/stop', body: {'reason': reason});
  }

  static Future<Map<String, dynamic>?> emergencyRecover({String? reason}) async {
    return await httpPost('/emergency/recover', body: {'reason': reason});
  }

  static Future<Map<String, dynamic>?> emergencyPause(String reason, int duration) async {
    return await httpPost('/emergency/pause', body: {
      'reason': reason,
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>?> emergencyStatus() async {
    return await httpGet('/emergency/status');
  }

  // ========== 审计日志 ==========
  static Future<Map<String, dynamic>?> auditLogs({int limit = 100, String? operation, String? userId}) async {
    String url = '/audit/logs?limit=$limit';
    if (operation != null) url += '&operation=$operation';
    if (userId != null) url += '&user_id=$userId';
    return await httpGet(url);
  }

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

  static Future<Map<String, dynamic>?> securityBypassToken({int duration = 300, String? ip}) async {
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

  // ========== 登录兼容 ==========
  static Future<Map<String, dynamic>?> login(String password) async {
    return await authPassword(password);
  }
}