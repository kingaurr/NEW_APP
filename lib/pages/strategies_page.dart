// lib/pages/strategies_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class StrategiesPage extends StatefulWidget {
  const StrategiesPage({Key? key}) : super(key: key);

  @override
  State<StrategiesPage> createState() => _StrategiesPageState();
}

class _StrategiesPageState extends State<StrategiesPage> {
  Map<String, dynamic> _aiStatus = {};
  List<dynamic> _strategies = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 模拟数据，实际应调用后端接口
      setState(() {
        _aiStatus = {
          'version': '1.2.0',
          'last_update': '2025-03-14',
          'right_brain': 'deepseek-v3',
          'left_brain': 'qwen-plus',
          'today_calls': 125,
          'total_cost': 2.35,
          'health_score': 85,
        };
        _strategies = [
          {'name': '均线突破', 'type': '趋势', 'market': '震荡', 'win_rate': 0.68, 'profit_ratio': 1.8, 'real_trades': 23},
          {'name': 'RSI超卖', 'type': '反转', 'market': '下跌', 'win_rate': 0.55, 'profit_ratio': 1.2, 'real_trades': 17},
          {'name': '放量突破', 'type': '趋势', 'market': '牛市', 'win_rate': 0.72, 'profit_ratio': 2.1, 'real_trades': 31},
        ];
      });
    } catch (e) {
      print('策略页数据加载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('策略库'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI版本', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_aiStatus['version'] ?? '未知'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('最近更新'),
                        Text(_aiStatus['last_update'] ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('右脑模型')),
                        Text(_aiStatus['right_brain'] ?? ''),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('左脑模型')),
                        Text(_aiStatus['left_brain'] ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('今日调用'),
                        Text('${_aiStatus['today_calls'] ?? 0} 次'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('累计成本'),
                        Text('¥ ${(_aiStatus['total_cost'] ?? 0).toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('模型健康度'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_aiStatus['health_score'] ?? 0) / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation(Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${_aiStatus['health_score'] ?? 0}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 学习进度卡片
            Card(
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
                      subtitle: const Text('上次训练: 2025-03-13, 样本数: 15234'),
                      trailing: const Text('就绪', style: TextStyle(color: Colors.green)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage, color: Color(0xFFD4AF37)),
                      title: const Text('在线学习缓存'),
                      subtitle: const Text('样本数: 87, 下次触发: 13样本后'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sports_esports, color: Color(0xFFD4AF37)),
                      title: const Text('红蓝军演习'),
                      subtitle: const Text('上次: 2025-03-14, 生成规则: 3条'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 策略列表
            const Text('策略库', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._strategies.map((s) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(s['name']),
                subtitle: Text('${s['type']} · ${s['market']} · 实盘验证 ${s['real_trades']}次'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('胜率 ${(s['win_rate']*100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('盈亏比 ${s['profit_ratio']}'),
                  ],
                ),
                onTap: () {
                  // 跳转到策略详情（后续实现）
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}