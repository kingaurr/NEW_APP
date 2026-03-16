// lib/pages/strategies_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'strategy_detail_page.dart';

class StrategiesPage extends StatefulWidget {
  const StrategiesPage({Key? key}) : super(key: key);

  @override
  State<StrategiesPage> createState() => _StrategiesPageState();
}

class _StrategiesPageState extends State<StrategiesPage> {
  late Future<Map<String, dynamic>?> _aiStatus;
  late Future<Map<String, dynamic>?> _learningProgress;
  late Future<List<dynamic>?> _strategies;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _aiStatus = ApiService.getAIStatus();
      _learningProgress = ApiService.getLearningProgress();
      _strategies = ApiService.getStrategies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('策略库'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI 状态卡片
            FutureBuilder<Map<String, dynamic>?>(
              future: _aiStatus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}')),
                    ),
                  );
                }
                final data = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('AI版本', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(data['version'] ?? '未知'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('调用次数'),
                            Text('${data['total_calls'] ?? 0} 次'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('累计成本'),
                            Text('¥ ${(data['total_cost'] ?? 0).toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('健康度'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: data['health'] == 'good' ? 1.0 : 0.5,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(data['health'] ?? 'unknown'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 学习进度卡片
            FutureBuilder<Map<String, dynamic>?>(
              future: _learningProgress,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}')),
                    ),
                  );
                }
                final data = snapshot.data!;
                final offline = data['offline'] ?? {};
                final online = data['online'] ?? {};
                final wargame = data['wargame'] ?? {};
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('学习进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.sync, color: Color(0xFFD4AF37)),
                          title: const Text('离线训练'),
                          subtitle: Text('上次训练: ${offline['last_train_time'] ?? '无'}, 样本数: ${offline['samples'] ?? 0}'),
                          trailing: Text(offline['last_train_time'] != null ? '就绪' : '未运行', 
                                         style: TextStyle(color: offline['last_train_time'] != null ? Colors.green : Colors.grey)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.storage, color: Color(0xFFD4AF37)),
                          title: const Text('在线学习缓存'),
                          subtitle: Text('样本数: ${online['cache_size'] ?? 0}'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.sports_esports, color: Color(0xFFD4AF37)),
                          title: const Text('红蓝军演习'),
                          subtitle: Text('上次: ${wargame['last_time'] ?? '无'}, 生成规则: ${wargame['rules_generated'] ?? 0}条'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 策略列表
            const Text('策略库', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>?>(
              future: _strategies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
                }
                final strategies = snapshot.data!;
                if (strategies.isEmpty) {
                  return const Center(child: Text('暂无策略'));
                }
                return Column(
                  children: strategies.map((s) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(s['name'] ?? '未知'),
                      subtitle: Text('${s['type'] ?? '未知'} · ${s['market'] ?? 'all'} · 实盘验证 ${s['real_trades'] ?? 0}次'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '胜率 ${s['win_rate'] != null ? (s['win_rate']*100).toStringAsFixed(0) : '0'}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('盈亏比 ${s['profit_ratio']?.toStringAsFixed(2) ?? '0.00'}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/strategy_detail',
                          arguments: s,
                        );
                      },
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}