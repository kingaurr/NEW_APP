// lib/pages/candidates_detail_page.dart
import 'package:flutter/material.dart';

class CandidatesDetailPage extends StatelessWidget {
  final Map<String, dynamic> stock;
  const CandidatesDetailPage({Key? key, required this.stock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${stock['code'] ?? ''} ${stock['name'] ?? ''}'),
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
                  const Text('六大凭证评分', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildFactorRow('逻辑自洽', stock['score_logic'] ?? 0.8),
                  _buildFactorRow('资金共振', stock['score_money'] ?? 0.6),
                  _buildFactorRow('盈亏比', stock['score_rr'] ?? 0.7),
                  _buildFactorRow('情绪周期', stock['score_cycle'] ?? 0.5),
                  _buildFactorRow('历史轨迹', stock['score_history'] ?? 0.4),
                  _buildFactorRow('关联事件', stock['score_event'] ?? 0.5),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('综合得分', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${(stock['total_score'] ?? 0.6).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, color: Color(0xFFD4AF37)),
                      ),
                    ],
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
                  const Text('入选理由', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text(stock['reason'] ?? '暂无理由'),
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
                  const Text('技术指标', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildInfoRow('现价', '¥${(stock['price'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildInfoRow('涨跌幅', stock['change'] ?? '0.00%'),
                  _buildInfoRow('成交量', stock['volume']?.toString() ?? '0'),
                  _buildInfoRow('市盈率', stock['pe'] ?? '--'),
                ],
              ),
            ),
          ),
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
              value: value.clamp(0.0, 1.0),
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