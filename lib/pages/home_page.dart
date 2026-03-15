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
  bool _hasAiAdvice = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 模拟数据，实际应从 ApiService 获取
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _status = {
          'mode': 'sim',
          'heart_rate': 60,
          'cpu': 12,
          'memory': 35,
          'disk': 42,
          'total_asset': 123456.78,
          'available': 65432.10,
          'position_value': 58024.68,
          'daily_profit': 1234.56,
          'trade_count': 15,
          'win_rate': 0.62,
          'max_drawdown': 0.023,
          'signal_count': 28,
          'approved_count': 19,
          'rejected_count': 9,
        };
        _alerts = ['数据源新浪财经连接超时', '内存使用率超过85%'];
        _hasAiAdvice = true;
      });
    } catch (e) {
      print('主页数据加载失败: $e');
    }
  }

  Future<void> _emergencyStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('紧急停机'),
        content: const Text('确定要停止所有交易吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // 调用 ApiService.emergencyStop()
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('停机指令已发送（模拟）')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _status['mode'] ?? 'sim';
    final heartRate = _status['heart_rate'] ?? 60;
    final cpu = _status['cpu'] ?? 0;
    final memory = _status['memory'] ?? 0;
    final disk = _status['disk'] ?? 0;
    final currentTime = DateTime.now();
    final isTradingTime = _isTradingTime(currentTime);

    final totalAsset = _status['total_asset'] ?? 0.0;
    final available = _status['available'] ?? 0.0;
    final positionValue = _status['position_value'] ?? 0.0;
    final dailyProfit = _status['daily_profit'] ?? 0.0;
    final dailyProfitPercent = totalAsset > 0 ? (dailyProfit / totalAsset) * 100 : 0.0;

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
            icon: const Icon(Icons.warning, color: Colors.red),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusChip('模式', mode, _getModeColor(mode)),
                        _buildStatusChip('心率', heartRate.toString(), heartRate > 80 ? Colors.red : Colors.green),
                        _buildStatusChip('CPU', '$cpu%', cpu > 80 ? Colors.red : Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusChip('内存', '$memory%', memory > 80 ? Colors.red : Colors.green),
                        _buildStatusChip('磁盘', '$disk%', disk > 80 ? Colors.red : Colors.green),
                        Text(
                          '${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: isTradingTime ? Colors.green : Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 资产卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('总资产', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      '¥ ${totalAsset.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('可用: ¥ ${available.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                        Text('持仓: ¥ ${positionValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '今日盈亏: ${dailyProfit >= 0 ? '+' : ''}¥ ${dailyProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: dailyProfit >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${dailyProfitPercent.toStringAsFixed(2)}%)',
                          style: TextStyle(color: dailyProfit >= 0 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 资金曲线迷你图
            Card(
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                child: _buildMiniChart(),
              ),
            ),
            const SizedBox(height: 16),

            // 今日交易摘要
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('成交', tradeCount.toString()),
                        _buildStatItem('胜率', '$winRate%'),
                        _buildStatItem('回撤', '$maxDrawdown%'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('信号', signalCount.toString()),
                        _buildStatItem('通过', approvedCount.toString()),
                        _buildStatItem('否决', rejectedCount.toString()),
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
                color: Colors.orange.shade900,
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.white),
                  title: const Text('有新的AI优化建议'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/ai_advice_center');
                  },
                ),
              ),

            // 告警滚动条
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
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_alerts[idx], style: const TextStyle(color: Colors.white)),
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
                  ),
                  ElevatedButton.icon(
                    onPressed: _emergencyStop,
                    icon: const Icon(Icons.warning),
                    label: const Text('紧急停止'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('模式切换功能待实现')),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('模式切换'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  Widget _buildMiniChart() {
    // 简单的资金曲线模拟（使用 fl_chart 的 LineChart）
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
            color: const Color(0xFFD4AF37),
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'real':
        return Colors.red;
      case 'sim':
        return Colors.green;
      case 'train':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
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