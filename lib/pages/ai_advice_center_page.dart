// lib/pages/ai_advice_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/strategy_item.dart';
import '../widgets/pending_rule_item.dart';
import '../widgets/guardian_suggestion_item.dart' as guardian;

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
  List<dynamic> _codeFixSuggestions = []; // 新增：代码修改建议
  Map<String, dynamic> _evolutionReport = {};
  int _pendingCount = 0;
  int _suggestionCount = 0;
  int _codeFixCount = 0; // 新增
  String _errorMessage = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 改为4个Tab
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    List<dynamic> strategies = [];
    List<dynamic> pendingRules = [];
    List<dynamic> guardianSuggestions = [];
    List<dynamic> codeFixSuggestions = [];
    Map<String, dynamic> evolutionReport = {};

    // 1. 策略列表
    try {
      final result = await ApiService.getStrategies();
      if (result != null && result is List) {
        strategies = result;
      }
    } catch (e) {
      debugPrint('getStrategies 错误: $e');
      _showErrorSnackbar('策略列表加载失败');
    }

    // 2. 待审核规则（外脑规则）
    try {
      final result = await ApiService.getPendingRules();
      if (result != null && result is List) {
        pendingRules = result;
      }
    } catch (e) {
      debugPrint('getPendingRules 错误: $e');
      _showErrorSnackbar('待审核规则加载失败');
    }

    // 3. 守门员建议（普通建议）
    try {
      final result = await ApiService.getPendingSuggestions();
      if (result != null && result is List) {
        guardianSuggestions = result;
      }
    } catch (e) {
      debugPrint('getPendingSuggestions 错误: $e');
      _showErrorSnackbar('守门员建议加载失败');
    }

    // 4. 代码修改建议（type=code_fix）
    try {
      final result = await ApiService.getPendingAdviceByType('code_fix');
      if (result != null && result is List) {
        codeFixSuggestions = result;
      }
    } catch (e) {
      debugPrint('getPendingAdviceByType(code_fix) 错误: $e');
      _showErrorSnackbar('代码修改建议加载失败');
    }

    // 5. 进化报告
    try {
      final result = await ApiService.getEvolutionReport();
      if (result != null && result is Map<String, dynamic>) {
        evolutionReport = result;
      }
    } catch (e) {
      debugPrint('getEvolutionReport 错误: $e');
      _showErrorSnackbar('进化报告加载失败');
    }

    setState(() {
      _strategies = strategies;
      _pendingRules = pendingRules;
      _pendingCount = _pendingRules.length;
      _guardianSuggestions = guardianSuggestions;
      _suggestionCount = _guardianSuggestions.length;
      _codeFixSuggestions = codeFixSuggestions;
      _codeFixCount = _codeFixSuggestions.length;
      _evolutionReport = evolutionReport;
      _isLoading = false;
    });
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'running': return '进化中';
      case 'completed': return '已完成';
      case 'failed': return '失败';
      default: return '待执行';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running': return Colors.orange;
      case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.grey;
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
            Tab(text: '代码修改($_codeFixCount)'), // 新增Tab
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                      Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                                      const Text('外脑进化报告', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(_evolutionReport['summary'] ?? '暂无新规则', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _getStatusColor(_evolutionReport['status'] ?? 'idle').withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                  child: Text(_getStatusText(_evolutionReport['status'] ?? 'idle'), style: TextStyle(color: _getStatusColor(_evolutionReport['status'] ?? 'idle'), fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStrategiesTab(),
                          _buildPendingRulesTab(),
                          _buildGuardianSuggestionsTab(),
                          _buildCodeFixTab(), // 新增
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStrategiesTab() {
    if (_strategies.isEmpty) return const Center(child: Text('暂无策略', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _strategies.length,
      itemBuilder: (context, index) => StrategyItem(strategy: _strategies[index], onStrategyChanged: _loadData),
    );
  }

  Widget _buildPendingRulesTab() {
    if (_pendingRules.isEmpty) return const Center(child: Text('暂无待审核规则', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRules.length,
      itemBuilder: (context, index) => PendingRuleItem(rule: _pendingRules[index], onStatusChanged: _loadData),
    );
  }

  Widget _buildGuardianSuggestionsTab() {
    if (_guardianSuggestions.isEmpty) return const Center(child: Text('暂无守门员建议', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guardianSuggestions.length,
      itemBuilder: (context, index) => guardian.GuardianSuggestionItem(suggestion: _guardianSuggestions[index], onStatusChanged: _loadData),
    );
  }

  // 新增：代码修改审批Tab
  Widget _buildCodeFixTab() {
    if (_codeFixSuggestions.isEmpty) {
      return const Center(child: Text('暂无代码修改请求', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _codeFixSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _codeFixSuggestions[index];
        // 复用守门员建议组件（如果字段不匹配，可以新建一个组件，但暂时复用）
        return guardian.GuardianSuggestionItem(
          suggestion: suggestion,
          onStatusChanged: _loadData,
        );
      },
    );
  }
}