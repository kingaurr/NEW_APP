// lib/pages/rule_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

/// 规则详情页面
/// 显示规则的完整信息、回测报告、绩效统计
class RuleDetailPage extends StatefulWidget {
  final Map<String, dynamic> rule;

  const RuleDetailPage({super.key, required this.rule});

  @override
  State<RuleDetailPage> createState() => _RuleDetailPageState();
}

class _RuleDetailPageState extends State<RuleDetailPage> {
  bool _isLoading = true;
  bool _isExpanded = false;
  Map<String, dynamic> _detail = {};
  List<double> _performanceData = [];
  List<Map<String, dynamic>> _backtestTrades = [];
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
      final result = await ApiService.getRuleDetail(widget.rule['id']);
      if (result != null) {
        setState(() {
          _detail = result;
          _performanceData = result['performance_curve'] ?? [];
          _backtestTrades = result['backtest_trades'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = '获取规则详情失败';
        });
      }
    } catch (e) {
      debugPrint('加载规则详情失败: $e');
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

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightBlue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    final name = widget.rule['name'] ?? '未命名';
    final source = widget.rule['source'] ?? '外脑';
    final status = widget.rule['status'] ?? 'pending';
    final winRate = _detail['win_rate'] ?? widget.rule['win_rate'] ?? 0.5;
    final sharpe = _detail['sharpe'] ?? widget.rule['sharpe'] ?? 0.5;
    final drawdown = _detail['max_drawdown'] ?? widget.rule['max_drawdown'] ?? 0.2;
    final profitRatio = _detail['profit_ratio'] ?? widget.rule['profit_ratio'] ?? 1.2;
    final totalReturn = _detail['total_return'] ?? 0.05;
    final backtestYears = _detail['backtest_years'] ?? 10;

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
                                    child: const Icon(
                                      Icons.rule,
                                      color: Color(0xFFD4AF37),
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
                                          '来源: $source',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'active'
                                          ? Colors.green.withOpacity(0.2)
                                          : (status == 'pending'
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status == 'active'
                                          ? '已生效'
                                          : (status == 'pending' ? '待审核' : '已拒绝'),
                                      style: TextStyle(
                                        color: status == 'active'
                                            ? Colors.green
                                            : (status == 'pending' ? Colors.orange : Colors.grey),
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

                      // 回测指标卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '回测指标',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildMetricRow('回测周期', '${backtestYears}年'),
                              _buildMetricRow('胜率', '${(winRate * 100).toInt()}%', winRate >= 0.55),
                              _buildMetricRow('夏普比率', sharpe.toStringAsFixed(2), sharpe >= 0.8),
                              _buildMetricRow('最大回撤', '${(drawdown * 100).toInt()}%', drawdown <= 0.15, isReverse: true),
                              _buildMetricRow('盈亏比', profitRatio.toStringAsFixed(1), profitRatio >= 1.5),
                              _buildMetricRow('累计收益', '${(totalReturn * 100).toInt()}%', totalReturn >= 0.05),
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

                      // 规则逻辑
                      if (_detail['logic'] != null)
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '规则逻辑',
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _detail['logic'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 回测交易记录
                      if (_backtestTrades.isNotEmpty)
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
                                    const Text(
                                      '回测交易记录',
                                      style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _isExpanded ? '收起' : '展开',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          Icon(
                                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    children: _backtestTrades.take(10).map((trade) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: _buildTradeItem(trade),
                                        )).toList(),
                                  ),
                                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 200),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricRow(String label, String value, [bool? isGood, bool isReverse = false]) {
    final actualIsGood = isGood != null ? (isReverse ? !isGood : isGood) : true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: isGood != null ? (actualIsGood ? Colors.green : Colors.red) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeItem(Map<String, dynamic> trade) {
    final action = trade['action'] ?? 'buy';
    final code = trade['code'] ?? '';
    final name = trade['name'] ?? '';
    final price = trade['price'] ?? 0.0;
    final shares = trade['shares'] ?? 0;
    final pnl = trade['pnl'] ?? 0.0;
    final date = trade['date'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: action == 'buy' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              action == 'buy' ? Icons.arrow_downward : Icons.arrow_upward,
              color: action == 'buy' ? Colors.green : Colors.red,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($code)',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shares}股 @ ¥${price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                action == 'buy' ? '买入' : '卖出',
                style: TextStyle(
                  color: action == 'buy' ? Colors.green : Colors.red,
                  fontSize: 11,
                ),
              ),
              if (pnl != 0)
                Text(
                  '${pnl >= 0 ? '+' : ''}¥${_formatNumber(pnl.abs())}',
                  style: TextStyle(
                    color: pnl >= 0 ? Colors.green : Colors.red,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}