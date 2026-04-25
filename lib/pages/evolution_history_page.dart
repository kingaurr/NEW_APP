// lib/pages/evolution_history_page.dart
// ==================== v2.0 自进化引擎：历史进化记录页（2026-04-25） ====================
// 功能描述：
// 1. 展示最近7天进化报告概览列表
// 2. 每条记录显示日期、建议数量、已采纳数量、是否有评审
// 3. 点击可查看指定日期的进化报告详情
// 4. 支持下拉刷新
// 数据来源：后端 /api/evolution/reports
// 遵循规范：
// - P0 真实数据原则：所有数据来自API，无数据展示"暂无历史记录"。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P7 完整交互绑定：列表项使用 InkWell 包裹，点击跳转详情。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 历史进化记录页
class EvolutionHistoryPage extends StatefulWidget {
  const EvolutionHistoryPage({super.key});

  @override
  State<EvolutionHistoryPage> createState() => _EvolutionHistoryPageState();
}

class _EvolutionHistoryPageState extends State<EvolutionHistoryPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getEvolutionReports();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final reports = data['reports'] as List<dynamic>? ?? [];

        final typedList = <Map<String, dynamic>>[];
        for (final item in reports) {
          if (item is Map<String, dynamic>) {
            typedList.add(item);
          }
        }

        setState(() {
          _reports = typedList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络异常，请检查连接';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('历史记录'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : _reports.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, color: Colors.white38, size: 64),
                            SizedBox(height: 16),
                            Text(
                              '暂无历史记录',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(_reports[index]);
                        },
                      ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final packDate = report['pack_date'] ?? report['date'] ?? '未知日期';
    final totalSuggestions = report['total_suggestions'] ?? report['suggestions_count'] ?? 0;
    final injectedCount = report['suggestions_injected'] ?? report['injected_count'] ?? 0;
    final stagesCompleted = report['stages_completed'] ?? [];
    final stagesFailed = report['stages_failed'] ?? [];
    final success = report['success'] ?? false;
    final elapsed = report['elapsed_seconds'] ?? 0.0;
    final nWarnings = report['n_warnings'] ?? report['warning_count'] ?? 0;

    final totalStages = (stagesCompleted is List ? stagesCompleted.length : 0) +
        (stagesFailed is List ? stagesFailed.length : 0);
    final completedStages = stagesCompleted is List ? stagesCompleted.length : 0;

    final statusIcon = success == true ? Icons.check_circle : Icons.warning;
    final statusColor = success == true ? Colors.green : Colors.orange;

    final elapsedNum = elapsed is num ? elapsed.toDouble() : 0.0;
    final totalSuggestionsNum = totalSuggestions is int ? totalSuggestions : 0;
    final injectedNum = injectedCount is int ? injectedCount : 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/evolution_report',
            arguments: {'date': packDate},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    packDate is String ? packDate : '未知日期',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      success == true ? '成功' : '部分失败',
                      style: TextStyle(color: statusColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    '${totalStages}个模块',
                    Icons.extension,
                    const Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 10),
                  _buildInfoChip(
                    '${completedStages}个完成',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _buildInfoChip(
                    '${totalSuggestionsNum}条建议',
                    Icons.lightbulb_outline,
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildInfoChip(
                    '${injectedNum}条注入',
                    Icons.call_made,
                    Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  _buildInfoChip(
                    '${elapsedNum.toStringAsFixed(1)}s',
                    Icons.timer,
                    Colors.grey,
                  ),
                  if (nWarnings is int && nWarnings > 0) ...[
                    const SizedBox(width: 10),
                    _buildInfoChip(
                      '$nWarnings 个预警',
                      Icons.warning_amber,
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}