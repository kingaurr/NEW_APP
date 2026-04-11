// lib/pages/strategy_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../widgets/evidence_viewer.dart';

/// 策略详情页面
/// 显示策略的完整信息、绩效曲线、因子权重、决策树和对比分析
class StrategyDetailPage extends StatefulWidget {
  final Map<String, dynamic> strategy;

  const StrategyDetailPage({super.key, required this.strategy});

  @override
  State<StrategyDetailPage> createState() => _StrategyDetailPageState();
}

class _StrategyDetailPageState extends State<StrategyDetailPage> {
  bool _isLoading = true;
  bool _isComparisonExpanded = false;
  Map<String, dynamic> _detail = {};
  Map<String, dynamic> _decisionTree = {};
  Map<String, dynamic> _comparison = {};
  List<double> _performanceData = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getStrategyDetail(widget.strategy['id']),
        ApiService.getStrategyDecisionTree(widget.strategy['id']),
        ApiService.getStrategyComparison(widget.strategy['id']),
      ]);

      // 1. 策略详情
      if (results[0] != null && results[0] is Map<String, dynamic>) {
        final detail = results[0] as Map<String, dynamic>;
        // 安全转换绩效曲线
        final curveData = detail['performance_curve'] ?? detail['curve'] ?? [];
        List<double> performanceData = [];
        if (curveData is List) {
          performanceData = curveData.map((e) => (e as num).toDouble()).toList();
        }
        setState(() {
          _detail = detail;
          _performanceData = performanceData;
        });
      }

      // 2. 决策树
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        setState(() {
          _decisionTree = results[1] as Map<String, dynamic>;
        });
      }

      // 3. 对比分析
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        setState(() {
          _comparison = results[2] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('加载策略详情失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightBlue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.strategy['name'] ?? '未命名';
    final type = widget.strategy['type'] ?? 'unknown';
    final winRate = _detail['win_rate'] ?? widget.strategy['win_rate'] ?? 0.5;
    final sharpe = _detail['sharpe'] ?? widget.strategy['sharpe'] ?? 0.5;
    final drawdown = _detail['max_drawdown'] ?? widget.strategy['max_drawdown'] ?? 0.2;
    final profitRatio = _detail['profit_ratio'] ?? 1.2;
    final totalReturn = _detail['total_return'] ?? 0.05;
    final weight = _detail['weight'] ?? widget.strategy['weight'] ?? 0.1;
    final enabled = _detail['enabled'] ?? widget.strategy['enabled'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(winRate).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      type == 'trend'
                                          ? Icons.trending_up
                                          : (type == 'mean_reversion'
                                              ? Icons.compare_arrows
                                              : Icons.auto_awesome),
                                      color: _getScoreColor(winRate),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          type == 'trend'
                                              ? '趋势跟踪'
                                              : (type == 'mean_reversion' ? '均值回归' : '复合策略'),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: enabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      enabled ? '启用' : '禁用',
                                      style: TextStyle(
                                        color: enabled ? Colors.green : Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 绩效指标卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '绩效指标',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildMetricRow('胜率', '${(winRate * 100).toInt()}%', winRate >= 0.55),
                              _buildMetricRow('夏普比率', sharpe.toStringAsFixed(2), sharpe >= 0.8),
                              _buildMetricRow('最大回撤', '${(drawdown * 100).toInt()}%', drawdown <= 0.15, isReverse: true),
                              _buildMetricRow('盈亏比', profitRatio.toStringAsFixed(1), profitRatio >= 1.5),
                              _buildMetricRow('累计收益', '${(totalReturn * 100).toInt()}%', totalReturn >= 0.05),
                              _buildMetricRow('当前权重', '${(weight * 100).toInt()}%', true),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 绩效曲线
                      if (_performanceData.isNotEmpty)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '绩效曲线',
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: true),
                                      titlesData: FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _performanceData.asMap().entries.map((e) {
                                            return FlSpot(e.key.toDouble(), e.value);
                                          }).toList(),
                                          isCurved: true,
                                          color: const Color(0xFFD4AF37),
                                          barWidth: 2,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 决策树入口卡片（改为跳转独立页面）
                      if (_decisionTree.isNotEmpty)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/decision_tree',
                                arguments: {
                                  'decisionTree': _decisionTree,
                                  'strategyName': name,
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_tree, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      '决策树',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 对比分析（保留原有展开逻辑）
                      if (_comparison.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isComparisonExpanded = !_isComparisonExpanded;
                            });
                          },
                          child: Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.compare_arrows, color: Color(0xFFD4AF37), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '对比分析',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        _isComparisonExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  if (_isComparisonExpanded) ...[
                                    const SizedBox(height: 16),
                                    _buildComparisonTable(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricRow(String label, String value, bool isGood, {bool isReverse = false}) {
    final actualIsGood = isReverse ? !isGood : isGood;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: actualIsGood ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final verdict = _comparison['verdict'] ?? '';
    final summary = _comparison['summary'] ?? '';
    final worseDimensions = _comparison['worse_dimensions'] as List? ?? [];
    final betterDimensions = _comparison['better_dimensions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: verdict == '明显劣于' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                verdict,
                style: TextStyle(
                  color: verdict == '明显劣于' ? Colors.red : Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (worseDimensions.isNotEmpty) ...[
          const Text(
            '劣于平均的维度',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...worseDimensions.map((dim) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${dim['name']}: ${(dim['gap'] * 100).toInt()}% 差距',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              )),
        ],
        if (betterDimensions.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '优于平均的维度',
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...betterDimensions.map((dim) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${dim['name']}: ${(dim['gap'] * 100).toInt()}% 优势',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              )),
        ],
      ],
    );
  }
}