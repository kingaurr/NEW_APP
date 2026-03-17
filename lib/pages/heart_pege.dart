// pages/heart_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class HeartPage extends StatefulWidget {
  const HeartPage({Key? key}) : super(key: key);

  @override
  _HeartPageState createState() => _HeartPageState();
}

class _HeartPageState extends State<HeartPage> {
  late Future<Map<String, dynamic>?> _heartSummaryFuture;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 定时刷新，每5秒
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _heartSummaryFuture = ApiService.getHeartSummary();
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
          FutureBuilder<Map<String, dynamic>?>(
            future: _heartSummaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    '加载失败: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                );
              }
              final data = snapshot.data!;
              return Column(
                children: [
                  // 系统心跳卡片
                  _buildHeartbeatCard(theme, data),
                  const SizedBox(height: 16),
                  // 熔断状态卡片
                  _buildFuseCard(theme, data),
                  const SizedBox(height: 16),
                  // 资金成本卡片
                  _buildCostCard(theme, data),
                  const SizedBox(height: 16),
                  // 数据源健康卡片
                  _buildDataSourceCard(theme, data),
                  const SizedBox(height: 16),
                  // 选股池快照
                  _buildPoolsCard(theme, data),
                  const SizedBox(height: 16),
                  // 左右脑状态快照
                  _buildBrainStatusRow(theme, data),
                  const SizedBox(height: 16),
                  // 最新报告摘要 + 待处理建议数
                  _buildReportAndAdviceRow(theme, data),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeartbeatCard(ThemeData theme, Map<String, dynamic> data) {
    final system = data['system'] ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, '系统心跳'),
            const SizedBox(height: 12),
            _infoRow(theme, '模式', _capitalize(system['mode'] ?? 'sim')),
            _infoRow(theme, '心率', '${system['heart_rate'] ?? 60} bpm'),
            _infoRow(theme, '紧急停止', system['emergency_stop'] == true ? '是' : '否'),
          ],
        ),
      ),
    );
  }

  Widget _buildFuseCard(ThemeData theme, Map<String, dynamic> data) {
    final fuse = data['fuse'] ?? {};
    final triggered = fuse['triggered'] == true;
    final severity = fuse['severity'] ?? 0;
    final remaining = fuse['remaining_minutes'] ?? 0;

    Color statusColor;
    if (!triggered) {
      statusColor = theme.colorScheme.primary;
    } else if (severity >= 3) {
      statusColor = theme.colorScheme.error;
    } else {
      statusColor = theme.colorScheme.secondary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, '熔断状态'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  triggered ? '已触发' : '正常',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: triggered ? statusColor : theme.colorScheme.primary,
                  ),
                ),
                if (triggered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '严重度 $severity',
                      style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                    ),
                  ),
              ],
            ),
            if (triggered) ...[
              const SizedBox(height: 8),
              Text(
                fuse['reason'] ?? '未知原因',
                style: theme.textTheme.bodyMedium,
              ),
              if (remaining > 0)
                Text(
                  '剩余解除时间: $remaining 分钟',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(ThemeData theme, Map<String, dynamic> data) {
    final cost = data['cost'] ?? {};
    final status = cost['status'] ?? 'normal';
    String statusText;
    Color statusColor;
    switch (status) {
      case 'halt':
        statusText = '熔断';
        statusColor = theme.colorScheme.error;
        break;
      case 'tight':
        statusText = '紧张';
        statusColor = theme.colorScheme.secondary;
        break;
      default:
        statusText = '正常';
        statusColor = theme.colorScheme.primary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle(theme, '资金成本'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(theme, '今日成本', '¥${cost['today']?.toStringAsFixed(2) ?? '0.00'}'),
            _infoRow(theme, '本月成本', '¥${cost['month']?.toStringAsFixed(2) ?? '0.00'}'),
            _infoRow(theme, '预算', '¥${cost['budget']?.toStringAsFixed(2) ?? '0.00'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceCard(ThemeData theme, Map<String, dynamic> data) {
    final ds = data['data_source'] ?? {};
    final current = ds['current'] ?? 'unknown';
    final health = ds['health'] as Map<String, dynamic>? ?? {};
    final tushareHealth = health['tushare'] as Map<String, dynamic>? ?? {};
    final healthScore = tushareHealth['health_score'] ?? 0;

    Color scoreColor = theme.colorScheme.primary;
    if (healthScore < 60) {
      scoreColor = theme.colorScheme.error;
    } else if (healthScore < 80) {
      scoreColor = theme.colorScheme.secondary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, '数据源健康'),
            const SizedBox(height: 12),
            _infoRow(theme, '当前数据源', _capitalize(current)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('健康分'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$healthScore',
                    style: theme.textTheme.bodySmall?.copyWith(color: scoreColor),
                  ),
                ),
              ],
            ),
            _infoRow(theme, '连续失败', '${tushareHealth['consecutive_failures'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolsCard(ThemeData theme, Map<String, dynamic> data) {
    final pools = data['pools'] ?? {};
    final tradePool = pools['trade_pool'] as List? ?? [];
    final shadowPool = pools['shadow_pool'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, '选股池快照'),
            const SizedBox(height: 12),
            _poolSection(theme, '交易池', tradePool, showScore: true),
            const Divider(height: 24),
            _poolSection(theme, '影子池', shadowPool, showScore: false),
          ],
        ),
      ),
    );
  }

  Widget _poolSection(ThemeData theme, String title, List pool, {bool showScore = true}) {
    if (pool.isEmpty) {
      return Center(
        child: Text(
          '暂无$title',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...pool.take(5).map((item) {
          if (item is Map) {
            final code = item['code'] ?? '未知';
            final score = item['score'] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(code, style: theme.textTheme.bodyMedium),
                  if (showScore)
                    Text(
                      '得分: ${score.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(item.toString()),
          );
        }),
      ],
    );
  }

  Widget _buildBrainStatusRow(ThemeData theme, Map<String, dynamic> data) {
    final right = data['right_brain'] ?? {};
    final left = data['left_brain'] ?? {};
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('右脑', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _infoRow(theme, '模式', _capitalize(right['mode'] ?? 'unknown')),
                  _infoRow(theme, '模型', right['model'] ?? '-'),
                  if (right['last_call'] != null && right['last_call'] != 0)
                    _infoRow(theme, '最后调用', _formatTime(right['last_call'])),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('左脑', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _infoRow(theme, '模式', _capitalize(left['mode'] ?? 'unknown')),
                  _infoRow(theme, '模型', left['model'] ?? '-'),
                  _infoRow(theme, '熔断', left['fuse_triggered'] == true ? '是' : '否'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportAndAdviceRow(ThemeData theme, Map<String, dynamic> data) {
    final latestReport = data['latest_report'] as Map<String, dynamic>? ?? {};
    final pendingCount = data['pending_advice_count'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最新日报', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (latestReport.isNotEmpty) ...[
                    Text(
                      latestReport['date'] ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    if (latestReport['health_score'] != null)
                      _infoRow(theme, '健康评分', '${latestReport['health_score']}'),
                    if (latestReport['strategy_score'] != null)
                      _infoRow(theme, '策略评分', '${latestReport['strategy_score']}'),
                    if (latestReport['risk_status'] != null)
                      _infoRow(theme, '风险状态', _capitalize(latestReport['risk_status'])),
                  ] else ...[
                    Text('暂无报告', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('待处理建议', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '$pendingCount',
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 辅助 Widget
  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  String _formatTime(num timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    final now = DateTime.now();
    if (dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}-${dt.day} ${dt.hour}:${dt.minute}';
  }
}