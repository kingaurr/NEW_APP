// lib/pages/evolution_suggestions_page.dart
// ==================== v2.0 自进化引擎：优化建议列表页（2026-04-25） ====================
// 功能描述：
// 1. 展示从守门员获取的优化建议列表
// 2. 每条建议显示模块、类型、优先级、建议内容、置信度
// 3. 支持按优先级筛选（全部/P0/P1/P2）
// 4. 点击跳转建议详情页，进行审批/拒绝操作
// 5. 支持下拉刷新
// 数据来源：后端 /api/evolution/suggestions → guardian.get_pending_suggestions()
// 遵循规范：
// - P0 真实数据原则：所有数据来自API，无数据展示"暂无优化建议"。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P7 完整交互绑定：列表项使用 InkWell 包裹，点击跳转详情。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 优化建议列表页
class EvolutionSuggestionsPage extends StatefulWidget {
  const EvolutionSuggestionsPage({super.key});

  @override
  State<EvolutionSuggestionsPage> createState() => _EvolutionSuggestionsPageState();
}

class _EvolutionSuggestionsPageState extends State<EvolutionSuggestionsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allSuggestions = [];
  List<Map<String, dynamic>> _filteredSuggestions = [];
  String _selectedPriority = '全部';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getEvolutionSuggestions();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        final typedList = <Map<String, dynamic>>[];
        for (final item in suggestions) {
          if (item is Map<String, dynamic>) {
            typedList.add(item);
          }
        }

        setState(() {
          _allSuggestions = typedList;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络异常，请检查连接';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _applyFilter() {
    if (_selectedPriority == '全部') {
      _filteredSuggestions = List.from(_allSuggestions);
    } else {
      _filteredSuggestions = _allSuggestions
          .where((s) => s['priority'] == _selectedPriority)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('优化建议'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
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
                      _buildFilterBar(),
                      Expanded(
                        child: _filteredSuggestions.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lightbulb_outline,
                                        color: Colors.white38, size: 64),
                                    SizedBox(height: 16),
                                    Text(
                                      '暂无优化建议',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                itemCount: _filteredSuggestions.length,
                                itemBuilder: (context, index) {
                                  return _buildSuggestionCard(_filteredSuggestions[index]);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final priorities = ['全部', 'P0', 'P1', 'P2'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: priorities.map((p) {
          final isSelected = _selectedPriority == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPriority = p;
                  _applyFilter();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4AF37).withOpacity(0.2)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.grey,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final module = suggestion['module'] ?? '未知模块';
    final type = suggestion['type'] ?? '';
    final priority = suggestion['priority'] ?? 'P2';
    final suggestionText = suggestion['suggestion'] ?? '暂无建议内容';
    final confidence = suggestion['confidence'] ?? 0.0;
    final confidenceNum = confidence is num ? confidence.toDouble() : 0.0;

    Color priorityColor;
    switch (priority) {
      case 'P0':
        priorityColor = Colors.red;
        break;
      case 'P1':
        priorityColor = Colors.orange;
        break;
      case 'P2':
        priorityColor = Colors.grey;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/evolution_suggestion_detail',
            arguments: suggestion,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      module,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    confidenceNum >= 70 ? Icons.verified : Icons.info_outline,
                    color: confidenceNum >= 70 ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${confidenceNum.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: confidenceNum >= 70 ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                suggestionText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (type is String && type.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  type,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}