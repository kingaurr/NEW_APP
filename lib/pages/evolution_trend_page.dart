// lib/pages/evolution_trend_page.dart
// ==================== v2.0 自进化引擎：进化趋势图表页（2026-04-25） ====================
// 功能描述：
// 1. 展示系统胜率、夏普比率、最大回撤、总收益的进化趋势数据
// 2. 以简洁的数值卡片和趋势方向展示各指标变化
// 3. 数据来源：后端 /api/evolution/trends → data/performance_stats.json
// 遵循规范：
// - P0 真实数据原则：所有数据来自API，无数据展示"暂无趋势数据"。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P7 完整交互绑定：无复杂交互，仅展示数据。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 进化趋势图表页
class EvolutionTrendPage extends StatefulWidget {
  const EvolutionTrendPage({super.key});

  @override
  State<EvolutionTrendPage> createState() => _EvolutionTrendPageState();
}

class _EvolutionTrendPageState extends State<EvolutionTrendPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<double> _winRate = [];
  List<double> _sharpeRatio = [];
  List<double> _maxDrawdown = [];
  List<double> _totalReturn = [];
  List<String> _dates = [];

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
      final result = await ApiService.getEvolutionTrends();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _winRate = _parseDoubleList(data['win_rate']);
          _sharpeRatio = _parseDoubleList(data['sharpe_ratio']);
          _maxDrawdown = _parseDoubleList(data['max_drawdown']);
          _totalReturn = _parseDoubleList(data['total_return']);
          _dates = _parseStringList(data['dates']);
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

  List<double> _parseDoubleList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<num>()
          .map((n) => n.toDouble())
          .toList();
    }
    return [];
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('进化趋势'),
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
                : _winRate.isEmpty && _sharpeRatio.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, color: Colors.white38, size: 64),
                            SizedBox(height: 16),
                            Text(
                              '暂无趋势数据',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_dates.isNotEmpty) _buildDateRangeCard(),
                            const SizedBox(height: 16),
                            _buildTrendMetricCard(
                              '胜率',
                              _winRate,
                              '%',
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildTrendMetricCard(
                              '夏普比率',
                              _sharpeRatio,
                              '',
                              Colors.blue,
                              Icons.speed,
                            ),
                            const SizedBox(height: 14),
                            _buildTrendMetricCard(
                              '最大回撤',
                              _maxDrawdown,
                              '%',
                              Colors.orange,
                              Icons.trending_down,
                            ),
                            const SizedBox(height: 14),
                            _buildTrendMetricCard(
                              '总收益',
                              _totalReturn,
                              '%',
                              Colors.purple,
                              Icons.account_balance_wallet,
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final firstDate = _dates.isNotEmpty ? _dates.first : '';
    final lastDate = _dates.isNotEmpty ? _dates.last : '';
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 12),
            Text(
              firstDate.isNotEmpty && lastDate.isNotEmpty
                  ? '$firstDate ~ $lastDate'
                  : '数据范围',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_dates.length} 个数据点',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendMetricCard(
    String label,
    List<double> values,
    String unit,
    Color color,
    IconData icon,
  ) {
    final current = values.isNotEmpty ? values.last : 0.0;
    final previous = values.length >= 2 ? values[values.length - 2] : current;
    final delta = current - previous;
    final isUp = delta > 0;
    final isFlat = delta.abs() < 1e-6;

    // 对于回撤，上升是坏事
    final bool isPositive;
    if (label == '最大回撤') {
      isPositive = delta < 0;
    } else {
      isPositive = isUp;
    }

    final trendIcon = isFlat
        ? Icons.remove
        : isUp
            ? Icons.arrow_upward
            : Icons.arrow_downward;
    final trendColor = isFlat
        ? Colors.grey
        : isPositive
            ? Colors.green
            : Colors.red;

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${current.toStringAsFixed(2)}$unit',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(trendIcon, color: trendColor, size: 20),
                Text(
                  isFlat
                      ? '持平'
                      : '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(2)}$unit',
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (values.isNotEmpty) _buildMiniBarChart(values, color),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBarChart(List<double> values, Color color) {
    if (values.isEmpty) return const SizedBox.shrink();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final normalizedRange = range < 1e-6 ? 1.0 : range;

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final height = ((v - minVal) / normalizedRange * 36) + 4;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: height,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}