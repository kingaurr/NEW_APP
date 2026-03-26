// lib/pages/audit_log_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../api_service.dart';

/// 审计日志页面
/// 查看所有安全操作记录，支持筛选和导出
class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  String _filterOperation = '';
  String _filterUserId = '';
  String _filterResult = '';
  int _currentPage = 0;
  final int _pageSize = 50;
  String _errorMessage = '';

  final List<String> _operationOptions = [
    '',
    'login',
    'logout',
    'approve_rule',
    'reject_rule',
    'clear_position',
    'modify_config',
    'rollback_version',
    'fingerprint_verify',
    'voice_verify',
    'permission_change',
  ];

  final List<String> _resultOptions = [
    '',
    'success',
    'failed',
    'denied',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.auditLogs(
        limit: _pageSize,
        operation: _filterOperation.isEmpty ? null : _filterOperation,
        userId: _filterUserId.isEmpty ? null : _filterUserId,
        result: _filterResult.isEmpty ? null : _filterResult,
      );

      if (result != null && result['logs'] != null) {
        setState(() {
          _logs = result['logs'];
        });
      } else {
        setState(() {
          _errorMessage = '获取审计日志失败';
        });
      }
    } catch (e) {
      debugPrint('加载审计日志失败: $e');
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

  Future<void> _exportLogs() async {
    try {
      final result = await ApiService.auditLogs(limit: 1000);
      if (result == null || result['logs'] == null) {
        throw Exception('获取日志失败');
      }

      final logs = result['logs'] as List;
      if (logs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂无日志可导出'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // 构建CSV内容
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('时间,操作,用户,结果,详情,IP地址,设备ID');

      for (final log in logs) {
        final timestamp = log['timestamp'] ?? '';
        final operation = log['operation'] ?? '';
        final userId = log['user_id'] ?? '';
        final result = log['result'] ?? '';
        final details = _formatDetailsForCsv(log['details']);
        final ip = log['ip_address'] ?? '';
        final deviceId = log['device_id'] ?? '';

        csvBuffer.writeln('"$timestamp","$operation","$userId","$result","$details","$ip","$deviceId"');
      }

      // 选择保存路径
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;

      final filePath = '$directory/audit_log_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导出到: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('导出失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDetailsForCsv(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return '';
    final parts = <String>[];
    if (details['rule_name'] != null) parts.add('规则:${details['rule_name']}');
    if (details['rule_id'] != null) parts.add('ID:${details['rule_id']}');
    if (details['position_value'] != null) parts.add('金额:${details['position_value']}');
    if (details['score'] != null) parts.add('相似度:${(details['score'] * 100).toInt()}%');
    if (details['message'] != null) parts.add(details['message']);
    return parts.join('|');
  }

  String _getOperationName(String operation) {
    const names = {
      'login': '登录',
      'logout': '登出',
      'approve_rule': '批准规则',
      'reject_rule': '拒绝规则',
      'clear_position': '清仓',
      'modify_config': '修改配置',
      'rollback_version': '版本回滚',
      'fingerprint_verify': '指纹验证',
      'voice_verify': '声纹验证',
      'permission_change': '权限变更',
    };
    return names[operation] ?? operation;
  }

  String _getResultText(String result) {
    switch (result) {
      case 'success':
        return '成功';
      case 'failed':
        return '失败';
      case 'denied':
        return '拒绝';
      default:
        return result;
    }
  }

  Color _getResultColor(String result) {
    if (result == 'success') return Colors.green;
    if (result == 'failed') return Colors.red;
    if (result == 'denied') return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('审计日志'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件栏
          if (_filterOperation.isNotEmpty || _filterUserId.isNotEmpty || _filterResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A2A2A),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    if (_filterOperation.isNotEmpty)
                      Chip(
                        label: Text(_getOperationName(_filterOperation)),
                        onDeleted: () {
                          setState(() {
                            _filterOperation = '';
                          });
                          _loadLogs();
                        },
                        backgroundColor: Colors.grey[800],
                        deleteIconColor: Colors.white,
                      ),
                    if (_filterUserId.isNotEmpty)
                      Chip(
                        label: Text('用户: $_filterUserId'),
                        onDeleted: () {
                          setState(() {
                            _filterUserId = '';
                          });
                          _loadLogs();
                        },
                        backgroundColor: Colors.grey[800],
                        deleteIconColor: Colors.white,
                      ),
                    if (_filterResult.isNotEmpty)
                      Chip(
                        label: Text(_getResultText(_filterResult)),
                        onDeleted: () {
                          setState(() {
                            _filterResult = '';
                          });
                          _loadLogs();
                        },
                        backgroundColor: Colors.grey[800],
                        deleteIconColor: Colors.white,
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterOperation = '';
                          _filterUserId = '';
                          _filterResult = '';
                        });
                        _loadLogs();
                      },
                      child: const Text('清除筛选'),
                    ),
                  ],
                ),
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
                    : _logs.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无审计日志',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return _buildLogItem(log);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? '';
    final operation = log['operation'] ?? '';
    final result = log['result'] ?? '';
    final userId = log['user_id'] ?? '';
    final details = log['details'] ?? {};

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          _showDetailDialog(log);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getResultColor(result),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getOperationName(operation),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    timestamp.length > 19 ? timestamp.substring(0, 19) : timestamp,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    userId,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getResultColor(result).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getResultText(result),
                      style: TextStyle(
                        color: _getResultColor(result),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (details.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDetails(details),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDetails(Map<String, dynamic> details) {
    final parts = <String>[];
    if (details['rule_name'] != null) {
      parts.add('规则: ${details['rule_name']}');
    }
    if (details['rule_id'] != null) {
      parts.add('ID: ${details['rule_id']}');
    }
    if (details['position_value'] != null) {
      parts.add('金额: ${details['position_value']}');
    }
    if (details['score'] != null) {
      parts.add('相似度: ${(details['score'] * 100).toInt()}%');
    }
    if (details['message'] != null) {
      parts.add(details['message']);
    }
    return parts.join(' | ');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选日志', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _filterOperation.isEmpty ? null : _filterOperation,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '操作类型',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                items: _operationOptions.map((op) {
                  return DropdownMenuItem(
                    value: op.isEmpty ? null : op,
                    child: Text(op.isEmpty ? '全部' : _getOperationName(op)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterOperation = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '用户ID',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filterUserId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _filterResult.isEmpty ? null : _filterResult,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '结果',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                items: _resultOptions.map((res) {
                  return DropdownMenuItem(
                    value: res.isEmpty ? null : res,
                    child: Text(res.isEmpty ? '全部' : _getResultText(res)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterResult = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          _getOperationName(log['operation'] ?? ''),
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('时间', log['timestamp']?.substring(0, 19) ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('用户', log['user_id'] ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('结果', _getResultText(log['result'] ?? '')),
              const Divider(color: Colors.grey),
              _buildDetailRow('IP地址', log['ip_address'] ?? '无'),
              const Divider(color: Colors.grey),
              _buildDetailRow('设备ID', log['device_id'] ?? '无'),
              if (log['details'] != null && log['details'].isNotEmpty) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('详情', _formatDetails(log['details'])),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';