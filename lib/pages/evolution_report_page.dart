// lib/pages/evolution_report_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

class EvolutionReportPage extends StatefulWidget {
  const EvolutionReportPage({super.key});

  @override
  State<EvolutionReportPage> createState() => _EvolutionReportPageState();
}

class _EvolutionReportPageState extends State<EvolutionReportPage> {
  bool _isLoading = true;
  Map<String, dynamic> _report = {};
  String _error = '';
  bool _isOperating = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getEvolutionReport();
      if (mounted) {
        setState(() {
          _report = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'running':
        return '进化中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return '待执行';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 一键批准所有待审核规则
  Future<void> _approveAllPendingRules() async {
    final pendingCount = _report['pending_rules_count'] ?? 0;
    if (pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有待审核的规则'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'approve_all_rules',
      operationDesc: '一键批准所有待审核规则',
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证失败，无法批准规则'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isOperating = true);
    try {
      final result = await ApiService.approveAllPendingRules();
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已批准 $pendingCount 条规则'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadReport();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '批准失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批准失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  /// 跳转到规则审核页面
  void _gotoPendingRules() {
    Navigator.pushNamed(context, '/pending_rules');
  }

  /// 跳转到规则详情
  void _gotoRuleDetail(String ruleId) {
    Navigator.pushNamed(
      context,
      '/rule_detail',
      arguments: {'rule_id': ruleId},
    );
  }

  /// 获取绩效颜色
  Color _getPerformanceColor(double value, double threshold) {
    if (value >= threshold) return Colors.green;
    if (value >= threshold * 0.8) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外脑进化报告'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReport,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ========== 状态卡片 ==========
                      Card(
                        color: const Color(0xFF2A2A2A),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 28),
                              const SizedBox(width: 8),
                              const Text(
                                '外脑进化状态',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_report['status'] ?? 'idle').withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(_report['status'] ?? 'idle'),
                                  style: TextStyle(color: _getStatusColor(_report['status'] ?? 'idle'), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ========== 待审核规则提示条 ==========
                      if ((_report['pending_rules_count'] ?? 0) > 0)
                        GestureDetector(
                          onTap: _gotoPendingRules,
                          child: Card(
                            color: const Color(0xFF3D2A1A),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.pending_actions, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '有 ${_report['pending_rules_count']} 条规则待审核，点击查看',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // ========== 知识源采集状态 ==========
                      Card(
                        color: const Color(0xFF2A2A2A),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '知识源采集',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildSourceStatus(
                                    '书籍',
                                    _report['books_count'] ?? 0,
                                    _report['books_success'] ?? 0,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSourceStatus(
                                    '博主',
                                    _report['bloggers_count'] ?? 0,
                                    _report['bloggers_success'] ?? 0,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSourceStatus(
                                    '新闻',
                                    _report['news_count'] ?? 0,
                                    _report['news_success'] ?? 0,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ========== 进化摘要 ==========
                      Card(
                        color: const Color(0xFF2A2A2A),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '进化摘要',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _report['summary'] ?? '暂无进化摘要',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ========== 新规则列表（含回测绩效） ==========
                      if (_report['new_rules'] != null && (_report['new_rules'] as List).isNotEmpty)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '新规则',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const Spacer(),
                                    if ((_report['pending_rules_count'] ?? 0) > 0)
                                      ElevatedButton(
                                        onPressed: _isOperating ? null : _approveAllPendingRules,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD4AF37),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        child: _isOperating
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('一键批准'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...(_report['new_rules'] as List).map((rule) => _buildRuleItem(rule)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  /// 构建知识源状态组件
  Widget _buildSourceStatus(String name, int total, int success) {
    final isSuccess = total > 0 && success >= total;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '$success/$total',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建规则项（含回测绩效）
  Widget _buildRuleItem(Map<String, dynamic> rule) {
    final ruleId = rule['rule_id'] ?? '';
    final ruleName = rule['name'] ?? rule['description'] ?? '未命名规则';
    final winRate = (rule['win_rate'] ?? 0).toDouble();
    final sharpe = (rule['sharpe_ratio'] ?? 0).toDouble();
    final maxDrawdown = (rule['max_drawdown'] ?? 0).toDouble();
    final profitLossRatio = (rule['profit_loss_ratio'] ?? 0).toDouble();
    final referenceCount = rule['reference_count'] ?? 0;
    final weightChange = (rule['weight_change'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _gotoRuleDetail(ruleId),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ruleName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 回测绩效指标
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildPerformanceChip('胜率', winRate, 55, '%'),
              _buildPerformanceChip('夏普', sharpe, 0.8, ''),
              _buildPerformanceChip('最大回撤', maxDrawdown, 15, '%', isReverse: true),
              _buildPerformanceChip('盈亏比', profitLossRatio, 1.5, ''),
            ],
          ),
          const SizedBox(height: 6),
          // 引用统计和权重变化
          Row(
            children: [
              Icon(Icons.trending_up, size: 12, color: weightChange >= 0 ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(
                '引用 $referenceCount 次',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(
                '权重 ${weightChange >= 0 ? "+" : ""}${weightChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: weightChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建绩效芯片
  Widget _buildPerformanceChip(String label, double value, double threshold, String suffix, {bool isReverse = false}) {
    Color getColor() {
      if (isReverse) {
        if (value <= threshold) return Colors.green;
        if (value <= threshold * 1.2) return Colors.orange;
        return Colors.red;
      } else {
        if (value >= threshold) return Colors.green;
        if (value >= threshold * 0.8) return Colors.orange;
        return Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getColor().withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}$suffix',
        style: TextStyle(fontSize: 10, color: getColor()),
      ),
    );
  }
}