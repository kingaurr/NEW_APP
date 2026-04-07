// lib/pages/version_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 系统版本与升级状态页面
/// 展示当前版本、待升级信息、最近升级记录、升级前后关键指标对比
class VersionPage extends StatefulWidget {
  const VersionPage({super.key});

  @override
  State<VersionPage> createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage> {
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
          const SnackBar(content: Text('升级成功，请重启应用'), backgroundColor: Colors.green),
        );
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('升级失败: ${result['error'] ?? '未知错误'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('升级异常: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统升级'),
        backgroundColor: const Color(0xFF1E1E1E),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatus,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
    final releaseDate = _status['release_date'] ?? '未知';
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 28, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text('当前版本', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(currentVersion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('发布时间: $releaseDate', style: const TextStyle(color: Colors.grey)),
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
    final version = pending['version'] ?? '未知';
    final reason = pending['reason'] ?? '无';
    final expectedBenefit = pending['expected_benefit'] ?? '未知';
    return Card(
      color: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.system_update, size: 28, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text('待升级版本', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(version, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('升级原因: $reason', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('预期收益: $expectedBenefit', style: const TextStyle(color: Colors.white70)),
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
    final fromVersion = last['from_version'] ?? '?';
    final toVersion = last['to_version'] ?? '?';
    final time = last['time'] ?? '未知';
    final reason = last['reason'] ?? '无';
    final result = last['result'] ?? 'unknown';
    final resultColor = result == 'success' ? Colors.green : Colors.red;
    final resultText = result == 'success' ? '成功' : (result == 'failed' ? '失败' : '未知');
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 28, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text('最近升级', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$fromVersion → $toVersion', style: const TextStyle(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(resultText, style: TextStyle(color: resultColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('时间: $time', style: const TextStyle(color: Colors.grey)),
            Text('原因: $reason', style: const TextStyle(color: Colors.grey)),
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

    final winRateBefore = (before['win_rate'] ?? 0.0).toDouble();
    final winRateAfter = (after['win_rate'] ?? 0.0).toDouble();
    final profitRatioBefore = (before['profit_ratio'] ?? 0.0).toDouble();
    final profitRatioAfter = (after['profit_ratio'] ?? 0.0).toDouble();
    final drawdownBefore = (before['max_drawdown'] ?? 0.0).toDouble();
    final drawdownAfter = (after['max_drawdown'] ?? 0.0).toDouble();

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('关键指标对比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      BarChartRodData(toY: winRateBefore, color: Colors.grey, width: 20),
                      BarChartRodData(toY: winRateAfter, color: const Color(0xFFD4AF37), width: 20),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: profitRatioBefore.clamp(0.0, 5.0) / 5.0, color: Colors.grey, width: 20),
                      BarChartRodData(toY: profitRatioAfter.clamp(0.0, 5.0) / 5.0, color: const Color(0xFFD4AF37), width: 20),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: drawdownBefore, color: Colors.grey, width: 20),
                      BarChartRodData(toY: drawdownAfter, color: const Color(0xFFD4AF37), width: 20),
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