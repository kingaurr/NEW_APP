// pages/system_monitor_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({Key? key}) : super(key: key);

  @override
  _SystemMonitorPageState createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getSystemMonitor();
      if (data == null) {
        setState(() => _error = '加载失败');
      } else {
        setState(() => _data = data);
      }
    } catch (e) {
      setState(() => _error = '异常: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统实时监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 资源卡片
                      _buildResourceSection(theme),
                      const SizedBox(height: 16),
                      // 模块健康卡片
                      _buildModuleHealthSection(theme),
                      const SizedBox(height: 16),
                      // 策略表现卡片
                      _buildStrategySection(theme),
                      const SizedBox(height: 16),
                      // 成本卡片
                      _buildCostSection(theme),
                      const SizedBox(height: 16),
                      // 事件流卡片
                      _buildEventsSection(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResourceSection(ThemeData theme) {
    final resources = _data?['resources'] ?? {};
    final cpu = resources['cpu'] ?? {};
    final memory = resources['memory'] ?? {};
    final disk = resources['disk'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统资源',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResourceRow(theme, 'CPU', cpu['percent'] ?? 0, cpu['history']),
            const SizedBox(height: 8),
            _buildResourceRow(theme, '内存', memory['percent'] ?? 0, memory['history']),
            const SizedBox(height: 8),
            _buildResourceRow(theme, '磁盘', disk['percent'] ?? 0, null, showGraph: false),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceRow(ThemeData theme, String label, double percent, List? history, {bool showGraph = true}) {
    final color = percent > 80 ? theme.colorScheme.error : (percent > 60 ? theme.colorScheme.secondary : theme.colorScheme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text('${percent.toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        if (showGraph && history != null && history.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModuleHealthSection(ThemeData theme) {
    final health = _data?['module_health'] as Map? ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '模块健康度',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...health.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatModuleName(e.key),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _healthColor(e.value).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${e.value}分',
                      style: theme.textTheme.bodySmall?.copyWith(color: _healthColor(e.value)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _healthColor(dynamic score) {
    if (score is! num) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatModuleName(String key) {
    switch (key) {
      case 'heart': return '心脏';
      case 'data_source': return '数据源';
      case 'right_brain': return '右脑';
      case 'left_brain': return '左脑';
      case 'order_manager': return '订单管理器';
      default: return key;
    }
  }

  Widget _buildStrategySection(ThemeData theme) {
    final strategy = _data?['strategy'] as Map? ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '策略实时表现',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, '总盈亏', '¥${(strategy['total_pnl'] ?? 0).toStringAsFixed(2)}',
                valueColor: (strategy['total_pnl'] ?? 0) >= 0 ? theme.colorScheme.primary : theme.colorScheme.error),
            _buildInfoRow(theme, '胜率', '${(strategy['win_rate'] * 100).toStringAsFixed(0)}%'),
            _buildInfoRow(theme, '夏普比率', (strategy['sharpe'] ?? 0).toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSection(ThemeData theme) {
    final cost = _data?['cost'] as Map? ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '成本监控',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, '今日成本', '¥${cost['today']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildInfoRow(theme, '本月成本', '¥${cost['month']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildInfoRow(theme, '预算', '¥${cost['budget']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildInfoRow(theme, '剩余', '¥${cost['remaining']?.toStringAsFixed(2) ?? '0.00'}',
                valueColor: (cost['remaining'] ?? 0) > 0 ? theme.colorScheme.primary : theme.colorScheme.error),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(ThemeData theme) {
    final events = _data?['events'] as List? ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '事件流',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Center(
                child: Text(
                  '暂无事件',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) {
                  final e = events[idx];
                  final type = e['type'] ?? 'info';
                  final color = type == 'error' ? theme.colorScheme.error :
                                (type == 'warning' ? theme.colorScheme.secondary : theme.colorScheme.primary);
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['message'] ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              _formatTime(e['time']),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}';
  }
}