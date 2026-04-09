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
    final health = report['system_health'] ?? {};
    final infrastructure = report['infrastructure'] ?? {};
    final todos = report['todos'] ?? {};
    final trends = report['trends'] ?? {};
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
    if (health.isNotEmpty) {
      parts.add('【系统健康】心跳${health['heartbeat'] ?? ''}，模块健康分${health['module_health_score']}，数据源健康分${health['data_source_health']}。');
    }
    if (infrastructure.isNotEmpty) {
      parts.add('【基础设施】数据源切换${infrastructure['source_switches']}次，日志异常${infrastructure['log_errors']}条。');
    }
    if (todos.isNotEmpty) {
      parts.add('【待办】昨日完成${todos['yesterday_completed']}项，今日待办${todos['today_pending']}项。');
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
    final health = report['system_health'] ?? {};
    final infrastructure = report['infrastructure'] ?? {};
    final todos = report['todos'] ?? {};
    final trends = report['trends'] ?? {};
    final summary = report['summary'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 报告摘要
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

          // 系统健康度总览（新增）
          if (health.isNotEmpty) ...[
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('系统健康度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildInfoRow('心跳状态', health['heartbeat'] ?? '未知'),
                    _buildInfoRow('模块健康分', health['module_health_score']?.toString() ?? '暂无'),
                    _buildInfoRow('数据源健康分', health['data_source_health']?.toString() ?? '暂无'),
                    _buildInfoRow('网络延迟', health['network_latency_ms'] != null ? '${health['network_latency_ms']}ms' : '暂无'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 交易绩效
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
                  // 趋势对比（新增）
                  if (trends['win_rate_vs_baseline'] != null) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.grey),
                    Text('较15日基线', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    _buildInfoRow('胜率变化', trends['win_rate_vs_baseline'] != null ? '${trends['win_rate_vs_baseline'] > 0 ? '+' : ''}${(trends['win_rate_vs_baseline'] * 100).toStringAsFixed(1)}%' : '暂无'),
                    _buildInfoRow('回撤变化', trends['drawdown_vs_baseline'] != null ? '${trends['drawdown_vs_baseline'] > 0 ? '+' : ''}${(trends['drawdown_vs_baseline'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 五层池
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('五层池', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildInfoRow('交易池 (1-50)', poolStats['trade_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('影子池 (51-100)', poolStats['shadow_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('观察池 (101-250)', poolStats['watch_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('研究池 (251-500)', poolStats['research_pool']?['count']?.toString() ?? '暂无'),
                  _buildInfoRow('备选池 (501-866)', poolStats['backup_pool']?['count']?.toString() ?? '暂无'),
                  if (poolStats['trade_pool']?['avg_score'] != null) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.grey),
                    _buildInfoRow('交易池平均得分', poolStats['trade_pool']['avg_score'].toStringAsFixed(2)),
                    _buildInfoRow('跑赢基准比例', poolStats['trade_pool']['beat_benchmark_ratio'] != null ? '${(poolStats['trade_pool']['beat_benchmark_ratio'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI进化
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
                  _buildInfoRow('外脑今日产出', aiEvolution['outer_brain']?['today_generated']?.toString() ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 市场环境
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
                  _buildInfoRow('板块轮动信号', marketEnv['sector_rotation']?.join(', ') ?? '暂无'),
                  _buildInfoRow('IPO提醒', marketEnv['ipo_alerts']?.join(', ') ?? '暂无'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 数据与基础设施层（新增）
          if (infrastructure.isNotEmpty) ...[
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('基础设施', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildInfoRow('数据源切换次数', infrastructure['source_switches']?.toString() ?? '暂无'),
                    _buildInfoRow('日志异常数', infrastructure['log_errors']?.toString() ?? '暂无'),
                    _buildInfoRow('缓存命中率', infrastructure['cache_hit_rate'] != null ? '${(infrastructure['cache_hit_rate'] * 100).toStringAsFixed(1)}%' : '暂无'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 待办闭环跟踪（新增）
          if (todos.isNotEmpty) ...[
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('待办事项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildInfoRow('昨日完成', todos['yesterday_completed']?.toString() ?? '暂无'),
                    _buildInfoRow('今日待办', todos['today_pending']?.toString() ?? '暂无'),
                    if (todos['top_items'] != null && (todos['top_items'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.grey),
                      const Text('高优待办', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ...(todos['top_items'] as List).map((item) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.toString(), style: const TextStyle(color: Colors.white70))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI分析按钮
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