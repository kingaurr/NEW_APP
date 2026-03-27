// lib/pages/ai_advice_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/strategy_item.dart';
import '../widgets/pending_rule_item.dart';
import '../widgets/guardian_suggestion_item.dart'; // 导入的是 suggestion (单数)
import '../widgets/evidence_viewer.dart';

/// AI优化建议中心页面
/// 整合策略库、外脑待审核规则、守门员建议、进化报告
class AiAdviceCenterPage extends StatefulWidget {
  const AiAdviceCenterPage({super.key});

  @override
  State<AiAdviceCenterPage> createState() => _AiAdviceCenterPageState();
}

class _AiAdviceCenterPageState extends State<AiAdviceCenterPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _strategies = [];
  List<dynamic> _pendingRules = [];
  List<dynamic> _guardianSuggestions = [];
  Map<String, dynamic> _evolutionReport = {};
  int _pendingCount = 0;
  int _suggestionCount = 0;
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
        ApiService.getStrategies(),
        ApiService.getPendingRules(),
        ApiService.getPendingSuggestions(),
        ApiService.getEvolutionReport(),
      ]);

      // 1. 策略列表 - 应为 List
      if (results[0] != null && results[0] is List) {
        setState(() {
          _strategies = results[0] as List<dynamic>;
        });
      }

      // 2. 待审核规则 - 后端返回 { "rules": [...] }
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        final pendingMap = results[1] as Map<String, dynamic>;
        final rules = pendingMap['rules'];
        if (rules != null && rules is List) {
          setState(() {
            _pendingRules = rules;
            _pendingCount = _pendingRules.length;
          });
        }
      }

      // 3. 守门员建议 - 后端返回 { "suggestions": [...] }
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        final suggestionMap = results[2] as Map<String, dynamic>;
        final suggestions = suggestionMap['suggestions'];
        if (suggestions != null && suggestions is List) {
          setState(() {
            _guardianSuggestions = suggestions;
            _suggestionCount = _guardianSuggestions.length;
          });
        }
      }

      // 4. 进化报告 - 应为 Map
      if (results[3] != null && results[3] is Map<String, dynamic>) {
        setState(() {
          _evolutionReport = results[3] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('加载AI中心数据失败: $e');
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
      case 'running':
        return '进化中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return '待执行';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI优化建议中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: '策略库'),
            Tab(text: '待审核规则($_pendingCount)'),
            Tab(text: '守门员建议($_suggestionCount)'),
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
              : Column(
                  children: [
                    // 进化报告卡片（在Tab上方）
                    if (_evolutionReport.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '外脑进化报告',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _evolutionReport['summary'] ?? '暂无新规则',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_evolutionReport['status'] ?? 'idle').withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(_evolutionReport['status'] ?? 'idle'),
                                    style: TextStyle(
                                      color: _getStatusColor(_evolutionReport['status'] ?? 'idle'),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Tab内容
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStrategiesTab(),
                          _buildPendingRulesTab(),
                          _buildGuardianSuggestionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStrategiesTab() {
    if (_strategies.isEmpty) {
      return const Center(
        child: Text(
          '暂无策略',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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

  Widget _buildPendingRulesTab() {
    if (_pendingRules.isEmpty) {
      return const Center(
        child: Text(
          '暂无待审核规则',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRules.length,
      itemBuilder: (context, index) {
        final rule = _pendingRules[index];
        return PendingRuleItem(
          rule: rule,
          onStatusChanged: _loadData,
        );
      },
    );
  }

  Widget _buildGuardianSuggestionsTab() {
    if (_guardianSuggestions.isEmpty) {
      return const Center(
        child: Text(
          '暂无守门员建议',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guardianSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _guardianSuggestions[index];
        // 修复点：此处类名由 GuardianSuggestionItem 改为 GuardianSuggestionItem
        return GuardianSuggestionItem(
          suggestion: suggestion,
          onStatusChanged: _loadData,
        );
      },
    );
  }
}