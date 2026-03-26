// lib/pages/signal_history_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/signal_item.dart';

/// 信号历史页面
/// 显示所有历史交易信号，支持筛选
class SignalHistoryPage extends StatefulWidget {
  const SignalHistoryPage({super.key});

  @override
  State<SignalHistoryPage> createState() => _SignalHistoryPageState();
}

class _SignalHistoryPageState extends State<SignalHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _signals = [];
  List<dynamic> _filteredSignals = [];
  String _filterAction = 'all'; // all, buy, sell, hold
  String _filterResult = 'all'; // all, executed, pending, rejected
  int _currentPage = 0;
  final int _pageSize = 20;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getSignalHistory(limit: 200);
      if (result != null && result['signals'] != null) {
        setState(() {
          _signals = result['signals'];
          _applyFilters();
        });
      } else {
        setState(() {
          _errorMessage = '获取信号历史失败';
        });
      }
    } catch (e) {
      debugPrint('加载信号历史失败: $e');
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
    var filtered = List.from(_signals);
    
    // 操作筛选
    if (_filterAction != 'all') {
      filtered = filtered.where((s) => s['action'] == _filterAction).toList();
    }
    
    // 执行结果筛选
    if (_filterResult != 'all') {
      filtered = filtered.where((s) {
        if (_filterResult == 'executed') return s['executed'] == true;
        if (_filterResult == 'pending') return s['executed'] == false && s['rejected'] == false;
        if (_filterResult == 'rejected') return s['rejected'] == true;
        return true;
      }).toList();
    }
    
    // 按时间倒序
    filtered.sort((a, b) {
      final timeA = a['timestamp'] ?? '';
      final timeB = b['timestamp'] ?? '';
      return timeB.compareTo(timeA);
    });
    
    setState(() {
      _filteredSignals = filtered;
    });
  }

  String _getActionFilterText() {
    switch (_filterAction) {
      case 'buy':
        return '买入';
      case 'sell':
        return '卖出';
      case 'hold':
        return '持有';
      default:
        return '全部';
    }
  }

  String _getResultFilterText() {
    switch (_filterResult) {
      case 'executed':
        return '已执行';
      case 'pending':
        return '待执行';
      case 'rejected':
        return '已拒绝';
      default:
        return '全部';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信号历史'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
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
                    // 筛选栏
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: _getActionFilterText(),
                            icon: Icons.swap_horiz,
                            onTap: () => _showActionFilterDialog(),
                          ),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                            label: _getResultFilterText(),
                            icon: Icons.check_circle_outline,
                            onTap: () => _showResultFilterDialog(),
                          ),
                          const Spacer(),
                          Text(
                            '共${_filteredSignals.length}条',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    // 信号列表
                    Expanded(
                      child: _filteredSignals.isEmpty
                          ? const Center(
                              child: Text(
                                '暂无信号',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSignals.length,
                              itemBuilder: (context, index) {
                                final signal = _filteredSignals[index];
                                return SignalItem(
                                  signal: signal,
                                  onExecuted: _loadData,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showActionFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选操作类型', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile('全部', 'all'),
            _buildRadioTile('买入', 'buy'),
            _buildRadioTile('卖出', 'sell'),
            _buildRadioTile('持有', 'hold'),
          ],
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

  void _showResultFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选执行结果', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultRadioTile('全部', 'all'),
            _buildResultRadioTile('已执行', 'executed'),
            _buildResultRadioTile('待执行', 'pending'),
            _buildResultRadioTile('已拒绝', 'rejected'),
          ],
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

  Widget _buildRadioTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      leading: Radio<String>(
        value: value,
        groupValue: _filterAction,
        activeColor: const Color(0xFFD4AF37),
        onChanged: (newValue) {
          setState(() {
            _filterAction = newValue!;
          });
          Navigator.pop(context);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildResultRadioTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      leading: Radio<String>(
        value: value,
        groupValue: _filterResult,
        activeColor: const Color(0xFFD4AF37),
        onChanged: (newValue) {
          setState(() {
            _filterResult = newValue!;
          });
          Navigator.pop(context);
          _applyFilters();
        },
      ),
    );
  }
}