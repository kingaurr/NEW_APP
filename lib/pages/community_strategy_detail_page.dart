// lib/pages/community_strategy_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class CommunityStrategyDetailPage extends StatefulWidget {
  final String ruleId;
  const CommunityStrategyDetailPage({super.key, required this.ruleId});

  @override
  State<CommunityStrategyDetailPage> createState() => _CommunityStrategyDetailPageState();
}

class _CommunityStrategyDetailPageState extends State<CommunityStrategyDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _rule = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ApiService.getRuleById(widget.ruleId);
      if (mounted) {
        setState(() {
          _rule = data ?? {};
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_rule['name'] ?? widget.ruleId),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
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
                        onPressed: _loadDetail,
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
                      _buildSection('基本信息', {
                        '名称': _rule['name'],
                        '来源': _rule['source'],
                        'LLM评分': _rule['llm_score'] != null
                            ? (_rule['llm_score'] is int ? _rule['llm_score'] : (_rule['llm_score'] * 100).toInt())
                            : null,
                        '胜率': _rule['win_rate'] != null ? '${(_rule['win_rate'] * 100).toInt()}%' : null,
                        '最大回撤': _rule['max_drawdown'] != null ? '${(_rule['max_drawdown'] * 100).toInt()}%' : null,
                        '夏普比率': _rule['sharpe'],
                        '盈亏比': _rule['profit_ratio'],
                      }),
                      const SizedBox(height: 16),
                      _buildSection('策略逻辑', {'规则内容': _rule['content']?.toString() ?? '无'}),
                      const SizedBox(height: 16),
                      _buildSection('对抗报告摘要', {'摘要': _rule['adversarial_summary'] ?? '无'}),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> items) {
    final filteredItems = items.entries.where((e) => e.value != null).toList();
    if (filteredItems.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 12),
            ...filteredItems.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 100, child: Text('${e.key}:', style: const TextStyle(color: Colors.grey))),
                  Expanded(child: Text(e.value.toString(), style: const TextStyle(color: Colors.white))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}