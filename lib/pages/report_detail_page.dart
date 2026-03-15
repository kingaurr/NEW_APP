// lib/pages/report_detail_page.dart
import 'package:flutter/material.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportType;
  final String reportDate;
  const ReportDetailPage({Key? key, required this.reportType, required this.reportDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$reportType - $reportDate'),
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
                  const Text('核心指标', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildMetricRow('总盈亏', '+¥1,234.56', Colors.green),
                  _buildMetricRow('胜率', '65.2%', Colors.green),
                  _buildMetricRow('盈亏比', '1.8', Colors.green),
                  _buildMetricRow('最大回撤', '-2.3%', Colors.red),
                  _buildMetricRow('交易次数', '15', null),
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
                  const Text('资金曲线', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('最佳/最差交易', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.green),
                    title: const Text('000001 买入'),
                    subtitle: const Text('盈利 +¥345.67'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_down, color: Colors.red),
                    title: const Text('600036 卖出'),
                    subtitle: const Text('亏损 -¥123.45'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}