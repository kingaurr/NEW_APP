// lib/pages/alert_detail_page.dart
import 'package:flutter/material.dart';

class AlertDetailPage extends StatelessWidget {
  final Map<String, dynamic> alert;
  const AlertDetailPage({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警详情'),
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
                  Row(
                    children: [
                      Icon(
                        alert['level'] == 'ERROR' ? Icons.error : Icons.warning,
                        color: alert['level'] == 'ERROR' ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert['level'] ?? 'INFO',
                        style: TextStyle(
                          color: alert['level'] == 'ERROR' ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(alert['content'] ?? '无内容'),
                  const SizedBox(height: 16),
                  Text('时间: ${alert['time'] ?? ''}'),
                  if (alert['details'] != null) ...[
                    const SizedBox(height: 16),
                    const Text('详细信息:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert['details'],
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 标记已读
                    Navigator.pop(context, true);
                  },
                  child: const Text('标记已读'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}