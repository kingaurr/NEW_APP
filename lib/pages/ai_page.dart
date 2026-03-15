// pages/ai_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class AiPage extends StatefulWidget {
  const AiPage({Key? key}) : super(key: key);

  @override
  _AiPageState createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  Future<Map<String, dynamic>?>? _aiStatusFuture;
  Future<Map<String, dynamic>?>? _learningProgressFuture;
  Future<List<dynamic>?>? _strategiesFuture;
  Future<Map<String, dynamic>?>? _warGameFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _aiStatusFuture = ApiService.getAIStatus();
      _learningProgressFuture = ApiService.getLearningProgress();
      _strategiesFuture = ApiService.getStrategies();
      _warGameFuture = ApiService.getLatestWarGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
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
                  const Text('AI 状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _aiStatusFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text('加载失败');
                      }
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          _buildInfoRow('版本', data['version'] ?? '未知'),
                          _buildInfoRow('调用次数', '${data['total_calls'] ?? 0}'),
                          _buildInfoRow('累计成本', '¥${data['total_cost']?.toStringAsFixed(2) ?? '0.00'}'),
                          _buildInfoRow('健康度', data['health'] ?? '未知'),
                        ],
                      );
                    },
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
                  const Text('学习进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _learningProgressFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text('加载失败');
                      }
                      final data = snapshot.data!;
                      final offline = data['offline'] ?? {};
                      final online = data['online'] ?? {};
                      final wargame = data['wargame'] ?? {};
                      return Column(
                        children: [
                          _buildInfoRow('离线训练时间', offline['last_train_time'] ?? '无'),
                          _buildInfoRow('离线样本数', '${offline['samples'] ?? 0}'),
                          _buildInfoRow('在线缓存数', '${online['cache_size'] ?? 0}'),
                          _buildInfoRow('演习时间', wargame['last_time'] ?? '无'),
                          _buildInfoRow('演习生成规则', '${wargame['rules_generated'] ?? 0}'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 红蓝军演习摘要卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('最近演习摘要', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _warGameFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text('加载失败');
                      }
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          _buildInfoRow('时间', data['time'] ?? '无'),
                          _buildInfoRow('生成规则数', '${data['rules_generated'] ?? 0}'),
                          _buildInfoRow('战损', '¥${data['loss']?.toStringAsFixed(2) ?? '0.00'}'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 策略列表
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('策略列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>?>(
                    future: _strategiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text('加载失败');
                      }
                      final strategies = snapshot.data!;
                      if (strategies.isEmpty) {
                        return const Text('暂无策略');
                      }
                      return Column(
                        children: strategies.map((s) => _buildStrategyItem(s)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildStrategyItem(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] ?? '未知', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('类型: ${s['type'] ?? '未知'}  |  市场: ${s['market'] ?? 'all'}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('胜率: ${_formatPercent(s['win_rate'])}'),
              Text('盈亏比: ${s['profit_ratio']?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPercent(dynamic value) {
    if (value == null) return '0%';
    if (value is num) return '${(value * 100).toStringAsFixed(0)}%';
    return '0%';
  }
}