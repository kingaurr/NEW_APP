// lib/pages/rule_detail_page.dart
import 'package:flutter/material.dart';

class RuleDetailPage extends StatelessWidget {
  final Map<String, dynamic> rule;
  const RuleDetailPage({Key? key, required this.rule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rule['id'] ?? '规则详情'),
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
                  const Text('规则内容', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rule['content'] ?? rule['desc'] ?? '无',
                      style: const TextStyle(fontFamily: 'monospace'),
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
                  const Text('绩效统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow('胜率', rule['win_rate'] ?? '0%'),
                  _buildInfoRow('使用次数', rule['usage']?.toString() ?? '0'),
                  _buildInfoRow('状态', rule['status'] ?? '生效'),
                ],
              ),
            ),
          ),
          if (rule['conflict'] != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade900.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('冲突检测', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    const Divider(color: Colors.red),
                    Text(rule['conflict']),
                  ],
                ),
              ),
            ),
          ],
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
}