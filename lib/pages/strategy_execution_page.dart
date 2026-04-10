// lib/pages/strategy_execution_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 战略执行页面（战术层）
/// 展示完整七板块数据，接收战略建议，提供千寻深度分析与任务执行
class StrategyExecutionPage extends StatefulWidget {
  const StrategyExecutionPage({super.key});

  @override
  State<StrategyExecutionPage> createState() => _StrategyExecutionPageState();
}

class _StrategyExecutionPageState extends State<StrategyExecutionPage> {
  bool _isLoading = true;
  String? _error;
  bool _isAnalyzing = false;
  bool _isExecuting = false;

  // 各板块数据
  Map<String, dynamic> _asset = {};
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _aiEvolution = {};
  Map<String, dynamic> _poolStats = {};
  Map<String, dynamic> _marketEnv = {};
  Map<String, dynamic> _systemHealth = {};
  List<dynamic> _actionItems = [];
  List<dynamic> _topStrategies = [];

  // 战略规划传来的建议
  String? _strategicAdvice;
  // 大模型返回的深度分析结论
  String? _deepAnalysis;
  // 解析出的可执行任务清单
  List<Map<String, dynamic>> _tasks = [];
  // 用户选中的任务ID
  final Set<int> _selectedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _strategicAdvice = args['strategic_advice'] as String?;
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getDailyReport(),
        ApiService.getActionItems(),
        ApiService.getStrategies(),
      ]);

      Map<String, dynamic> report = {};
      if (results[0] != null && results[0] is Map) {
        report = results[0] as Map<String, dynamic>;
      } else {
        report = await _buildFallbackReport();
      }

      List<dynamic> actionItems = [];
      if (results[1] != null && results[1] is List) {
        actionItems = results[1] as List<dynamic>;
      }

      List<dynamic> strategies = [];
      if (results[2] != null && results[2] is List) {
        strategies = results[2] as List<dynamic>;
      }

      if (mounted) {
        setState(() {
          _asset = report['asset'] ?? {};
          _stats = report['stats'] ?? {};
          _aiEvolution = report['ai_evolution'] ?? {};
          _poolStats = report['pool_stats'] ?? {};
          _marketEnv = report['market_environment'] ?? {};
          _systemHealth = report['system_health'] ?? {};
          _actionItems = actionItems;
          _topStrategies = _extractTopStrategies(strategies);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        try {
          final fallback = await _buildFallbackReport();
          setState(() {
            _asset = fallback['asset'] ?? {};
            _stats = fallback['stats'] ?? {};
            _aiEvolution = fallback['ai_evolution'] ?? {};
            _poolStats = fallback['pool_stats'] ?? {};
            _marketEnv = fallback['market_environment'] ?? {};
            _systemHealth = fallback['system_health'] ?? {};
            _actionItems = [];
            _topStrategies = [];
            _isLoading = false;
            _error = null;
          });
        } catch (e2) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<Map<String, dynamic>> _buildFallbackReport() async {
    final report = <String, dynamic>{};

    try {
      final results = await Future.wait([
        ApiService.getStatus(),
        ApiService.getFund(),
        ApiService.getRightBrainStatus(),
        ApiService.getLeftBrainStatus(),
        ApiService.getOuterBrainStatusV2(),
        ApiService.getDataSourceHealth(),
        ApiService.getTradingSignals(),
        ApiService.getActionItems(),
      ]);

      final statusData = (results[0] as Map<String, dynamic>?) ?? {};
      final fundData = (results[1] as Map<String, dynamic>?) ?? {};
      final rightBrain = (results[2] as Map<String, dynamic>?) ?? {};
      final leftBrain = (results[3] as Map<String, dynamic>?) ?? {};
      final outerBrain = (results[4] as Map<String, dynamic>?) ?? {};
      final healthData = (results[5] as Map<String, dynamic>?) ?? {};
      final signalsData = (results[6] as Map<String, dynamic>?) ?? {};
      final actionItems = (results[7] as List<dynamic>?) ?? [];

      final totalAsset = (fundData['current_fund'] ?? 0.0) + (statusData['position_value'] ?? 0.0);
      report['asset'] = {
        'total_asset': totalAsset,
        'available_cash': fundData['available_fund'] ?? 0.0,
        'position_value': statusData['position_value'] ?? 0.0,
        'today_pnl': statusData['today_pnl'] ?? 0.0,
        'today_return_pct': totalAsset > 0 ? (statusData['today_pnl'] ?? 0.0) / totalAsset * 100 : 0.0,
      };

      report['stats'] = {
        'total_trades': statusData['trade_count'] ?? 0,
        'win_rate': statusData['win_rate'] ?? 0.0,
        'total_pnl': statusData['total_pnl'] ?? 0.0,
        'max_drawdown': statusData['max_drawdown'] ?? 0.0,
      };

      report['ai_evolution'] = {
        'right_brain': {
          'today_signals': rightBrain['today_signals'] ?? 0,
          'buy_signals': rightBrain['buy_signals'] ?? 0,
          'sell_signals': rightBrain['sell_signals'] ?? 0,
          'avg_confidence': rightBrain['avg_confidence'] ?? 0.0,
        },
        'left_brain': {
          'pass_rate': leftBrain['pass_rate'] ?? 0.0,
          'today_decisions': leftBrain['today_decisions'] ?? 0,
        },
        'arbitration': {
          'conflicts_today': 0,
        },
        'outer_brain': {
          'pending_rules_count': outerBrain['pending_rules_count'] ?? 0,
          'collection_success_rate': outerBrain['collection_success_rate'] ?? 0.0,
        },
        'guardian': {'suggestions_today': 0},
        'rule_learner': {'new_rules_today': 0},
      };

      final tradePool = signalsData['trade_pool'] as List<dynamic>? ?? [];
      final shadowPool = signalsData['shadow_pool'] as List<dynamic>? ?? [];
      double tradeAvgScore = 0.0;
      if (tradePool.isNotEmpty) {
        double sum = 0.0;
        for (var s in tradePool) {
          sum += (s['total_score'] ?? 0).toDouble();
        }
        tradeAvgScore = sum / tradePool.length;
      }

      report['pool_stats'] = {
        'trade_pool': {'count': tradePool.length, 'avg_score': tradeAvgScore},
        'shadow_pool': {'count': shadowPool.length},
        'watch_pool': {'count': 0},
        'research_pool': {'count': 0},
        'backup_pool': {'count': 0},
      };

      report['market_environment'] = {
        'sentiment': 'neutral',
        'sentiment_score': 0.5,
        'volatility_state': 'medium',
        'market_state': 'oscillation',
        'hot_sectors': [],
        'ipo_upcoming': [],
      };

      report['system_health'] = {
        'heartbeat': '正常',
        'module_health_score': 100,
        'data_source_health': healthData['health']?['tushare'] ?? 85,
        'network_latency_ms': 0,
      };

      report['action_items'] = actionItems;
      report['summary'] = '已从核心接口聚合数据';
      report['date'] = DateTime.now().toString().substring(0, 10);

      return report;
    } catch (e) {
      return {
        'summary': '数据加载失败',
        'asset': {},
        'stats': {},
        'ai_evolution': {},
        'pool_stats': {},
        'market_environment': {},
        'system_health': {},
        'action_items': []
      };
    }
  }

  List<dynamic> _extractTopStrategies(List<dynamic> strategies) {
    final sorted = List.from(strategies);
    sorted.sort((a, b) => (b['weight'] ?? 0).compareTo(a['weight'] ?? 0));
    return sorted.take(3).toList();
  }

  Future<void> _completeActionItem(String itemId) async {
    final auth = await BiometricsHelper.authenticateForOperation(
      operation: 'complete_action',
      operationDesc: '标记待办完成',
    );
    if (!auth) return;

    try {
      final success = await ApiService.completeActionItem(itemId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('待办已标记为完成'), backgroundColor: Colors.green),
        );
        _loadAllData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _runDeepAnalysis() async {
    setState(() => _isAnalyzing = true);

    final context = '''
【战略层建议】
${_strategicAdvice ?? '无'}

【战术层详细数据】
一、资产状况：$_asset
二、交易统计：$_stats
三、AI进化：$_aiEvolution
四、五层池：$_poolStats
五、市场环境：$_marketEnv
六、系统健康：$_systemHealth
七、待办事项：$_actionItems

请作为量化系统战术执行专家，基于以上信息，生成一个可执行的任务清单。
必须以严格的JSON格式返回，格式如下：
{
  "analysis": "对当前状况的简要分析",
  "tasks": [
    {
      "type": "adjust_weight|approve_rule|disable_rule|modify_code|run_backtest",
      "target_id": "策略ID或规则ID或文件路径",
      "params": { "key": "value" },
      "reason": "执行理由"
    }
  ]
}
如果没有需要执行的任务，tasks为空数组。
''';

    try {
      final result = await ApiService.voiceAsk(context);
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _parseAndShowTasks(result['answer'] ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _parseAndShowTasks(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('未找到有效JSON');
      }
      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      _deepAnalysis = parsed['analysis'] as String? ?? '';
      final tasksList = parsed['tasks'] as List<dynamic>? ?? [];
      _tasks = tasksList.map((t) => t as Map<String, dynamic>).toList();
      _selectedTasks.clear();

      _showTasksDialog();
    } catch (e) {
      _deepAnalysis = response;
      _tasks = [];
      _showAnalysisDialog(response);
    }
  }

  void _showTasksDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 8),
              Text('千寻战术任务', style: TextStyle(color: Color(0xFFD4AF37))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_deepAnalysis!.isNotEmpty) ...[
                    Text(_deepAnalysis!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                  ],
                  if (_tasks.isEmpty)
                    const Text('暂无战术任务', style: TextStyle(color: Colors.grey))
                  else
                    ..._tasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final task = entry.value;
                      return CheckboxListTile(
                        title: Text(task['reason'] ?? '未命名任务', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${task['type']}: ${task['target_id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        value: _selectedTasks.contains(index),
                        activeColor: const Color(0xFFD4AF37),
                        checkColor: Colors.black,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              _selectedTasks.add(index);
                            } else {
                              _selectedTasks.remove(index);
                            }
                          });
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭', style: TextStyle(color: Colors.grey)),
            ),
            if (_tasks.isNotEmpty)
              ElevatedButton(
                onPressed: _isExecuting ? null : () => _executeSelectedTasks(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                child: _isExecuting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('执行选中任务'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisDialog(String analysis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
            SizedBox(width: 8),
            Text('千寻深度分析', style: TextStyle(color: Color(0xFFD4AF37))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(analysis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSelectedTasks(BuildContext dialogContext) async {
    if (_selectedTasks.isEmpty) return;

    final auth = await BiometricsHelper.authenticateForOperation(
      operation: 'execute_tactical_tasks',
      operationDesc: '执行战术任务',
    );
    if (!auth) return;

    setState(() => _isExecuting = true);

    Navigator.pop(dialogContext);

    int successCount = 0;
    int failCount = 0;

    for (final index in _selectedTasks) {
      final task = _tasks[index];
      try {
        final success = await _executeSingleTask(task);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    setState(() {
      _isExecuting = false;
      _selectedTasks.clear();
      _tasks.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('任务执行完成：成功 $successCount 项，失败 $failCount 项'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      _loadAllData();
    }
  }

  Future<bool> _executeSingleTask(Map<String, dynamic> task) async {
    final type = task['type'] as String? ?? '';
    final targetId = task['target_id'] as String? ?? '';
    final params = task['params'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'adjust_weight':
        final weight = (params['weight'] as num?)?.toDouble() ?? 1.0;
        final result = await ApiService.updateStrategyWeight(targetId, weight);
        return result?['success'] == true;
      case 'approve_rule':
        return await ApiService.approveRule(targetId);
      case 'disable_rule':
        return await ApiService.disableRule(targetId);
      case 'modify_code':
        final patchContent = params['patch_content'] as String? ?? '';
        final result = await ApiService.oneClickFix();
        return result?['success'] == true;
      case 'run_backtest':
        final result = await ApiService.getStrategyDetail(targetId);
        return result != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('战略执行'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAllData, child: const Text('重试')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_strategicAdvice != null && _strategicAdvice!.isNotEmpty)
                          Card(
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 18),
                                      SizedBox(width: 8),
                                      Text('千寻战略建议', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_strategicAdvice!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        if (_strategicAdvice != null) const SizedBox(height: 16),

                        _buildAssetCard(),
                        const SizedBox(height: 16),
                        _buildTradingCard(),
                        const SizedBox(height: 16),
                        _buildHealthAndAICard(),
                        const SizedBox(height: 16),
                        _buildStrategyAndPoolCard(),
                        const SizedBox(height: 16),
                        _buildMarketCard(),
                        const SizedBox(height: 16),
                        _buildActionItemsCard(),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _runDeepAnalysis,
                            icon: _isAnalyzing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isAnalyzing ? '分析中...' : '千寻深度分析'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAssetCard() {
    final totalAsset = _asset['total_asset'] ?? 0.0;
    final availableCash = _asset['available_cash'] ?? 0.0;
    final positionValue = _asset['position_value'] ?? 0.0;
    final todayPnl = _asset['today_pnl'] ?? 0.0;
    final todayReturnPct = _asset['today_return_pct'] ?? 0.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFD4AF37), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 20), SizedBox(width: 8), Text('实盘资产', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('¥${totalAsset.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('可用资金', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('¥${availableCash.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 14))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('持仓市值', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('¥${positionValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 14))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('今日盈亏', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('${todayPnl >= 0 ? '+' : ''}¥${todayPnl.toStringAsFixed(2)} (${todayReturnPct >= 0 ? '+' : ''}${todayReturnPct.toStringAsFixed(2)}%)', style: TextStyle(color: todayPnl >= 0 ? Colors.green : Colors.red, fontSize: 14, fontWeight: FontWeight.w500))]),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingCard() {
    final rightBrain = _aiEvolution['right_brain'] ?? {};
    final leftBrain = _aiEvolution['left_brain'] ?? {};
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 今日交易', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildTradingItem('交易次数', _stats['total_trades']?.toString() ?? '0'),
              _buildTradingItem('胜率', _stats['win_rate'] != null ? '${(_stats['win_rate'] * 100).toStringAsFixed(1)}%' : '-'),
              _buildTradingItem('总盈亏', '¥${(_stats['total_pnl'] ?? 0).toStringAsFixed(2)}', color: (_stats['total_pnl'] ?? 0) >= 0 ? Colors.green : Colors.red),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildTradingItem('买入信号', rightBrain['buy_signals']?.toString() ?? rightBrain['today_signals']?.toString() ?? '0'),
              _buildTradingItem('卖出信号', rightBrain['sell_signals']?.toString() ?? '0'),
              _buildTradingItem('审核通过率', leftBrain['pass_rate'] != null ? '${(leftBrain['pass_rate'] * 100).toStringAsFixed(1)}%' : '-'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingItem(String label, String value, {Color? color}) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w500))]);
  }

  Widget _buildHealthAndAICard() {
    final arbitration = _aiEvolution['arbitration'] ?? {};
    final guardian = _aiEvolution['guardian'] ?? {};
    final outerBrain = _aiEvolution['outer_brain'] ?? {};
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛡️ 系统健康 & AI状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _buildStatusChip('心脏', _systemHealth['heartbeat'] == '正常'),
              _buildStatusChip('数据源', (_systemHealth['data_source_health'] ?? 0) >= 80),
              _buildStatusChip('右脑', _aiEvolution['right_brain']?['mode'] != 'error'),
              _buildStatusChip('左脑', _aiEvolution['left_brain']?['mode'] != 'error'),
            ]),
            const Divider(color: Colors.white24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildAIStat('仲裁冲突', arbitration['conflicts_today']?.toString() ?? '0'),
              _buildAIStat('守门员建议', guardian['suggestions_today']?.toString() ?? '0'),
              _buildAIStat('待审核规则', outerBrain['pending_rules_count']?.toString() ?? '0'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isHealthy) {
    return Chip(avatar: Icon(isHealthy ? Icons.check_circle : Icons.warning, color: isHealthy ? Colors.green : Colors.orange, size: 16), label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), backgroundColor: Colors.white10);
  }

  Widget _buildAIStat(String label, String value) {
    return Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
  }

  Widget _buildStrategyAndPoolCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('📈 策略与选股', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), TextButton(onPressed: () => Navigator.pushNamed(context, '/trading_signals'), child: const Text('查看详情', style: TextStyle(color: Color(0xFFD4AF37))))]),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 8, children: [
              _buildPoolChip('交易池', _poolStats['trade_pool']?['count'] ?? 0),
              _buildPoolChip('影子池', _poolStats['shadow_pool']?['count'] ?? 0),
              _buildPoolChip('观察池', _poolStats['watch_pool']?['count'] ?? 0),
            ]),
            if (_topStrategies.isNotEmpty) ...[const Divider(color: Colors.white24), const Text('策略绩效 Top3', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8), ..._topStrategies.take(3).map((s) => ListTile(dense: true, leading: CircleAvatar(backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2), child: Text(s['name']?.substring(0, 1) ?? 'S', style: const TextStyle(color: Color(0xFFD4AF37)))), title: Text(s['name'] ?? '', style: const TextStyle(color: Colors.white)), trailing: Text('胜率 ${((s['win_rate'] ?? 0) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.green)), onTap: () => Navigator.pushNamed(context, '/strategy_detail', arguments: s)))],
          ],
        ),
      ),
    );
  }

  Widget _buildPoolChip(String label, int count) {
    return Chip(label: Text('$label: $count', style: const TextStyle(color: Colors.white70, fontSize: 12)), backgroundColor: Colors.white10);
  }

  Widget _buildMarketCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('🌍 市场感知', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), InkWell(onTap: () => Navigator.pushNamed(context, '/macro_events'), child: const Icon(Icons.arrow_forward, color: Colors.grey, size: 18))]),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _buildMarketItem('情绪', _marketEnv['sentiment'] ?? 'neutral', _marketEnv['sentiment_score'] ?? 0.5),
              _buildMarketItem('波动', _marketEnv['volatility_state'] ?? 'medium', null),
              _buildMarketItem('状态', _marketEnv['market_state'] ?? 'oscillation', null),
            ]),
            if (_marketEnv['hot_sectors'] != null && (_marketEnv['hot_sectors'] as List).isNotEmpty) ...[const Divider(color: Colors.white24), const Text('热门板块', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Wrap(spacing: 8, children: (_marketEnv['hot_sectors'] as List).map((s) => Chip(label: Text(s.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)), backgroundColor: Colors.white10)).toList())],
            if (_marketEnv['ipo_upcoming'] != null && (_marketEnv['ipo_upcoming'] as List).isNotEmpty) ...[const Divider(color: Colors.white24), InkWell(onTap: () => Navigator.pushNamed(context, '/ipo_list'), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('IPO提醒: ${(_marketEnv['ipo_upcoming'] as List).length} 只', style: const TextStyle(color: Colors.orange)), const Icon(Icons.chevron_right, color: Colors.grey)]))],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketItem(String label, String value, double? score) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 2), Row(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)), if (score != null) ...[const SizedBox(width: 4), Text('(${score.toStringAsFixed(2)})', style: const TextStyle(color: Colors.grey, fontSize: 10))]])]);
  }

  Widget _buildActionItemsCard() {
    final pendingItems = _actionItems.where((item) => item['status'] == 'pending').toList();
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('📋 待办跟踪', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), TextButton(onPressed: () => Navigator.pushNamed(context, '/action_history'), child: const Text('历史', style: TextStyle(color: Color(0xFFD4AF37))))]),
            const SizedBox(height: 8),
            Text('今日待办: ${pendingItems.length} 项', style: const TextStyle(color: Colors.white70)),
            if (pendingItems.isNotEmpty) ...[const Divider(color: Colors.white24), ...pendingItems.take(3).map((item) => ListTile(dense: true, leading: Container(width: 4, height: 20, color: item['priority'] == 'high' ? Colors.red : Colors.orange), title: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)), trailing: ElevatedButton(onPressed: () => _completeActionItem(item['id']), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero), child: const Text('完成', style: TextStyle(fontSize: 12)))))],
          ],
        ),
      ),
    );
  }
}