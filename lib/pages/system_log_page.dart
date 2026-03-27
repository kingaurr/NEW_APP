// lib/pages/system_log_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../api_service.dart';

/// 系统日志页面
/// 实时查看系统日志，支持按级别筛选
class SystemLogPage extends StatefulWidget {
  const SystemLogPage({super.key});

  @override
  State<SystemLogPage> createState() => _SystemLogPageState();
}

class _SystemLogPageState extends State<SystemLogPage> {
  Timer? _timer;
  bool _isLoading = true;
  List<dynamic> _logs = [];
  List<dynamic> _filteredLogs = [];
  String _filterLevel = '';
  int _currentPage = 0;
  final int _pageSize = 100;
  String _errorMessage = '';
  bool _autoRefresh = true;

  final List<String> _levelOptions = [
    '',
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    // 每10秒自动刷新
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_autoRefresh && mounted) {
        _loadLogs(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final result = await ApiService.getRecentLogs(limit: _pageSize);
      List<dynamic> logsList = [];

      if (result is Map && result['logs'] is List) {
        logsList = result['logs'] as List<dynamic>;
      } else if (result is List) {
        logsList = result;
      }

      setState(() {
        _logs = logsList;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('加载系统日志失败: $e');
      if (showLoading && mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
        });
      }
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_filterLevel.isEmpty) {
      setState(() {
        _filteredLogs = List.from(_logs);
      });
    } else {
      setState(() {
        _filteredLogs = _logs.where((log) {
          final level = log['level'] ?? '';
          return level.toUpperCase() == _filterLevel.toUpperCase();
        }).toList();
      });
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.green;
      case 'DEBUG':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      case 'INFO':
        return Icons.info;
      case 'DEBUG':
        return Icons.bug_report;
      default:
        return Icons.description;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统日志'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          // 自动刷新开关
          Row(
            children: [
              const Text('自动', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Switch(
                value: _autoRefresh,
                onChanged: (value) {
                  setState(() {
                    _autoRefresh = value;
                  });
                },
                activeColor: const Color(0xFFD4AF37),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          if (_filterLevel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A2A2A),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_filterLevel),
                    onDeleted: () {
                      setState(() {
                        _filterLevel = '';
                      });
                      _applyFilter();
                    },
                    backgroundColor: _getLevelColor(_filterLevel).withOpacity(0.2),
                    deleteIconColor: _getLevelColor(_filterLevel),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterLevel = '';
                      });
                      _applyFilter();
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
            ),

          // 日志列表
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
                              onPressed: _loadLogs,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLogs.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无日志',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = _filteredLogs[index];
                              return _buildLogItem(log);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final level = log['level'] ?? '';
    final message = log['message'] ?? '';
    final timestamp = log['timestamp'];
    final source = log['source'] ?? '';

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getLevelColor(level).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getLevelIcon(level), color: _getLevelColor(level), size: 16),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLevelColor(level).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: _getLevelColor(level),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (source.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  source,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选日志级别', style: TextStyle(color: Colors.white)),
        content: DropdownButtonFormField<String>(
          value: _filterLevel.isEmpty ? null : _filterLevel,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '日志级别',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          items: _levelOptions.map((level) {
            return DropdownMenuItem(
              value: level.isEmpty ? null : level,
              child: Text(level.isEmpty ? '全部' : level),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filterLevel = value ?? '';
            });
            Navigator.pop(context);
            _applyFilter();
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