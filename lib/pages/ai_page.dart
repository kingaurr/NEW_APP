// pages/ai_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'right_brain_page.dart';
import 'left_brain_page.dart';

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
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 右脑状态卡片（可点击跳转）
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RightBrainPage()),
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '右脑状态',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _aiStatusFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return Text(
                            '加载失败',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          );
                        }
                        final data = snapshot.data!;
                        return Column(
                          children: [
                            _buildInfoRow(theme, '模式', data['mode'] ?? '未知'),
                            _buildInfoRow(theme, '模型', data['model'] ?? '未知'),
                            _buildInfoRow(theme, '调用次数', '${data['total_calls'] ?? 0}'),
                            _buildInfoRow(theme, '累计成本', '¥${data['total_cost']?.toStringAsFixed(2) ?? '0.00'}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 左脑状态卡片（可点击跳转）
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeftBrainPage()),
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '左脑状态',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _aiStatusFuture, // 实际应替换为左脑专用接口，暂用同一数据
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return Text(
                            '加载失败',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          );
                        }
                        final data = snapshot.data!;
                        return Column(
                          children: [
                            _buildInfoRow(theme, '模式', data['mode'] ?? '未知'),
                            _buildInfoRow(theme, '模型', data['model'] ?? '未知'),
                            _buildInfoRow(theme, '熔断', data['fuse_triggered'] == true ? '已触发' : '正常'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 学习进度卡片
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学习进度',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _learningProgressFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Text(
                          '加载失败',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        );
                      }
                      final data = snapshot.data!;
                      final offline = data['offline'] ?? {};
                      final online = data['online'] ?? {};
                      final wargame = data['wargame'] ?? {};
                      return Column(
                        children: [
                          _buildInfoRow(theme, '离线训练时间', offline['last_train_time'] ?? '无'),
                          _buildInfoRow(theme, '离线样本数', '${offline['samples'] ?? 0}'),
                          _buildInfoRow(theme, '在线缓存数', '${online['cache_size'] ?? 0}'),
                          _buildInfoRow(theme, '演习时间', wargame['last_time'] ?? '无'),
                          _buildInfoRow(theme, '演习生成规则', '${wargame['rules_generated'] ?? 0}'),
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最近演习摘要',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _warGameFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Text(
                          '加载失败',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        );
                      }
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          _buildInfoRow(theme, '时间', data['time'] ?? '无'),
                          _buildInfoRow(theme, '生成规则数', '${data['rules_generated'] ?? 0}'),
                          _buildInfoRow(theme, '战损', '¥${data['loss']?.toStringAsFixed(2) ?? '0.00'}'),
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '策略列表',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>?>(
                    future: _strategiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Text(
                          '加载失败',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        );
                      }
                      final strategies = snapshot.data!;
                      if (strategies.isEmpty) {
                        return Center(
                          child: Text(
                            '暂无策略',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        );
                      }
                      return Column(
                        children: strategies.map((s) => _buildStrategyItem(theme, s)).toList(),
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

  Widget _buildStrategyItem(ThemeData theme, Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name'] ?? '未知',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '类型: ${s['type'] ?? '未知'}  |  市场: ${s['market'] ?? 'all'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '胜率: ${_formatPercent(s['win_rate'])}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '盈亏比: ${s['profit_ratio']?.toStringAsFixed(2) ?? '0.00'}',
                style: theme.textTheme.bodyMedium,
              ),
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