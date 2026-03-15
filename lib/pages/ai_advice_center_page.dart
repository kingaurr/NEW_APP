// lib/pages/ai_advice_center_page.dart
import 'package:flutter/material.dart';

class AiAdviceCenterPage extends StatefulWidget {
  const AiAdviceCenterPage({Key? key}) : super(key: key);

  @override
  State<AiAdviceCenterPage> createState() => _AiAdviceCenterPageState();
}

class _AiAdviceCenterPageState extends State<AiAdviceCenterPage> {
  // 模拟待处理建议数据
  final List<Map<String, dynamic>> _pendingAdvices = [
    {
      'id': 'adv_001',
      'type': '规则',
      'summary': '提高均线突破策略的置信度阈值',
      'expected_profit': '+2.3%',
      'confidence': 0.85,
      'created_at': '10:23',
    },
    {
      'id': 'adv_002',
      'type': '参数',
      'summary': '降低RSI超卖策略的买入仓位',
      'expected_profit': '+1.1%',
      'confidence': 0.72,
      'created_at': '09:15',
    },
    {
      'id': 'adv_003',
      'type': '策略',
      'summary': '新增“放量突破后回调”策略',
      'expected_profit': '+3.5%',
      'confidence': 0.91,
      'created_at': '昨天',
    },
  ];

  // 模拟历史建议
  final List<Map<String, dynamic>> _historyAdvices = [
    {
      'id': 'adv_000',
      'type': '规则',
      'summary': '优化止损比例',
      'result': '执行后胜率+1.5%',
      'executed_at': '2025-03-14',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI优化建议'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '待处理'),
              Tab(text: '历史'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingList(),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _pendingAdvices.length,
      itemBuilder: (ctx, index) {
        final item = _pendingAdvices[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(item['summary']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('类型: ${item['type']} · 预期: ${item['expected_profit']}'),
                Text('置信度: ${(item['confidence']*100).toInt()}% · ${item['created_at']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _showDecisionDialog(item, '同意'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _showDecisionDialog(item, '拒绝'),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _historyAdvices.length,
      itemBuilder: (ctx, index) {
        final item = _historyAdvices[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(item['summary']),
            subtitle: Text('${item['result']} · ${item['executed_at']}'),
            trailing: const Icon(Icons.history, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showDecisionDialog(Map<String, dynamic> item, String decision) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$decision 建议'),
        content: Text('确定要${decision}建议 “${item['summary']}” 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已$decision (模拟操作)')),
              );
            },
            child: Text(decision),
          ),
        ],
      ),
    );
  }
}