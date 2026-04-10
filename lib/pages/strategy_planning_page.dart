// lib/pages/strategy_planning_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 战略规划页面
/// 展示四大核心模块（心脏、左脑、右脑、外脑）状态 + 实盘资产
/// 提供千寻战略评估入口，分析结论可传递给战略执行页面
class StrategyPlanningPage extends StatefulWidget {
  const StrategyPlanningPage({super.key});

  @override
  State<StrategyPlanningPage> createState() => _StrategyPlanningPageState();
}

class _StrategyPlanningPageState extends State<StrategyPlanningPage> {
  bool _isLoading = true;
  String? _error;
  bool _isAnalyzing = false;

  // 四大核心模块状态
  Map<String, dynamic> _heartStatus = {};
  Map<String, dynamic> _rightBrainStatus = {};
  Map<String, dynamic> _leftBrainStatus = {};
  Map<String, dynamic> _outerBrainStatus = {};

  // 资产与系统状态
  Map<String, dynamic> _fundData = {};
  Map<String, dynamic> _statusData = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getHeartSummary(),
        ApiService.getRightBrainStatus(),
        ApiService.getLeftBrainStatus(),
        ApiService.getOuterBrainStatusV2(),
        ApiService.getFund(),
        ApiService.getStatus(),
      ]);

      if (mounted) {
        setState(() {
          _heartStatus = (results[0] as Map<String, dynamic>?) ?? {};
          _rightBrainStatus = (results[1] as Map<String, dynamic>?) ?? {};
          _leftBrainStatus = (results[2] as Map<String, dynamic>?) ?? {};
          _outerBrainStatus = (results[3] as Map<String, dynamic>?) ?? {};
          _fundData = (results[4] as Map<String, dynamic>?) ?? {};
          _statusData = (results[5] as Map<String, dynamic>?) ?? {};
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

  Future<void> _runStrategicAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    // 构建战略分析上下文
    final context = '''
【战略规划上下文】
一、核心大脑状态
- 心脏：模式=${_heartStatus['system']?['mode'] ?? '未知'}，熔断=${_heartStatus['fuse']?['triggered'] == true ? '已触发' : '正常'}
- 右脑：模式=${_rightBrainStatus['mode'] ?? '未知'}，今日信号=${_rightBrainStatus['today_signals'] ?? 0}，置信度=${_rightBrainStatus['avg_confidence'] ?? 0}
- 左脑：模式=${_leftBrainStatus['mode'] ?? '未知'}，审核通过率=${_leftBrainStatus['pass_rate'] != null ? (_leftBrainStatus['pass_rate'] * 100).toStringAsFixed(1) : '0'}%
- 外脑：待审核规则=${_outerBrainStatus['pending_rules_count'] ?? 0}，采集成功率=${_outerBrainStatus['collection_success_rate'] != null ? (_outerBrainStatus['collection_success_rate'] * 100).toStringAsFixed(1) : '0'}%

二、资产状况
- 总资产：¥${(_fundData['current_fund'] ?? 0) + (_statusData['position_value'] ?? 0)}
- 今日盈亏：¥${_statusData['today_pnl'] ?? 0}
- 胜率：${_statusData['win_rate'] != null ? (_statusData['win_rate'] * 100).toStringAsFixed(1) : '0'}%

请作为Quant 4.0战略分析师，完成以下任务：
1. 评估四大核心模块是否健康运行。
2. 给出一句话战略总结（不超过100字）。
3. 如果有需要优化的问题，生成一个可执行的战术任务清单，格式为：
   - [ ] 任务类型: 具体操作 (例如: 调整策略权重、批准规则、检查数据源)
如果系统运行完美，则写"无需战术任务"。
''';

    try {
      final result = await ApiService.voiceAsk(context);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showAnalysisDialog(result['answer'] ?? '暂无分析结果');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
            Text('千寻战略评估', style: TextStyle(color: Color(0xFFD4AF37))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            analysis,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 跳转到战略执行页面，携带分析结论
              Navigator.pushNamed(
                context,
                '/strategy_execution',
                arguments: {
                  'strategic_advice': analysis,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('去战略执行'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('战略规划'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
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
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: const Text('重试'),
                      ),
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
                        // 资产卡片
                        _buildAssetCard(),
                        const SizedBox(height: 16),
                        // 四大核心模块标题
                        const Text(
                          '核心大脑',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 心脏卡片
                        _buildHeartCard(),
                        const SizedBox(height: 12),
                        // 右脑卡片
                        _buildRightBrainCard(),
                        const SizedBox(height: 12),
                        // 左脑卡片
                        _buildLeftBrainCard(),
                        const SizedBox(height: 12),
                        // 外脑卡片
                        _buildOuterBrainCard(),
                        const SizedBox(height: 24),
                        // 千寻战略评估按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _runStrategicAnalysis,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isAnalyzing ? '分析中...' : '千寻战略评估'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 查看详细报告入口（直接跳转，不携带分析结论）
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/strategy_execution'),
                            icon: const Icon(Icons.analytics, size: 18),
                            label: const Text('查看详细报告'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ========== UI 构建方法 ==========
  Widget _buildAssetCard() {
    final totalAsset = (_fundData['current_fund'] ?? 0.0) + (_statusData['position_value'] ?? 0.0);
    final todayPnl = _statusData['today_pnl'] ?? 0.0;
    final winRate = _statusData['win_rate'] ?? 0.0;
    final positionRatio = totalAsset > 0 ? (_statusData['position_value'] ?? 0.0) / totalAsset : 0.0;

    return Card(
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
                Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 20),
                SizedBox(width: 8),
                Text(
                  '实盘资产',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '¥${totalAsset.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日盈亏', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${todayPnl >= 0 ? '+' : ''}¥${todayPnl.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: todayPnl >= 0 ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('胜率', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${(winRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('仓位比例', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    Text(
                      '${(positionRatio * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: positionRatio,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          positionRatio > 0.8 ? Colors.orange : Colors.green,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartCard() {
    final mode = _heartStatus['system']?['mode'] ?? 'sim';
    final fuseTriggered = _heartStatus['fuse']?['triggered'] ?? false;
    final costToday = _heartStatus['cost']?['today'] ?? 0.0;
    final monthlyBudget = _heartStatus['cost']?['budget'] ?? 200.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: fuseTriggered ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '心脏',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: mode == 'real' ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mode == 'real' ? '实盘' : '模拟',
                    style: TextStyle(
                      color: mode == 'real' ? Colors.red : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('熔断状态', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  fuseTriggered ? '已触发' : '正常',
                  style: TextStyle(
                    color: fuseTriggered ? Colors.red : Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日成本', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '¥${costToday.toStringAsFixed(2)} / ¥${monthlyBudget.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightBrainCard() {
    final mode = _rightBrainStatus['mode'] ?? 'unknown';
    final todaySignals = _rightBrainStatus['today_signals'] ?? 0;
    final avgConfidence = _rightBrainStatus['avg_confidence'] ?? 0.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '右脑',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: mode == 'api' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mode.toUpperCase(),
                    style: TextStyle(
                      color: mode == 'api' ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日信号', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '$todaySignals 个',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('平均置信度', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftBrainCard() {
    final mode = _leftBrainStatus['mode'] ?? 'unknown';
    final fuseTriggered = _leftBrainStatus['fuse_triggered'] ?? false;
    final todayDecisions = _leftBrainStatus['today_decisions'] ?? 0;
    final passRate = _leftBrainStatus['pass_rate'] ?? 0.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '左脑',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (fuseTriggered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '熔断中',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日审核', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '$todayDecisions 次',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('通过率', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${(passRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: passRate >= 0.6 ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterBrainCard() {
    final pendingRules = _outerBrainStatus['pending_rules_count'] ?? 0;
    final collectionRate = _outerBrainStatus['collection_success_rate'] ?? 0.0;
    final status = _outerBrainStatus['status'] ?? 'idle';

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_books, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '外脑',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'completed' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status == 'completed' ? '已更新' : '待更新',
                    style: TextStyle(
                      color: status == 'completed' ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('待审核规则', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '$pendingRules 条',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('采集成功率', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${(collectionRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}