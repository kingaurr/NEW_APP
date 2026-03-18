// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _status = {};
  List<String> _alerts = [];
  bool _hasAiAdvice = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final status = await ApiService.getStatus();
      if (status != null) {
        setState(() {
          _status = status;
        });
      }
      final alerts = await ApiService.getAlerts();
      setState(() {
        _alerts = alerts;
      });
      final hasAdvice = await ApiService.hasNewAiAdvice();
      setState(() {
        _hasAiAdvice = hasAdvice;
      });
    } catch (e) {
      debugPrint('主页数据加载失败: $e');
    }
  }

  Future<void> _emergencyStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).dialogBackgroundColor,
        title: Text('紧急停机', style: Theme.of(ctx).textTheme.titleMedium),
        content: const Text('确定要停止所有交易吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      const emergencyToken = 'change_me_in_prod';
      final response = await ApiService.httpPost(
        '/emergency_stop',
        body: {'reason': '用户手动触发'},
        headers: {'X-Emergency-Token': emergencyToken},
      );
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('紧急停止指令已发送'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: ${response?['error'] ?? '未知错误'}'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = _status['mode'] ?? 'sim';
    final heartRate = _status['heart_rate'] ?? 60;
    final cpu = _status['cpu_percent'] ?? 0;
    final memory = _status['memory_percent'] ?? 0;
    final disk = _status['disk_usage'] ?? 0;
    final currentTime = DateTime.now();
    final isTradingTime = _isTradingTime(currentTime);

    // 实盘资金
    final realFund = _status['fund'] ?? 0.0;
    final realAvailable = _status['available_fund'] ?? 0.0;
    final realPosition = _status['position_value'] ?? 0.0;

    // 模拟资金
    final simFund = _status['sim_fund'] ?? 0.0;
    final simAvailable = _status['sim_available'] ?? 0.0;
    final simPosition = _status['sim_position'] ?? 0.0;

    final dailyProfit = _status['today_pnl'] ?? 0.0;
    final dailyProfitPercent = realFund > 0 ? (dailyProfit / realFund) * 100 : 0.0;

    final tradeCount = _status['trade_count'] ?? 0;
    final winRate = ((_status['win_rate'] ?? 0) * 100).toStringAsFixed(1);
    final maxDrawdown = ((_status['max_drawdown'] ?? 0) * 100).toStringAsFixed(1);
    final signalCount = _status['signal_count'] ?? 0;
    final approvedCount = _status['approved_count'] ?? 0;
    final rejectedCount = _status['rejected_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            icon: Icon(Icons.warning, color: theme.colorScheme.error),
            onPressed: _emergencyStop,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 顶部状态栏
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusChip(theme, '模式', mode, _getModeColor(theme, mode)),
                        _buildStatusChip(theme, '心率', heartRate.toString(), heartRate > 80 ? theme.colorScheme.error : theme.colorScheme.primary),
                        _buildStatusChip(theme, 'CPU', '$cpu%', cpu > 80 ? theme.colorScheme.error : theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusChip(theme, '内存', '$memory%', memory > 80 ? theme.colorScheme.error : theme.colorScheme.primary),
                        _buildStatusChip(theme, '磁盘', '$disk%', disk > 80 ? theme.colorScheme.error : theme.colorScheme.primary),
                        Text(
                          '${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isTradingTime ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 实盘资产卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('实盘资产', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      '¥ ${realFund.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('可用: ¥ ${realAvailable.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                        Text('持仓: ¥ ${realPosition.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 模拟资产卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('模拟资产', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      '¥ ${simFund.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('可用: ¥ ${simAvailable.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                        Text('持仓: ¥ ${simPosition.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    if (simFund == 0.0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '注：模拟资金尚未加载，请检查后端配置',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 资金曲线迷你图
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                child: _buildMiniChart(theme),
              ),
            ),
            const SizedBox(height: 16),

            // 今日交易摘要
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(theme, '成交', tradeCount.toString()),
                        _buildStatItem(theme, '胜率', '$winRate%'),
                        _buildStatItem(theme, '回撤', '$maxDrawdown%'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(theme, '信号', signalCount.toString()),
                        _buildStatItem(theme, '通过', approvedCount.toString()),
                        _buildStatItem(theme, '否决', rejectedCount.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI优化建议提醒
            if (_hasAiAdvice)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: theme.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(Icons.lightbulb, color: theme.colorScheme.onSecondaryContainer),
                  title: Text('有新的AI优化建议', style: theme.textTheme.bodyLarge),
                  trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSecondaryContainer),
                  onTap: () {
                    Navigator.pushNamed(context, '/ai_advice_center');
                  },
                ),
              ),

            // 告警滚动条（仅当有告警时显示）
            if (_alerts.isNotEmpty)
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _alerts.length,
                  itemBuilder: (ctx, idx) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _alerts[idx],
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ),

            // 快捷操作栏
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _emergencyStop,
                    icon: const Icon(Icons.warning),
                    label: const Text('紧急停止'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('模式切换功能待实现'),
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('模式切换'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildMiniChart(ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 1),
              FlSpot(1, 1.2),
              FlSpot(2, 1.1),
              FlSpot(3, 1.3),
              FlSpot(4, 1.25),
              FlSpot(5, 1.4),
              FlSpot(6, 1.35),
            ],
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(ThemeData theme, String mode) {
    switch (mode) {
      case 'real':
        return theme.colorScheme.error;
      case 'sim':
        return theme.colorScheme.primary;
      case 'train':
        return theme.colorScheme.secondary;
      case 'maintenance':
        return theme.colorScheme.tertiary ?? Colors.orange;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  bool _isTradingTime(DateTime now) {
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) return false;
    final hour = now.hour;
    final minute = now.minute;
    final timeValue = hour * 100 + minute;
    return (timeValue >= 930 && timeValue <= 1130) || (timeValue >= 1300 && timeValue <= 1500);
  }
}