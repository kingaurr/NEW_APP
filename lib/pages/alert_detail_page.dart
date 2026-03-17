// lib/pages/alert_detail_page.dart
import 'package:flutter/material.dart';

class AlertDetailPage extends StatelessWidget {
  final Map<String, dynamic> alert;
  const AlertDetailPage({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = alert['level'] ?? 'INFO';
    final isError = level == 'ERROR';
    final color = isError ? theme.colorScheme.error : theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('告警详情'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isError ? Icons.error : Icons.warning,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    alert['content'] ?? '无内容',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '时间: ${alert['time'] ?? ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (alert['details'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '详细信息:',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert['details']!,
                        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
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
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
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