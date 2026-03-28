// lib/pages/guardian_suggestions_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/guardian_suggestion_item.dart';

/// 守门员建议列表页面
/// 显示守门员生成的所有优化建议，支持采纳/拒绝/筛选
class GuardianSuggestionsPage extends StatefulWidget {
  const GuardianSuggestionsPage({super.key});

  @override
  State<GuardianSuggestionsPage> createState() => _GuardianSuggestionsPageState();
}

class _GuardianSuggestionsPageState extends State<GuardianSuggestionsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _suggestions = [];
  List<dynamic> _filteredSuggestions = [];
  String _filterStatus = 'pending'; // pending, history, all
  String _filterPriority = '';
  int _pendingCount = 0;
  int _historyCount = 0;
  String _errorMessage = '';

  late TabController _tabController;

  final List<String> _priorityOptions = [
    '',
    'critical',
    'high',
    'medium',
    'low',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _filterStatus = _tabController.index == 0 ? 'pending' : 'history';
      });
      _applyFilters();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getPendingSuggestions(),
        ApiService.getHistorySuggestions(),
      ]);

      List<dynamic> pendingList = [];
      List<dynamic> historyList = [];

      // 处理待处理建议
      if (results[0] != null) {
        if (results[0] is List) {
          pendingList = results[0] as List<dynamic>;
        } else if (results[0] is Map<String, dynamic> && results[0].containsKey('suggestions') && results[0]['suggestions'] is List) {
          pendingList = results[0]['suggestions'] as List<dynamic>;
        }
      }

      // 处理历史建议
      if (results[1] != null) {
        if (results[1] is List) {
          historyList = results[1] as List<dynamic>;
        } else if (results[1] is Map<String, dynamic> && results[1].containsKey('suggestions') && results[1]['suggestions'] is List) {
          historyList = results[1]['suggestions'] as List<dynamic>;
        }
      }

      setState(() {
        _pendingCount = pendingList.length;
        _historyCount = historyList.length;
        _suggestions = [...pendingList, ...historyList];
      });

      _applyFilters();
    } catch (e) {
      debugPrint('加载守门员建议失败: $e');
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

  void _applyFilters() {
    var filtered = _suggestions.where((s) {
      if (_filterStatus == 'pending') {
        return s['status'] == 'pending';
      } else if (_filterStatus == 'history') {
        return s['status'] != 'pending';
      }
      return true;
    }).toList();

    if (_filterPriority.isNotEmpty) {
      filtered = filtered.where((s) => s['priority'] == _filterPriority).toList();
    }

    setState(() {
      _filteredSuggestions = filtered;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选建议', style: TextStyle(color: Colors.white)),
        content: DropdownButtonFormField<String>(
          value: _filterPriority.isEmpty ? null : _filterPriority,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '优先级',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          items: _priorityOptions.map((p) {
            return DropdownMenuItem(
              value: p.isEmpty ? null : p,
              child: Text(p.isEmpty ? '全部' : _getPriorityText(p)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filterPriority = value ?? '';
            });
            Navigator.pop(context);
            _applyFilters();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'critical':
        return '紧急';
      case 'high':
        return '重要';
      case 'medium':
        return '一般';
      case 'low':
        return '参考';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('守门员建议'),
        backgroundColor: const Color(0xFF1E1E1E),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '待处理($_pendingCount)'),
            Tab(text: '历史记录($_historyCount)'),
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
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
                        onPressed: _loadSuggestions,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _filteredSuggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, color: Colors.grey, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _filterStatus == 'pending' ? '暂无待处理建议' : '暂无历史建议',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return GuardianSuggestionItem(
                          suggestion: suggestion,
                          onStatusChanged: _loadSuggestions,
                        );
                      },
                    ),
    );
  }
}