// lib/widgets/strategy_lifecycle_card.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 外脑中心 - 策略生命周期卡片
/// 展示实习中/灰度中的策略，支持终止实习、调整灰度权重
class StrategyLifecycleCard extends StatefulWidget {
  const StrategyLifecycleCard({super.key});

  @override
  State<StrategyLifecycleCard> createState() => _StrategyLifecycleCardState();
}

class _StrategyLifecycleCardState extends State<StrategyLifecycleCard> {
  Map<String, dynamic> _status = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStrategyAlchemyStatus();
      if (mounted) {
        setState(() {
          _status = data ?? {};
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

  Future<void> _terminateInternship(String strategyId) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指纹验证失败，操作取消')),
      );
      return;
    }
    try {
      final result = await ApiService.terminateInternship(strategyId);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已终止实习策略'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${result['error'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作异常: $e')),
      );
    }
  }

  Future<void> _adjustGrayWeight(String strategyId, double newWeight) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指纹验证失败，操作取消')),
      );
      return;
    }
    try {
      final result = await ApiService.adjustGrayWeight(strategyId, newWeight);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('权重已调整为 ${(newWeight * 100).toInt()}%'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${result['error'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作异常: $e')),
      );
    }
  }

  void _showAdjustWeightDialog(String strategyId, double currentWeight) {
    final controller = TextEditingController(text: (currentWeight * 100).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('调整灰度权重', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '权重 (%)',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final percent = double.tryParse(controller.text);
              if (percent != null && percent >= 0 && percent <= 100) {
                Navigator.pop(ctx);
                _adjustGrayWeight(strategyId, percent / 100);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入0-100之间的数字')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('加载失败: $_error', style: const TextStyle(color: Colors.grey)),
              TextButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final internshipCount = _status['internship_count'] ?? 0;
    final grayCount = _status['gray_count'] ?? 0;
    final internshipList = _status['internship_list'] ?? [];
    final grayList = _status['gray_list'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.factory, size: 28),
                SizedBox(width: 8),
                Text('策略炼金炉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('实习中', internshipCount),
                _buildStatItem('灰度中', grayCount),
              ],
            ),
            if (internshipList.isNotEmpty) ...[
              const Divider(),
              const Text('实习策略', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...internshipList.map<Widget>((s) => _buildInternshipItem(s)),
            ],
            if (grayList.isNotEmpty) ...[
              const Divider(),
              const Text('灰度策略', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...grayList.map<Widget>((s) => _buildGrayItem(s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildInternshipItem(Map<String, dynamic> strategy) {
    final name = strategy['name'] ?? strategy['id'];
    final winRate = (strategy['win_rate'] ?? 0.0).toDouble();
    final drawdown = (strategy['max_drawdown'] ?? 0.0).toDouble();
    final progress = (strategy['progress_days'] ?? 0) / (strategy['total_days'] ?? 5);
    return ListTile(
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('胜率: ${(winRate * 100).toInt()}%  回撤: ${(drawdown * 100).toInt()}%'),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          Text('实习进度: ${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _terminateInternship(strategy['id']),
        tooltip: '终止实习',
      ),
    );
  }

  Widget _buildGrayItem(Map<String, dynamic> strategy) {
    final name = strategy['name'] ?? strategy['id'];
    final weight = (strategy['current_weight'] ?? 0.0).toDouble();
    final performance = strategy['performance'] ?? 'stable';
    return ListTile(
      title: Text(name),
      subtitle: Text('当前权重: ${(weight * 100).toInt()}%  绩效: $performance'),
      trailing: IconButton(
        icon: const Icon(Icons.tune),
        onPressed: () => _showAdjustWeightDialog(strategy['id'], weight),
        tooltip: '调整权重',
      ),
    );
  }
}