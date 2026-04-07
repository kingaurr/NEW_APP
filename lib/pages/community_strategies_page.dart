// lib/pages/community_strategies_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';
import 'community_strategy_detail_page.dart';

class CommunityStrategiesPage extends StatefulWidget {
  const CommunityStrategiesPage({super.key});

  @override
  State<CommunityStrategiesPage> createState() => _CommunityStrategiesPageState();
}

class _CommunityStrategiesPageState extends State<CommunityStrategiesPage> {
  bool _isLoading = true;
  List<dynamic> _strategies = [];
  String _error = '';
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoading) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      if (mounted) setState(() => _strategies.clear());
    }
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await ApiService.getPendingRulesV2(limit: _pageSize, page: _page);
      if (mounted) {
        final List<dynamic> newList = result is List ? result : [];
        if (refresh || _page == 1) {
          _strategies = newList;
        } else {
          _strategies.addAll(newList);
        }
        _hasMore = newList.length >= _pageSize;
        setState(() {});
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      _page++;
      await _loadData();
    }
  }

  Future<void> _refresh() async {
    _error = '';
    await _loadData(refresh: true);
  }

  Future<void> _approve(String ruleId) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以批准策略',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    try {
      final success = await ApiService.approveRule(ruleId);
      if (success) {
        _showMessage('策略已批准');
        await _refresh();
      } else {
        _showMessage('批准失败', isError: true);
      }
    } catch (e) {
      _showMessage('操作异常: $e', isError: true);
    }
  }

  Future<void> _reject(String ruleId) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以拒绝策略',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    try {
      final success = await ApiService.rejectRule(ruleId);
      if (success) {
        _showMessage('策略已拒绝');
        await _refresh();
      } else {
        _showMessage('拒绝失败', isError: true);
      }
    } catch (e) {
      _showMessage('操作异常: $e', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社区策略'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading && _strategies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty && _strategies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _strategies.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index == _strategies.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final rule = _strategies[index];
                      return Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rule['name'] ?? rule['id'],
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      rule['source'] ?? '社区',
                                      style: const TextStyle(color: Colors.blue, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (rule['llm_score'] != null)
                                    Chip(
                                      label: Text(
                                        'LLM: ${rule['llm_score'] is int ? rule['llm_score'] : (rule['llm_score'] * 100).toInt()}',
                                        style: const TextStyle(color: Colors.orange, fontSize: 11),
                                      ),
                                      backgroundColor: Colors.orange.withOpacity(0.2),
                                    ),
                                  Chip(
                                    label: Text('胜率: ${((rule['win_rate'] ?? 0) * 100).toInt()}%', style: const TextStyle(color: Colors.green, fontSize: 11)),
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                  ),
                                  Chip(
                                    label: Text('回撤: ${((rule['max_drawdown'] ?? 0) * 100).toInt()}%', style: const TextStyle(color: Colors.red, fontSize: 11)),
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _reject(rule['id']),
                                    child: const Text('拒绝', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _approve(rule['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('批准'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CommunityStrategyDetailPage(ruleId: rule['id']),
                                        ),
                                      );
                                    },
                                    child: const Text('详情', style: TextStyle(color: Color(0xFFD4AF37))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}