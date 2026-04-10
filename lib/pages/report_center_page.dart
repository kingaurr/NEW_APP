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
    final summary = report['summary'] ?? '';
    final asset = report['asset'] ?? {};

    final parts = <String>[];
    if (summary.isNotEmpty) parts.add('【摘要】$summary');
    if (asset.isNotEmpty) {
      parts.add('【资产】总资产${asset['total_asset']}元，今日盈亏${asset['today_pnl']}元 (${asset['today_return_pct']}%)');
    }
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

  // ===== 新增：标记待办完成 =====
  Future<void> _completeActionItem(String itemId) async {
    try {
      final success = await ApiService.completeActionItem(itemId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('待办已标记为完成'), backgroundColor: Colors.green),
        );
        // 刷新当前报告
        _loadDailyReport();
      } else {
        throw Exception('操作失败');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===== 新增：构建七大板块视图 =====
  Widget _buildReportView(Map<String, dynamic> report, String type) {
    final stats = report['stats'] ?? {};
    final poolStats = report['pool_stats'] ?? {};
    final aiEvolution = report['ai_evolution'] ?? {};
    final marketEnv = report['market_environment'] ?? {};
    final health = report['system_health'] ?? {};
    final infrastructure = report['infrastructure'] ?? {};
    final todos = report['todos'] ?? {};
    final asset = report['asset'] ?? {};
    final topStrategies = report['top_strategies'] as List<dynamic>? ?? [];
    final actionItems = report['action_items'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 板块一：实盘资产总览
          if (asset.isNotEmpty) ...[
            _buildAssetCard(asset),
            const SizedBox(height: 16),
          ],

          // 板块二：今日交易与信号执行
          _buildTradingCard(stats, aiEvolution),
          const SizedBox(height: 16),

          // 板块三：系统健康与AI状态
          _buildHealthAndAICard(health, aiEvolution),
          const SizedBox(height: 16),

          // 板块四：策略与选股运行状态（五层池 + 策略绩效）
          _buildStrategyAndPoolCard(poolStats, topStrategies),
          const SizedBox(height: 16),

          // 板块五：市场感知与风险提示
          _buildMarketCard(marketEnv),
          const SizedBox(height: 16),

          // 板块六：待办闭环跟踪
          if (actionItems.isNotEmpty || todos.isNotEmpty)
            _buildActionItemsCard(todos, actionItems),
          const SizedBox(height: 16),

          // 板块七：AI分析入口
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _analyzeReport(report, type),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('千寻AI分析'),
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

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/fund_curve'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💰 实盘资产', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAssetItem('总资产', '¥${(asset['total_asset'] ?? 0).toStringAsFixed(2)}'),
                  _buildAssetItem('可用资金', '¥${(asset['available_cash'] ?? 0).toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAssetItem('今日盈亏', '${asset['today_pnl'] >= 0 ? '+' : ''}¥${(asset['today_pnl'] ?? 0).toStringAsFixed(2)}',
                      color: (asset['today_pnl'] ?? 0) >= 0 ? Colors.green : Colors.red),
                  _buildAssetItem('收益率', '${asset['today_return_pct'] >= 0 ? '+' : ''}${(asset['today_return_pct'] ?? 0).toStringAsFixed(2)}%',
                      color: (asset['today_return_pct'] ?? 0) >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTradingCard(Map<String, dynamic> stats, Map<String, dynamic> aiEvolution) {
    final rightBrain = aiEvolution['right_brain'] ?? {};
    final leftBrain = aiEvolution['left_brain'] ?? {};
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 今日交易', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTradingItem('交易次数', stats['total_trades']?.toString() ?? '0'),
                _buildTradingItem('胜率', stats['win_rate'] != null ? '${(stats['win_rate'] * 100).toStringAsFixed(1)}%' : '-'),
                _buildTradingItem('总盈亏', '¥${(stats['total_pnl'] ?? 0).toStringAsFixed(2)}',
                    color: (stats['total_pnl'] ?? 0) >= 0 ? Colors.green : Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTradingItem('买入信号', rightBrain['buy_signals']?.toString() ?? '0'),
                _buildTradingItem('卖出信号', rightBrain['sell_signals']?.toString() ?? '0'),
                _buildTradingItem('审核通过率', leftBrain['pass_rate'] != null ? '${(leftBrain['pass_rate'] * 100).toStringAsFixed(1)}%' : '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHealthAndAICard(Map<String, dynamic> health, Map<String, dynamic> aiEvolution) {
    final arbitration = aiEvolution['arbitration'] ?? {};
    final guardian = aiEvolution['guardian'] ?? {};
    final outerBrain = aiEvolution['outer_brain'] ?? {};
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🛡️ 系统健康 & AI状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/data_source_health'),
                  child: const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatusChip('心脏', health['heartbeat'] == '正常'),
                _buildStatusChip('数据源', (health['data_source_health'] ?? 0) >= 80),
                _buildStatusChip('右脑', aiEvolution['right_brain']?['mode'] != 'error'),
                _buildStatusChip('左脑', aiEvolution['left_brain']?['mode'] != 'error'),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAIStat('仲裁冲突', arbitration['conflicts_today']?.toString() ?? '0'),
                _buildAIStat('守门员建议', guardian['suggestions_today']?.toString() ?? '0'),
                _buildAIStat('待审核规则', outerBrain['pending_rules_count']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isHealthy) {
    return Chip(
      avatar: Icon(isHealthy ? Icons.check_circle : Icons.warning, color: isHealthy ? Colors.green : Colors.orange, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      backgroundColor: Colors.white10,
    );
  }

  Widget _buildAIStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStrategyAndPoolCard(Map<String, dynamic> poolStats, List<dynamic> topStrategies) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📈 策略与选股', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/trading_signals'),
                  child: const Text('查看详情', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 五层池摘要
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildPoolChip('交易池', poolStats['trade_pool']?['count'] ?? 0),
                _buildPoolChip('影子池', poolStats['shadow_pool']?['count'] ?? 0),
                _buildPoolChip('观察池', poolStats['watch_pool']?['count'] ?? 0),
                _buildPoolChip('研究池', poolStats['research_pool']?['count'] ?? 0),
                _buildPoolChip('备选池', poolStats['backup_pool']?['count'] ?? 0),
              ],
            ),
            if (topStrategies.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              const Text('策略绩效 Top3', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              ...topStrategies.take(3).map((s) => ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2), child: Text(s['name']?.substring(0, 1) ?? 'S', style: const TextStyle(color: Color(0xFFD4AF37)))),
                title: Text(s['name'] ?? '', style: const TextStyle(color: Colors.white)),
                trailing: Text('胜率 ${((s['win_rate'] ?? 0) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.green)),
                onTap: () => Navigator.pushNamed(context, '/strategy_detail', arguments: s),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPoolChip(String label, int count) {
    return Chip(
      label: Text('$label: $count', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      backgroundColor: Colors.white10,
      onDeleted: null,
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> marketEnv) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🌍 市场感知', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/macro_events'),
                  child: const Icon(Icons.arrow_forward, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMarketItem('情绪', marketEnv['sentiment'] ?? 'neutral', marketEnv['sentiment_score'] ?? 0.5),
                _buildMarketItem('波动', marketEnv['volatility_state'] ?? 'medium', null),
                _buildMarketItem('状态', marketEnv['market_state'] ?? 'oscillation', null),
              ],
            ),
            if (marketEnv['hot_sectors'] != null && (marketEnv['hot_sectors'] as List).isNotEmpty) ...[
              const Divider(color: Colors.white24),
              const Text('热门板块', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: (marketEnv['hot_sectors'] as List).map((s) => Chip(
                  label: Text(s.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  backgroundColor: Colors.white10,
                )).toList(),
              ),
            ],
            if (marketEnv['ipo_upcoming'] != null && (marketEnv['ipo_upcoming'] as List).isNotEmpty) ...[
              const Divider(color: Colors.white24),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/ipo_list'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('IPO提醒: ${(marketEnv['ipo_upcoming'] as List).length} 只', style: const TextStyle(color: Colors.orange)),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketItem(String label, String value, double? score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (score != null) ...[
              const SizedBox(width: 4),
              Text('(${score.toStringAsFixed(2)})', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionItemsCard(Map<String, dynamic> todos, List<dynamic> actionItems) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📋 待办跟踪', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/action_history'),
                  child: const Text('历史', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTodoStat('昨日完成', todos['yesterday_completed']?.toString() ?? '0'),
                _buildTodoStat('今日待办', todos['today_pending']?.toString() ?? '0'),
              ],
            ),
            if (actionItems.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              ...actionItems.take(3).map((item) => _buildActionItemTile(item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodoStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionItemTile(Map<String, dynamic> item) {
    final priority = item['priority'] ?? 'medium';
    Color priorityColor;
    if (priority == 'high') priorityColor = Colors.red;
    else if (priority == 'medium') priorityColor = Colors.orange;
    else priorityColor = Colors.green;

    return ListTile(
      dense: true,
      leading: Container(width: 4, height: 20, color: priorityColor),
      title: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(item['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1),
      trailing: item['status'] == 'pending'
          ? ElevatedButton(
              onPressed: () => _completeActionItem(item['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text('完成', style: TextStyle(fontSize: 12)),
            )
          : const Icon(Icons.check_circle, color: Colors.green),
    );
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

    return _buildReportView(report, type);
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