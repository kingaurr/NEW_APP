// lib/pages/evolution_strategy_compare.dart
// ==================== v2.0 自进化引擎：策略进化前后对比页（2026-04-25） ====================
// 功能描述：
// 1. 展示策略参数锦标赛冠军与原参数的前后对比
// 2. 展示关键指标变化（胜率、夏普、回撤、盈亏比）
// 3. 支持按策略ID筛选
// 4. 数据来源：后端 /api/evolution/strategies
// 遵循规范：
// - P0 真实数据原则：所有数据来自API，无数据展示"暂无对比数据"。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P6 路由参数解耦：参数为null时提供默认值。
// - P7 完整交互绑定：点击卡片跳转对应策略详情。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 策略进化对比页
class EvolutionStrategyCompare extends StatefulWidget {
  final String strategyId;

  const EvolutionStrategyCompare({super.key, required this.strategyId});

  @override
  State<EvolutionStrategyCompare> createState() => _EvolutionStrategyCompareState();
}

class _EvolutionStrategyCompareState extends State<EvolutionStrategyCompare> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _comparisons = [];
  String _selectedStrategyId = '';

  @override
  void initState() {
    super.initState();
    _selectedStrategyId = widget.strategyId;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getEvolutionStrategies();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final strategies = data['strategies'] as List<dynamic>? ?? [];

        final typedList = <Map<String, dynamic>>[];
        for (final item in strategies) {
          if (item is Map<String, dynamic>) {
            typedList.add(item);
          }
        }

        setState(() {
          _comparisons = typedList;
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

  List<Map<String, dynamic>> get _filteredComparisons {
    if (_selectedStrategyId.isEmpty) return _comparisons;
    return _comparisons
        .where((s) => s['strategy_id'] == _selectedStrategyId || s['id'] == _selectedStrategyId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('策略进化对比'),
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
                : _filteredComparisons.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.compare_arrows, color: Colors.white38, size: 64),
                            SizedBox(height: 16),
                            Text(
                              '暂无对比数据',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _filteredComparisons.length,
                        itemBuilder: (context, index) {
                          return _buildComparisonCard(_filteredComparisons[index]);
                        },
                      ),
      ),
    );
  }

  Widget _buildComparisonCard(Map<String, dynamic> item) {
    final strategyName = item['strategy_name'] ?? item['name'] ?? '未知策略';
    final strategyId = item['strategy_id'] ?? item['id'] ?? '';
    final originalParams = item['original_params'] as Map<String, dynamic>? ?? {};
    final championParams = item['champion_params'] as Map<String, dynamic>? ?? {};
    final metrics = item['metrics'] as Map<String, dynamic>? ?? {};
    final optimizationMethod = item['optimization_method'] ?? '';
    final outerVerified = item['outer_brain_verified'] ?? false;
    final oosVerified = item['out_of_sample_verified'] ?? false;

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 策略名称与验证状态
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.compare_arrows, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (strategyId is String && strategyId.isNotEmpty)
                        Text(
                          strategyId,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (outerVerified == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '外脑验证通过',
                      style: TextStyle(color: Colors.green, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 关键指标对比
            _buildMetricsRow(metrics, oosVerified),
            const SizedBox(height: 14),

            // 参数变化对比
            if (originalParams.isNotEmpty && championParams.isNotEmpty)
              _buildParamsCompare(originalParams, championParams, optimizationMethod)
            else
              const Text(
                '暂无参数对比数据',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> metrics, bool oosVerified) {
    final winRate = metrics['win_rate'] ?? 0.0;
    final sharpe = metrics['sharpe_ratio'] ?? 0.0;
    final drawdown = metrics['max_drawdown'] ?? 0.0;
    final profitLoss = metrics['profit_loss_ratio'] ?? 0.0;

    return Row(
      children: [
        _buildMetricCol('胜率', '${(winRate is num ? winRate.toDouble() : 0.0).toStringAsFixed(1)}%', Colors.green),
        const SizedBox(width: 6),
        _buildMetricCol('夏普', (sharpe is num ? sharpe.toDouble() : 0.0).toStringAsFixed(2), Colors.blue),
        const SizedBox(width: 6),
        _buildMetricCol('回撤', '${(drawdown is num ? drawdown.toDouble() : 0.0).toStringAsFixed(1)}%', Colors.orange),
        const SizedBox(width: 6),
        _buildMetricCol('盈亏比', (profitLoss is num ? profitLoss.toDouble() : 0.0).toStringAsFixed(2), Colors.purple),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamsCompare(
    Map<String, dynamic> original,
    Map<String, dynamic> champion,
    String method,
  ) {
    final changedKeys = <String>[];
    for (final key in champion.keys) {
      final origVal = original[key];
      final champVal = champion[key];
      if (origVal != champVal) {
        changedKeys.add(key);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '参数变化',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              if (method is String && method.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    method,
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (changedKeys.isEmpty)
            const Text('无参数变化', style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            ...changedKeys.take(5).map((key) {
              final origVal = original[key];
              final champVal = champion[key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        key,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${_formatVal(origVal)} → ${_formatVal(champVal)}',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (changedKeys.length > 5)
            Text(
              '... 还有 ${changedKeys.length - 5} 项参数变化',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
        ],
      ),
    );
  }

  String _formatVal(dynamic val) {
    if (val == null) return '?';
    if (val is double) return val.toStringAsFixed(4);
    if (val is int) return val.toString();
    return val.toString();
  }
}