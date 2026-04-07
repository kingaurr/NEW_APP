// lib/pages/system_upgrade_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

class SystemUpgradePage extends StatefulWidget {
  const SystemUpgradePage({super.key});

  @override
  State<SystemUpgradePage> createState() => _SystemUpgradePageState();
}

class _SystemUpgradePageState extends State<SystemUpgradePage> {
  bool _isLoading = true;
  Map<String, dynamic> _status = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSystemUpgradeStatus();
      if (mounted) {
        setState(() {
          _status = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performUpgrade() async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指纹验证失败，操作取消')),
      );
      return;
    }
    try {
      final result = await ApiService.systemUpgrade();
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('升级成功，请重启应用')),
        );
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('升级失败: ${result['error'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('升级异常: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统升级'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('加载失败: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentVersionCard(),
                      const SizedBox(height: 16),
                      if (_status['has_upgrade'] == true) _buildPendingUpgradeCard(),
                      if (_status['last_upgrade'] != null) _buildLastUpgradeCard(),
                      const SizedBox(height: 16),
                      _buildMetricsComparison(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentVersionCard() {
    final currentVersion = _status['current_version'] ?? 'v1.0.0';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 28),
                SizedBox(width: 8),
                Text('当前版本', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(currentVersion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('发布时间: ${_status['release_date'] ?? '未知'}', style: const TextStyle(color: Colors.grey)),
            if (_status['has_upgrade'] != true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('已是最新版本', style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUpgradeCard() {
    final pending = _status['pending_upgrade'] ?? {};
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.system_update, size: 28),
                SizedBox(width: 8),
                Text('待升级版本', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(pending['version'] ?? '未知', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('升级原因: ${pending['reason'] ?? '无'}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('预期收益: ${pending['expected_benefit'] ?? '未知'}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performUpgrade,
                icon: const Icon(Icons.upgrade),
                label: const Text('立即升级'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpgradeCard() {
    final last = _status['last_upgrade'] ?? {};
    final resultColor = last['result'] == 'success' ? Colors.green : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 28),
                SizedBox(width: 8),
                Text('最近升级', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${last['from_version']} → ${last['to_version']}', style: const TextStyle(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(last['result'] ?? '未知', style: TextStyle(color: resultColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('时间: ${last['time'] ?? '未知'}', style: const TextStyle(color: Colors.grey)),
            Text('原因: ${last['reason'] ?? '无'}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsComparison() {
    final last = _status['last_upgrade'] ?? {};
    final before = last['metrics_before'] ?? {};
    final after = last['metrics_after'] ?? {};
    if (before.isEmpty && after.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('关键指标对比', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['胜率', '盈亏比', '最大回撤'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Text(titles[value.toInt()], style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: (before['win_rate'] ?? 0).toDouble(), color: Colors.grey, width: 20),
                      BarChartRodData(toY: (after['win_rate'] ?? 0).toDouble(), color: const Color(0xFFD4AF37), width: 20),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: (before['profit_ratio'] ?? 0).toDouble() / 5, color: Colors.grey, width: 20),
                      BarChartRodData(toY: (after['profit_ratio'] ?? 0).toDouble() / 5, color: const Color(0xFFD4AF37), width: 20),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: (before['max_drawdown'] ?? 0).toDouble(), color: Colors.grey, width: 20),
                      BarChartRodData(toY: (after['max_drawdown'] ?? 0).toDouble(), color: const Color(0xFFD4AF37), width: 20),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16, height: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('升级前', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                Container(width: 16, height: 16, color: const Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text('升级后', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}