// lib/pages/wargame_page.dart
import 'package:flutter/material.dart';

class WarGamePage extends StatefulWidget {
  const WarGamePage({Key? key}) : super(key: key);

  @override
  State<WarGamePage> createState() => _WarGamePageState();
}

class _WarGamePageState extends State<WarGamePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日报'),
            Tab(text: '周报'),
            Tab(text: '月报'),
            Tab(text: '进化周报'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(),
          _buildWeeklyReport(),
          _buildMonthlyReport(),
          _buildEvolutionReport(),
        ],
      ),
    );
  }

  Widget _buildDailyReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日核心指标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMetricRow('总盈亏', '+¥1,234.56', Colors.green),
                _buildMetricRow('胜率', '65.2%', Colors.green),
                _buildMetricRow('盈亏比', '1.8', Colors.green),
                _buildMetricRow('最大回撤', '-2.3%', Colors.red),
                _buildMetricRow('交易次数', '15', null),
                _buildMetricRow('佣金占比', '0.3%', null),
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
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                const SizedBox(height: 8),
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
    );
  }

  Widget _buildWeeklyReport() {
    return const Center(child: Text('周报内容（开发中）', style: TextStyle(color: Colors.white54)));
  }

  Widget _buildMonthlyReport() {
    return const Center(child: Text('月报内容（开发中）', style: TextStyle(color: Colors.white54)));
  }

  Widget _buildEvolutionReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本周进化摘要', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMetricRow('新增规则', '3条', Colors.green),
                _buildMetricRow('淘汰规则', '1条', Colors.red),
                _buildMetricRow('策略权重调整', '5个', null),
                _buildMetricRow('新增知识', '12条', Colors.green),
                const Divider(),
                const Text('热门检索关键词', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text('均线突破')),
                    Chip(label: Text('RSI背离')),
                    Chip(label: Text('放量')),
                    Chip(label: Text('主力资金')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}