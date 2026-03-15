// lib/pages/strategy_detail_page.dart
import 'package:flutter/material.dart';

class StrategyDetailPage extends StatelessWidget {
  final Map<String, dynamic> strategy;
  const StrategyDetailPage({Key? key, required this.strategy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strategy['name'] ?? '策略详情'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow('类型', strategy['type'] ?? '--'),
                  _buildInfoRow('适用市场', strategy['market'] ?? '--'),
                  _buildInfoRow('实盘验证', '${strategy['real_trades'] ?? 0} 次'),
                  _buildInfoRow('胜率', '${((strategy['win_rate'] ?? 0) * 100).toStringAsFixed(0)}%'),
                  _buildInfoRow('盈亏比', (strategy['profit_ratio'] ?? 0).toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('因子权重', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildFactorRow('趋势因子', 0.30),
                  _buildFactorRow('动量因子', 0.25),
                  _buildFactorRow('共振因子', 0.20),
                  _buildFactorRow('盈亏比', 0.15),
                  _buildFactorRow('情绪周期', 0.10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('交易规则', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const Text('买入条件：'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ma5 > ma20 && volume > volume_ma5 * 1.2',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('卖出条件：'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'price < stop_loss || price > take_profit || rsi > 80',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('绩效曲线', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    color: Colors.grey[800],
                    child: const Center(child: Text('图表占位', style: TextStyle(color: Colors.white54))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFactorRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(value * 100).toInt()}%'),
        ],
      ),
    );
  }
}