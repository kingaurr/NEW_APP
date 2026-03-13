// lib/pages/knowledge_page.dart
import 'package:flutter/material.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({Key? key}) : super(key: key);

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> with SingleTickerProviderStateMixin {
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
        title: const Text('知识库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '规则库'),
            Tab(text: '案例库'),
            Tab(text: '痛苦记忆'),
            Tab(text: '外脑配置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRulesTab(),
          _buildCasesTab(),
          _buildFailuresTab(),
          _buildConfigTab(),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('自动生成规则', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildRuleItem('R001', 'if ma5 > ma20 then buy', '胜率 68%', '生效', Colors.green),
                _buildRuleItem('R002', 'if rsi < 30 then buy', '胜率 55%', '生效', Colors.green),
                _buildRuleItem('R003', 'if volume > volume_ma5*1.5 then buy', '胜率 42%', '冲突', Colors.red),
                _buildRuleItem('R004', 'if close < boll_lower then buy', '胜率 71%', '生效', Colors.green),
                const Divider(),
                const Text('冲突检测结果', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade900.withOpacity(0.3),
                  child: const Text('规则R003与R001存在逻辑冲突，建议调整'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCasesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('牛股基因案例', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildCaseItem('贵州茅台 (600519)', '2025-01-15', '放量突破前高，后续涨幅30%', Icons.trending_up, Colors.green),
                _buildCaseItem('宁德时代 (300750)', '2025-02-03', 'MACD底背离，反弹20%', Icons.trending_up, Colors.green),
                const SizedBox(height: 16),
                const Text('惨案特征', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildCaseItem('东方财富 (300059)', '2025-02-28', '高位放量滞涨，后续跌15%', Icons.trending_down, Colors.red),
                _buildCaseItem('中国平安 (601318)', '2025-03-01', '跌破年线后加速下跌', Icons.trending_down, Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailuresTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('亏损案例归因', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFailureItem('000001', '2025-03-10', '追高被套', '亏损 ¥1,234'),
                _buildFailureItem('600036', '2025-03-09', '卖飞牛股', '少赚 ¥2,345'),
                _buildFailureItem('601318', '2025-03-08', '震荡市追涨', '亏损 ¥567'),
                const Divider(),
                const Text('相似案例提示', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade900.withOpacity(0.3),
                  child: const Text('当前持仓中 000858 形态与失败案例 000001 相似，建议谨慎'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('专家白名单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildConfigItem('张三', '趋势交易', '已启用'),
                _buildConfigItem('李四', '量化模型', '已启用'),
                _buildConfigItem('王五', '宏观分析', '未启用'),
                const Divider(),
                const Text('书籍规则库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildConfigItem('海龟交易法则', '规则数: 12', '已导入'),
                _buildConfigItem('股票大作手', '规则数: 8', '已导入'),
                const Divider(),
                const Text('动态关键词库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildConfigItem('震荡市', '低吸 +5%, 追高 -3%', '权重 0.8'),
                _buildConfigItem('牛市', '追涨 +8%', '权重 1.2'),
                const SizedBox(height: 16),
                const Text('知识统计', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('总条目: 156'),
                    Text('向量库大小: 45 MB'),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('最近新增: 7条'),
                    Text(''),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String id, String desc, String winRate, String status, Color statusColor) {
    return ListTile(
      title: Text('$id: $desc'),
      subtitle: Text(winRate),
      trailing: Chip(label: Text(status), backgroundColor: statusColor.withOpacity(0.2), labelStyle: TextStyle(color: statusColor)),
      dense: true,
    );
  }

  Widget _buildCaseItem(String title, String date, String desc, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text('$date\n$desc'),
      isThreeLine: true,
    );
  }

  Widget _buildFailureItem(String code, String date, String reason, String loss) {
    return ListTile(
      leading: const Icon(Icons.error, color: Colors.red),
      title: Text(code),
      subtitle: Text('$date  $reason'),
      trailing: Text(loss, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildConfigItem(String name, String detail, String status) {
    return ListTile(
      title: Text(name),
      subtitle: Text(detail),
      trailing: Text(status, style: TextStyle(color: status == '已启用' ? Colors.green : Colors.white54)),
      dense: true,
    );
  }
}