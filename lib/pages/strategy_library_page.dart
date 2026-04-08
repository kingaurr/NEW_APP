// lib/pages/strategy_library_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'strategy_detail_page.dart';

/// 策略库页面
/// 展示所有策略及其绩效指标
class StrategyLibraryPage extends StatefulWidget {
  const StrategyLibraryPage({super.key});

  @override
  State<StrategyLibraryPage> createState() => _StrategyLibraryPageState();
}

class _StrategyLibraryPageState extends State<StrategyLibraryPage> {
  bool _isLoading = true;
  List<dynamic> _strategies = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStrategies();
      if (mounted) {
        setState(() {
          _strategies = result ?? [];
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

  Future<void> _refresh() async {
    await _loadStrategies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('策略库'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
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
                          onPressed: _refresh,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : _strategies.isEmpty
                    ? const Center(
                        child: Text('暂无策略', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _strategies.length,
                        itemBuilder: (ctx, index) {
                          final strategy = _strategies[index];
                          return _buildStrategyCard(strategy);
                        },
                      ),
      ),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> strategy) {
    final name = strategy['name'] ?? strategy['id'];
    final winRate = (strategy['win_rate'] ?? 0.0).toDouble();
    final maxDrawdown = (strategy['max_drawdown'] ?? 0.0).toDouble();
    final sharpe = (strategy['sharpe'] ?? 0.0).toDouble();
    final profitRatio = (strategy['profit_ratio'] ?? 0.0).toDouble();
    final status = strategy['enabled'] == true ? '启用' : '禁用';
    final statusColor = strategy['enabled'] == true ? Colors.green : Colors.grey;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StrategyDetailPage(strategy: strategy),
            ),
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
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildMetric('胜率', '${(winRate * 100).toInt()}%', Colors.green),
                  _buildMetric('最大回撤', '${(maxDrawdown * 100).toInt()}%', Colors.red),
                  _buildMetric('夏普比率', sharpe.toStringAsFixed(2), Colors.blue),
                  _buildMetric('盈亏比', profitRatio.toStringAsFixed(2), Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}