// lib/pages/strategies_page.dart
import 'package:flutter/material.dart';
import 'strategy_detail_page.dart';

class StrategiesPage extends StatefulWidget {
  const StrategiesPage({Key? key}) : super(key: key);

  @override
  State<StrategiesPage> createState() => _StrategiesPageState();
}

class _StrategiesPageState extends State<StrategiesPage> {
  late Future<Map<String, dynamic>> _aiStatus;
  late Future<List<dynamic>> _strategies;

  @override
  void initState() {
    super.initState();
    _aiStatus = _fetchAIStatus();
    _strategies = _fetchStrategies();
  }

  Future<Map<String, dynamic>> _fetchAIStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'version': '1.2.0',
      'last_update': '2025-03-14',
      'right_brain': 'deepseek-v3',
      'left_brain': 'qwen-plus',
      'today_calls': 125,
      'total_cost': 2.35,
      'health_score': 85,
    };
  }

  Future<List<dynamic>> _fetchStrategies() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {
        'name': '均线突破',
        'type': '趋势',
        'market': '震荡',
        'win_rate': 0.68,
        'profit_ratio': 1.8,
        'real_trades': 23,
      },
      {
        'name': 'RSI超卖',
        'type': '反转',
        'market': '下跌',
        'win_rate': 0.55,
        'profit_ratio': 1.2,
        'real_trades': 17,
      },
      {
        'name': '放量突破',
        'type': '趋势',
        'market': '牛市',
        'win_rate': 0.72,
        'profit_ratio': 2.1,
        'real_trades': 31,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('策略库'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _aiStatus = _fetchAIStatus();
            _strategies = _fetchStrategies();
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI 状态卡片
            FutureBuilder<Map<String, dynamic>>(
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
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text('加载失败: ${snapshot.error}'),
                      ),
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
                            const Text('最近更新'),
                            Text(data['last_update'] ?? ''),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('右脑模型')),
                            Text(data['right_brain'] ?? ''),
                          ],
                        ),
                        Row(
                          children: [
                            const Expanded(child: Text('左脑模型')),
                            Text(data['left_brain'] ?? ''),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('今日调用'),
                            Text('${data['today_calls'] ?? 0} 次'),
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
                            const Text('模型健康度'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (data['health_score'] ?? 0) / 100,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${data['health_score'] ?? 0}%'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('学习进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ListTile(
                      leading: Icon(Icons.sync, color: Color(0xFFD4AF37)),
                      title: Text('离线训练'),
                      subtitle: Text('上次训练: 2025-03-13, 样本数: 15234'),
                      trailing: Text('就绪', style: TextStyle(color: Colors.green)),
                    ),
                    ListTile(
                      leading: Icon(Icons.storage, color: Color(0xFFD4AF37)),
                      title: Text('在线学习缓存'),
                      subtitle: Text('样本数: 87, 下次触发: 13样本后'),
                    ),
                    ListTile(
                      leading: Icon(Icons.sports_esports, color: Color(0xFFD4AF37)),
                      title: Text('红蓝军演习'),
                      subtitle: Text('上次: 2025-03-14, 生成规则: 3条'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 策略列表
            const Text('策略库', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _strategies,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败: ${snapshot.error}'));
                }
                final strategies = snapshot.data!;
                return Column(
                  children: strategies.map((s) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(s['name']),
                      subtitle: Text('${s['type']} · ${s['market']} · 实盘验证 ${s['real_trades']}次'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '胜率 ${(s['win_rate']*100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('盈亏比 ${s['profit_ratio']}'),
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