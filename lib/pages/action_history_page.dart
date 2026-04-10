// lib/pages/action_history_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 待办历史页面
class ActionHistoryPage extends StatefulWidget {
  const ActionHistoryPage({super.key});

  @override
  State<ActionHistoryPage> createState() => _ActionHistoryPageState();
}

class _ActionHistoryPageState extends State<ActionHistoryPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  
  // 筛选状态
  String _selectedStatus = 'all'; // all, pending, done

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取当前待办列表
      final currentItems = await ApiService.getActionItems();
      
      // 尝试获取历史待办（通过日报历史聚合）
      final historyItems = await _loadHistoryActionItems();
      
      // 合并去重
      final allItems = [...currentItems, ...historyItems];
      final seen = <String>{};
      final uniqueItems = <dynamic>[];
      for (final item in allItems) {
        final id = item['id'] as String? ?? '';
        if (id.isNotEmpty && !seen.contains(id)) {
          seen.add(id);
          uniqueItems.add(item);
        }
      }
      
      // 按时间倒序排序
      uniqueItems.sort((a, b) {
        final aTime = _parseItemTime(a);
        final bTime = _parseItemTime(b);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _allItems = uniqueItems;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<dynamic>> _loadHistoryActionItems() async {
    final historyItems = <dynamic>[];
    try {
      // 获取近7天的日报，聚合其中的待办
      final now = DateTime.now();
      for (int i = 1; i <= 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        try {
          final report = await ApiService.getDailyReportByDate(dateStr);
          if (report != null) {
            final items = report['action_items'] as List<dynamic>? ?? [];
            historyItems.addAll(items);
          }
        } catch (e) {
          // 忽略单日错误
        }
      }
    } catch (e) {
      // 忽略
    }
    return historyItems;
  }

  DateTime _parseItemTime(dynamic item) {
    try {
      final created = item['created_at'] as String?;
      if (created != null) {
        return DateTime.parse(created);
      }
      final resolved = item['resolved_date'] as String?;
      if (resolved != null) {
        return DateTime.parse(resolved);
      }
    } catch (e) {
      // fallback
    }
    return DateTime(2000);
  }

  void _applyFilter() {
    if (_selectedStatus == 'all') {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems.where((item) {
        final status = item['status'] as String? ?? 'pending';
        return status == _selectedStatus;
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('待办历史'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                      Text('加载失败: $_error', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 筛选栏
        _buildFilterBar(),
        // 统计信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${_filteredItems.length} 条待办',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Row(
                children: [
                  _buildStatusBadge('待处理', _allItems.where((i) => (i['status'] ?? 'pending') == 'pending').length, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatusBadge('已完成', _allItems.where((i) => (i['status'] ?? 'pending') == 'done').length, Colors.green),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        // 列表
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, color: Colors.white38, size: 64),
                      SizedBox(height: 16),
                      Text(
                        '暂无待办记录',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildActionItemCard(_filteredItems[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Text('状态: ', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('待处理', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('已完成', 'done'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white38,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionItemCard(dynamic item) {
    final id = item['id'] as String? ?? '';
    final title = item['title'] as String? ?? '未命名待办';
    final description = item['description'] as String? ?? '';
    final priority = item['priority'] as String? ?? 'medium';
    final status = item['status'] as String? ?? 'pending';
    final createdAt = item['created_at'] as String? ?? '';
    final resolvedDate = item['resolved_date'] as String?;
    final evidence = item['evidence'] as String?;

    Color priorityColor;
    String priorityText;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = '高';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = '中';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = '低';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = priority;
    }

    final isDone = status == 'done';
    final statusColor = isDone ? Colors.green : Colors.orange;
    final statusText = isDone ? '已完成' : '待处理';

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  createdAt,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            if (isDone && resolvedDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '完成于 $resolvedDate',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (evidence != null && evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evidence,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isDone) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text('确认完成', style: TextStyle(color: Color(0xFFD4AF37))),
                        content: const Text('确定该待办事项已完成吗？', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                            ),
                            child: const Text('确定', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        final success = await ApiService.completeActionItem(id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已标记为完成')),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('操作失败: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('标记完成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}