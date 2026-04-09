// lib/pages/report_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class ReportCenterPage extends StatefulWidget {
  const ReportCenterPage({super.key});

  @override
  State<ReportCenterPage> createState() => _ReportCenterPageState();
}

class _ReportCenterPageState extends State<ReportCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _weeklyReport;
  Map<String, dynamic>? _monthlyReport;
  bool _loadingDaily = true;
  bool _loadingWeekly = true;
  bool _loadingMonthly = true;
  String _dailyError = '';
  String _weeklyError = '';
  String _monthlyError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDailyReport();
    _loadWeeklyReport();
    _loadMonthlyReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyReport() async {
    setState(() {
      _loadingDaily = true;
      _dailyError = '';
    });
    try {
      final result = await ApiService.getDailyReportLatest();
      if (mounted) {
        final report = result?['data'] ?? result;
        setState(() {
          _dailyReport = report;
          _loadingDaily = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailyError = e.toString();
          _loadingDaily = false;
        });
      }
    }
  }

  Future<void> _loadWeeklyReport() async {
    setState(() {
      _loadingWeekly = true;
      _weeklyError = '';
    });
    try {
      final result = await ApiService.getWeeklyReportLatest();
      if (mounted) {
        final report = result?['data'] ?? result;
        setState(() {
          _weeklyReport = report;
          _loadingWeekly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weeklyError = e.toString();
          _loadingWeekly = false;
        });
      }
    }
  }

  Future<void> _loadMonthlyReport() async {
    setState(() {
      _loadingMonthly = true;
      _monthlyError = '';
    });
    try {
      final result = await ApiService.getMonthlyReportLatest();
      if (mounted) {
        final report = result?['data'] ?? result;
        setState(() {
          _monthlyReport = report;
          _loadingMonthly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _monthlyError = e.toString();
          _loadingMonthly = false;
        });
      }
    }
  }

  Future<void> _analyzeReport(Map<String, dynamic> report, String type) async {
    final stats = report['stats'] ?? {};
    final poolStats = report['pool_stats'] ?? {};
    final aiEvolution = report['ai_evolution'] ?? {};
    final marketEnv = report['market_environment'] ?? {};
    final summary = report['summary'] ?? '';

    final parts = <String>[];
    if (summary.isNotEmpty) parts.add('【摘要】$summary');
    if (stats.isNotEmpty) {
      parts.add('【交易统计】总交易${stats['total_trades']}次，胜率${stats['win_rate'] != null ? (stats['win_rate'] * 100).toStringAsFixed(1) : ''}%，总盈亏${stats['total_pnl']}元，最大回撤${stats['max_drawdown'] != null ? (stats['max_drawdown'] * 100).toStringAsFixed(1) : ''}%。');
    }
    if (poolStats.isNotEmpty) {
      parts.add('【五层池】交易池${poolStats['trade_pool']?['count']}只，观察池${poolStats['watch_pool']?['count']}只，研究池${poolStats['research_pool']?['count']}只。');
    }
    if (aiEvolution.isNotEmpty) {
      parts.add('【AI进化】右脑信号数${aiEvolution['right_brain']?['today_signals']}，左脑审核通过率${aiEvolution['left_brain']?['pass_rate'] != null ? (aiEvolution['left_brain']['pass_rate'] * 100).toStringAsFixed(1) : ''}%。');
    }
    if (marketEnv.isNotEmpty) {
      parts.add('【市场环境】情绪${marketEnv['sentiment']}，波动率${marketEnv['volatility_state']}，市场状态${marketEnv['market_state']}。');
    }

    final text = parts.isNotEmpty ? parts.join('\n') : '请分析此报告。';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('AI分析中...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final result = await ApiService.voiceAsk(text);
      if (mounted) {
        Navigator.pop(context);
        if (result['answer'] != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: Text('千寻分析报告 ($type)', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Text(
                  result['answer'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
          );
        } else {
          throw Exception('未收到分析结果');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReportCard(Map<String, dynamic>? report, String type, bool loading, String error) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (type == '日报') _loadDailyReport();
                else if (type == '周报') _loadWeeklyReport();
                else _loadMonthlyReport();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (report == null) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)));
    }

    final stats = report['stats'] ?? {};
    final poolStats = report['pool_stats'] ?? {};
    final aiEvolution = report['ai_evolution'] ?? {};
    final marketEnv = report['market_environment'] ?? {};
    final summary = report['summary'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('报告摘要', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(summary.isNotEmpty ? summary : '暂无摘要', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('交易绩效', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildInfoRow('总交易次数', stats['total_trades']?.toString() ?? '暂无'),
                  _buildInfoRow('胜率', stats['win_rate'] != null ? '${(stats['win_rate'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  _buildInfoRow('总盈亏', stats['total_pnl'] != null ? '¥${stats['total_pnl']}' : '暂无'),
                  _buildInfoRow('最大回撤', stats['max_drawdown'] != null ? '${(stats['max_drawdown'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  _buildInfoRow('夏普比率', stats['sharpe_ratio']?.toStringAsFixed(2) ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('五层池', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildInfoRow('交易池', poolStats['trade_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('影子池', poolStats['shadow_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('观察池', poolStats['watch_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('研究池', poolStats['research_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('备选池', poolStats['backup_pool']?['count']?.toString() ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI进化', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildInfoRow('右脑信号数', aiEvolution['right_brain']?['today_signals']?.toString() ?? '暂无'),
                  _buildInfoRow('左脑通过率', aiEvolution['left_brain']?['pass_rate'] != null ? '${(aiEvolution['left_brain']['pass_rate'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  _buildInfoRow('仲裁冲突数', aiEvolution['arbitration']?['conflicts_today']?.toString() ?? '暂无'),
                  _buildInfoRow('待审核规则', aiEvolution['outer_brain']?['pending_rules_count']?.toString() ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('市场环境', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildInfoRow('市场情绪', marketEnv['sentiment'] ?? '暂无'),
                  _buildInfoRow('波动率状态', marketEnv['volatility_state'] ?? '暂无'),
                  _buildInfoRow('市场状态', marketEnv['market_state'] ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _analyzeReport(report, type),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日报'),
            Tab(text: '周报'),
            Tab(text: '月报'),
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportCard(_dailyReport, '日报', _loadingDaily, _dailyError),
          _buildReportCard(_weeklyReport, '周报', _loadingWeekly, _weeklyError),
          _buildReportCard(_monthlyReport, '月报', _loadingMonthly, _monthlyError),
        ],
      ),
    );
  }
}