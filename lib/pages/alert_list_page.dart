// lib/pages/alert_list_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'alert_detail_page.dart';

/// 告警列表页面
/// 显示系统告警信息，支持按级别筛选和已读/未读状态
class AlertListPage extends StatefulWidget {
  const AlertListPage({super.key});

  @override
  State<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String _filterSeverity = '';
  int _unreadCount = 0;
  String _errorMessage = '';

  final List<String> _severityOptions = [
    '',
    'critical',
    'high',
    'medium',
    'low',
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 使用已有的 getAlerts 方法（返回未读数量和告警列表）
      final result = await ApiService.getAlerts();
      if (result != null && result is Map<String, dynamic>) {
        final alerts = result['alerts'];
        final unread = result['unread_count'];
        if (alerts != null && alerts is List) {
          setState(() {
            _alerts = alerts;
            _unreadCount = unread ?? 0;
          });
        } else {
          setState(() {
            _errorMessage = '获取告警列表失败';
          });
        }
      } else {
        setState(() {
          _errorMessage = '获取告警列表失败';
        });
      }
    } catch (e) {
      debugPrint('加载告警列表失败: $e');
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

  Future<void> _markAsRead(String alertId) async {
    try {
      final result = await ApiService.acknowledgeAlert(alertId);
      if (result?['success'] == true) {
        setState(() {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          final index = _alerts.indexWhere((a) => a['id'] == alertId);
          if (index != -1) {
            _alerts[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }
  }

  Future<void> _markAllRead() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('全部标记已读', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要将所有告警标记为已读吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 逐个标记已读（若后端无批量接口）
      for (final alert in _alerts) {
        if (alert['read'] != true) {
          await ApiService.acknowledgeAlert(alert['id']);
        }
      }
      setState(() {
        for (var alert in _alerts) {
          alert['read'] = true;
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已全部标记为已读'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'critical':
        return '紧急';
      case 'high':
        return '重要';
      case 'medium':
        return '一般';
      case 'low':
        return '提示';
      default:
        return '未知';
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.info;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes == 0) return '刚刚';
          return '${diff.inMinutes}分钟前';
        }
        return '${diff.inHours}小时前';
      } else if (diff.inDays == 1) {
        return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp.substring(0, 16);
    }
  }

  void _navigateToDetail(Map<String, dynamic> alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertDetailPage(alert: alert),
      ),
    ).then((_) {
      if (alert['read'] != true) {
        _markAsRead(alert['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          if (_unreadCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: _markAllRead,
                  tooltip: '全部标记已读',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件栏
          if (_filterSeverity.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A2A2A),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_getSeverityText(_filterSeverity)),
                    onDeleted: () {
                      setState(() {
                        _filterSeverity = '';
                      });
                      _loadAlerts();
                    },
                    backgroundColor: _getSeverityColor(_filterSeverity).withOpacity(0.2),
                    deleteIconColor: _getSeverityColor(_filterSeverity),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterSeverity = '';
                      });
                      _loadAlerts();
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
            ),

          // 告警列表
          Expanded(
            child: _isLoading
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
                              onPressed: _loadAlerts,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _alerts.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无告警',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _alerts.length,
                            itemBuilder: (context, index) {
                              final alert = _alerts[index];
                              return _buildAlertItem(alert);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'medium';
    final title = alert['title'] ?? '';
    final message = alert['message'] ?? '';
    final timestamp = alert['timestamp'];
    final read = alert['read'] ?? false;

    return Card(
      color: read ? const Color(0xFF2A2A2A) : const Color(0xFF3A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getSeverityColor(severity).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSeverityIcon(severity),
                  color: _getSeverityColor(severity),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: read ? Colors.grey : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(severity).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSeverityText(severity),
                            style: TextStyle(
                              color: _getSeverityColor(severity),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(timestamp),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选告警', style: TextStyle(color: Colors.white)),
        content: DropdownButtonFormField<String>(
          value: _filterSeverity.isEmpty ? null : _filterSeverity,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '严重级别',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          items: _severityOptions.map((s) {
            return DropdownMenuItem(
              value: s.isEmpty ? null : s,
              child: Text(s.isEmpty ? '全部' : _getSeverityText(s)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filterSeverity = value ?? '';
            });
            Navigator.pop(context);
            _loadAlerts();
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
}