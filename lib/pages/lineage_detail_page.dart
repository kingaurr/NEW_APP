// lib/pages/lineage_detail_page.dart
// ==================== 宫崎骏模块：谱系详情页（2026-04-14） ====================
// 功能描述：
// 1. 展示单条谱系记录的完整信息：变更文件、变更时间、变更类型、影响等级。
// 2. 对比展示变更前后的核心指标（胜率、回撤、资产、模块健康分等）。
// 3. 显示影响评分、影响摘要、回滚建议。
// 4. 支持通过路由参数传入记录ID，自动加载对应数据。
// 5. 包含加载状态、错误处理、空状态展示。
// 美学设计：
// - 卡片式布局，指标对比采用左右分栏，配色清晰。
// - 影响等级标签与优先级色彩体系一致（正面绿/负面橙/严重红/中性灰）。
// - 回滚建议区域使用醒目背景色提示。
// 遵循规范：
// - P0 真实数据原则：所有数据来自API。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：setState 前检查 mounted。
// - P6 路由参数解耦：通过 arguments 接收参数。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 谱系记录数据模型
class LineageRecord {
  final String id;
  final String filePath;
  final String changeType;
  final DateTime createdAt;
  final String impactLevel;
  final double impactScore;
  final String impactSummary;
  final String rollbackRecommendation;
  final Map<String, dynamic> snapshotBefore;
  final Map<String, dynamic> snapshotAfter;

  LineageRecord({
    required this.id,
    required this.filePath,
    required this.changeType,
    required this.createdAt,
    required this.impactLevel,
    required this.impactScore,
    required this.impactSummary,
    required this.rollbackRecommendation,
    required this.snapshotBefore,
    required this.snapshotAfter,
  });

  factory LineageRecord.fromJson(Map<String, dynamic> json) {
    String id = json['record_id'] is String ? json['record_id'] : '';
    String filePath = json['file_path'] is String ? json['file_path'] : '';
    String changeType = json['change_type'] is String ? json['change_type'] : '未知';
    String impactLevel = json['impact_level'] is String ? json['impact_level'] : 'neutral';
    double impactScore = json['impact_score'] is num ? (json['impact_score'] as num).toDouble() : 0.0;
    String impactSummary = json['impact_summary'] is String ? json['impact_summary'] : '';
    String rollbackRecommendation = json['rollback_recommendation'] is String
        ? json['rollback_recommendation']
        : '';

    DateTime createdAt;
    if (json['created_at'] is String) {
      createdAt = DateTime.tryParse(json['created_at']) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    Map<String, dynamic> snapshotBefore = {};
    if (json['snapshot_before'] is Map) {
      snapshotBefore = json['snapshot_before'] as Map<String, dynamic>;
    }

    Map<String, dynamic> snapshotAfter = {};
    if (json['snapshot_after'] is Map) {
      snapshotAfter = json['snapshot_after'] as Map<String, dynamic>;
    }

    return LineageRecord(
      id: id,
      filePath: filePath,
      changeType: changeType,
      createdAt: createdAt,
      impactLevel: impactLevel,
      impactScore: impactScore,
      impactSummary: impactSummary,
      rollbackRecommendation: rollbackRecommendation,
      snapshotBefore: snapshotBefore,
      snapshotAfter: snapshotAfter,
    );
  }

  /// 从快照中提取指标数据
  Map<String, double> _extractMetrics(Map<String, dynamic> snapshot) {
    final metrics = snapshot['metrics'] as Map<String, dynamic>? ?? {};
    return {
      'win_rate': metrics['win_rate'] is num ? (metrics['win_rate'] as num).toDouble() : 0.0,
      'max_drawdown': metrics['max_drawdown'] is num ? (metrics['max_drawdown'] as num).toDouble() : 0.0,
      'total_asset': metrics['total_asset'] is num ? (metrics['total_asset'] as num).toDouble() : 0.0,
      'module_health_avg': metrics['module_health_avg'] is num ? (metrics['module_health_avg'] as num).toDouble() : 100.0,
      'positions_count': metrics['positions_count'] is num ? (metrics['positions_count'] as num).toDouble() : 0.0,
    };
  }

  Map<String, double> get metricsBefore => _extractMetrics(snapshotBefore);
  Map<String, double> get metricsAfter => _extractMetrics(snapshotAfter);

  Color get impactColor {
    switch (impactLevel) {
      case 'positive':
        return const Color(0xFF4CAF50);
      case 'negative':
        return const Color(0xFFFF9800);
      case 'critical':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get impactLabel {
    switch (impactLevel) {
      case 'positive':
        return '正面影响';
      case 'negative':
        return '负面影响';
      case 'critical':
        return '严重负面影响';
      default:
        return '无明显影响';
    }
  }
}

/// 谱系详情页
class LineageDetailPage extends StatefulWidget {
  final Map<String, dynamic>? args; // 新增：用于接收路由参数

  const LineageDetailPage({Key? key}) : args = null, super(key: key);
  const LineageDetailPage.withArgs({Key? key, this.args}) : super(key: key); // 新增：带参数的构造函数

  @override
  State<LineageDetailPage> createState() => _LineageDetailPageState();
}

class _LineageDetailPageState extends State<LineageDetailPage> {
  LineageRecord? _record;
  bool _isLoading = true;
  String? _errorMessage;
  String? _recordId;

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _fetchRecord();
  }

  void _parseArguments() {
    // 优先从 widget.args 获取，兼容旧的路由 arguments 方式
    final args = widget.args ?? ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _recordId = args['record_id'] as String?;
    }
  }

  Future<void> _fetchRecord() async {
    if (!mounted) return;
    if (_recordId == null || _recordId!.isEmpty) {
      setState(() {
        _errorMessage = '缺少记录ID';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.fetchMiyazakiLineageById(_recordId!);
      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        setState(() {
          _record = LineageRecord.fromJson(result);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '谱系记录不存在';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('谱系详情'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecord,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage == '谱系记录不存在'
                  ? Icons.history_outlined
                  : Icons.error_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (_errorMessage != '谱系记录不存在')
              TextButton(
                onPressed: _fetchRecord,
                child: const Text('重试'),
              ),
          ],
        ),
      );
    }

    final record = _record!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息卡片
          _buildHeaderCard(record),
          const SizedBox(height: 16),
          // 影响评估卡片
          _buildImpactCard(record),
          const SizedBox(height: 16),
          // 指标对比卡片
          _buildMetricsComparisonCard(record),
          const SizedBox(height: 16),
          // 回滚建议卡片
          _buildRollbackCard(record),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(LineageRecord record) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_copy_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.filePath,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.change_circle_outlined,
                  label: record.changeType,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: '${record.createdAt.month}/${record.createdAt.day} '
                      '${record.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${record.createdAt.minute.toString().padLeft(2, '0')}',
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(LineageRecord record) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '影响评估',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.impactColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: record.impactColor.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    record.impactLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: record.impactColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '影响评分：',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  record.impactScore.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: record.impactColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.summarize_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.impactSummary.isNotEmpty
                          ? record.impactSummary
                          : '暂无影响摘要',
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsComparisonCard(LineageRecord record) {
    final before = record.metricsBefore;
    final after = record.metricsAfter;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '指标对比（变更前 / 变更后）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              label: '胜率',
              before: before['win_rate'] ?? 0.0,
              after: after['win_rate'] ?? 0.0,
              isPercentage: true,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              label: '最大回撤',
              before: before['max_drawdown'] ?? 0.0,
              after: after['max_drawdown'] ?? 0.0,
              isPercentage: true,
              isInverted: true,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              label: '总资产',
              before: before['total_asset'] ?? 0.0,
              after: after['total_asset'] ?? 0.0,
              isCurrency: true,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              label: '模块健康分',
              before: before['module_health_avg'] ?? 100.0,
              after: after['module_health_avg'] ?? 100.0,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              label: '持仓数量',
              before: before['positions_count'] ?? 0.0,
              after: after['positions_count'] ?? 0.0,
              isInteger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required double before,
    required double after,
    bool isPercentage = false,
    bool isCurrency = false,
    bool isInteger = false,
    bool isInverted = false,
  }) {
    final double diff = after - before;
    final double diffPercent = before != 0 ? (diff / before).abs() : 0.0;

    Color diffColor;
    if (diff == 0) {
      diffColor = Colors.grey;
    } else if (isInverted) {
      diffColor = diff < 0 ? Colors.green : Colors.red;
    } else {
      diffColor = diff > 0 ? Colors.green : Colors.red;
    }

    String formatValue(double value) {
      if (isInteger) return value.toInt().toString();
      if (isPercentage) return '${(value * 100).toStringAsFixed(2)}%';
      if (isCurrency) return '¥${value.toStringAsFixed(2)}';
      return value.toStringAsFixed(2);
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            formatValue(before),
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        Expanded(
          flex: 3,
          child: Text(
            formatValue(after),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: diffColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: diffColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${diffPercent.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: diffColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRollbackCard(LineageRecord record) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restore_outlined, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '回滚建议',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: record.impactLevel == 'critical' || record.impactLevel == 'negative'
                    ? Colors.red.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: record.impactLevel == 'critical' || record.impactLevel == 'negative'
                      ? Colors.red.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Text(
                record.rollbackRecommendation.isNotEmpty
                    ? record.rollbackRecommendation
                    : '暂无回滚建议',
                style: TextStyle(
                  fontSize: 14,
                  color: record.impactLevel == 'critical' || record.impactLevel == 'negative'
                      ? Colors.red[700]
                      : Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
