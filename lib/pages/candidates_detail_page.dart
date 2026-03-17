// lib/pages/candidates_detail_page.dart
import 'package:flutter/material.dart';

class CandidatesDetailPage extends StatelessWidget {
  final Map<String, dynamic> stock;
  const CandidatesDetailPage({Key? key, required this.stock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${stock['code'] ?? ''} ${stock['name'] ?? ''}'),
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
                  Text(
                    '六大凭证评分',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildFactorRow(theme, '逻辑自洽', stock['score_logic'] ?? 0.8),
                  _buildFactorRow(theme, '资金共振', stock['score_money'] ?? 0.6),
                  _buildFactorRow(theme, '盈亏比', stock['score_rr'] ?? 0.7),
                  _buildFactorRow(theme, '情绪周期', stock['score_cycle'] ?? 0.5),
                  _buildFactorRow(theme, '历史轨迹', stock['score_history'] ?? 0.4),
                  _buildFactorRow(theme, '关联事件', stock['score_event'] ?? 0.5),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '综合得分',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(stock['total_score'] ?? 0.6).toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '入选理由',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Text(
                    stock['reason'] ?? '暂无理由',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '技术指标',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(theme, '现价', '¥${(stock['price'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildInfoRow(theme, '涨跌幅', stock['change'] ?? '0.00%'),
                  _buildInfoRow(theme, '成交量', stock['volume']?.toString() ?? '0'),
                  _buildInfoRow(theme, '市盈率', stock['pe'] ?? '--'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(ThemeData theme, String label, double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: clampedValue,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(clampedValue * 100).toInt()}%',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}