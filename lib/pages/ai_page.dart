// lib/pages/ai_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/strategy_item.dart';
import '../widgets/pending_rule_item.dart';
import '../widgets/guardian_suggestion_item.dart';
import '../widgets/arbitration_card.dart'; // 新增导入
import '../pages/brain_detail_page.dart';
import '../pages/outer_brain_center_page.dart'; // 新增导入，用于跳转

/// AI页面
/// 决策层+进化层：左右脑状态、策略库（已认证）、外脑（待验证）、守门员建议
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRightBrainExpanded = false;
  bool _isLeftBrainExpanded = false;
 
  Map<String, dynamic> _rightBrain = {};
  Map<String, dynamic> _leftBrain = {};
  List<dynamic> _strategies = [];
  List<dynamic> _pendingRules = [];
  List<dynamic> _guardianSuggestions = [];
  Map<String, dynamic> _evolutionReport = {};
  String _errorMessage = '';
 
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getRightBrainStatus(),
        ApiService.getLeftBrainStatus(),
        ApiService.getStrategies(),
        ApiService.getPendingRules(),
        ApiService.getEvolutionReport(),
        ApiService.getPendingSuggestions(),
      ]);

      if (results[0] != null && results[0] is Map<String, dynamic>) {
        _rightBrain = results[0] as Map<String, dynamic>;
      }
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        _leftBrain = results[1] as Map<String, dynamic>;
      }
      if (results[2] != null && results[2] is List) {
        _strategies = results[2] as List<dynamic>;
      }
      if (results[3] != null) {
        if (results[3] is Map<String, dynamic>) {
          final pendingMap = results[3] as Map<String, dynamic>;
          final rules = pendingMap['rules'];
          if (rules != null && rules is List) _pendingRules = rules;
        } else if (results[3] is List) {
          _pendingRules = results[3] as List<dynamic>;
        }
      }
      if (results[4] != null && results[4] is Map<String, dynamic>) {
        _evolutionReport = results[4] as Map<String, dynamic>;
      }
      if (results[5] != null) {
        if (results[5] is List) {
          _guardianSuggestions = results[5] as List<dynamic>;
        } else if (results[5] is Map<String, dynamic>) {
          final suggestionMap = results[5] as Map<String, dynamic>;
          final suggestions = suggestionMap['suggestions'];
          if (suggestions != null && suggestions is List) {
            _guardianSuggestions = suggestions;
          }
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('加载AI页面数据失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'normal':
      case 'healthy':
        return '正常';
      case 'warning':
      case 'degraded':
        return '预警';
      case 'error':
      case 'failed':
        return '异常';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
      case 'healthy':
        return Colors.green;
      case 'warning':
      case 'degraded':
        return Colors.orange;
      case 'error':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToBrainDetail(String brainType) {
    if (brainType == 'outer') {
      // 外脑跳转到外脑中心
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OuterBrainCenterPage()),
      );
    } else {
      Navigator.pushNamed(
        context,
        '/brain_detail',
        arguments: {'type': brainType},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI决策中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '策略库'),
            Tab(text: '外脑'),
            Tab(text: '守门员建议'),
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左右脑状态卡片
                      _buildBrainStatusCard(),
                      const SizedBox(height: 16),

                      // 新增：仲裁卡片
                      const ArbitrationCard(),
                      const SizedBox(height: 16),

                      // 外脑进化报告卡片（点击跳转到外脑中心）
                      _buildEvolutionReportCard(),
                      const SizedBox(height: 16),

                      // Tab内容
                      SizedBox(
                        height: 500,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStrategiesList(),
                            _buildPendingRulesList(),
                            _buildGuardianSuggestionsList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBrainStatusCard() {
    final rightStatus = _rightBrain['status'] ?? 'unknown';
    final leftStatus = _leftBrain['status'] ?? 'unknown';
    final rightSignals = _rightBrain['today_signals'] ?? 0;
    final leftDecisions = _leftBrain['today_decisions'] ?? 0;
    final rightConfidence = _rightBrain['avg_confidence'] ?? 0.5;
    final leftConfidence = _leftBrain['avg_confidence'] ?? 0.5;
    final rightModel = _rightBrain['model'] ?? _rightBrain['model_name'] ?? '未配置';
    final leftModel = _leftBrain['model'] ?? _leftBrain['model_name'] ?? '未配置';

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _navigateToBrainDetail('right'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '右脑（进攻）',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '模型: $rightModel',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '今日信号: $rightSignals | 平均置信度: ${(rightConfidence * 100).toInt()}%',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(rightStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(rightStatus),
                        style: TextStyle(
                          color: _getStatusColor(rightStatus),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _navigateToBrainDetail('left'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '左脑（风控）',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '模型: $leftModel',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '今日决策: $leftDecisions | 平均置信度: ${(leftConfidence * 100).toInt()}%',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(leftStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(leftStatus),
                        style: TextStyle(
                          color: _getStatusColor(leftStatus),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionReportCard() {
    final status = _evolutionReport['status'] ?? 'idle';
    final newRules = _evolutionReport['new_rules'] ?? 0;
    final successRate = _evolutionReport['success_rate'] ?? 0;
    final summary = _evolutionReport['summary'] ?? '';

    return GestureDetector(
      onTap: () {
        // 跳转到外脑中心
        _navigateToBrainDetail('outer');
      },
      child: Card(
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '外脑进化报告',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (status == 'running')
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem('新规则', '$newRules', Colors.orange),
                  ),
                  Expanded(
                    child: _buildMetricItem('成功率', '${(successRate * 100).toInt()}%', successRate >= 0.6 ? Colors.green : Colors.red),
                  ),
                ],
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                '更多外脑功能，请点击进入外脑中心',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategiesList() {
    if (_strategies.isEmpty) {
      return const Center(
        child: Text(
          '暂无策略',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _strategies.length,
      itemBuilder: (context, index) {
        final strategy = _strategies[index];
        return StrategyItem(
          strategy: strategy,
          onStrategyChanged: _loadData,
        );
      },
    );
  }

  Widget _buildPendingRulesList() {
    // 外脑功能已迁移到外脑中心，显示提示并跳转
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '外脑功能已迁移到外脑中心',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '请点击下方按钮查看待审核策略、IPO提醒等',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OuterBrainCenterPage()),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开外脑中心'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianSuggestionsList() {
    if (_guardianSuggestions.isEmpty) {
      return const Center(
        child: Text(
          '暂无守门员建议',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _guardianSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _guardianSuggestions[index];
        return GuardianSuggestionItem(
          suggestion: suggestion,
          onStatusChanged: _loadData,
        );
      },
    );
  }
}