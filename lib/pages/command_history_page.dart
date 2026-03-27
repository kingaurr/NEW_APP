// lib/pages/command_history_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 指令历史页面
/// 显示所有语音指令执行历史
class CommandHistoryPage extends StatefulWidget {
  const CommandHistoryPage({super.key});

  @override
  State<CommandHistoryPage> createState() => _CommandHistoryPageState();
}

class _CommandHistoryPageState extends State<CommandHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _commands = [];
  String _filterStatus = 'all'; // all, success, failed, pending
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
      final result = await ApiService.getCommandHistory(limit: 200);
      // 后端返回格式: { "history": [...] }
      if (result != null && result is Map && result['history'] != null) {
        setState(() {
          _commands = result['history'];
        });
      } else {
        setState(() {
          _errorMessage = '获取指令历史失败';
        });
      }
    } catch (e) {
      debugPrint('加载指令历史失败: $e');
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

  List<dynamic> get _filteredCommands {
    if (_filterStatus == 'all') return _commands;
    return _commands.where((cmd) {
      final status = cmd['status'] ?? '';
      if (_filterStatus == 'success') return status == 'success';
      if (_filterStatus == 'failed') return status == 'failed';
      if (_filterStatus == 'pending') return status == 'pending';
      return true;
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
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
      } else if (diff.inDays < 7) {
        return '${diff.inDays}天前';
      }
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.substring(0, 16);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
        return '成功';
      case 'failed':
        return '失败';
      case 'pending':
        return '执行中';
      default:
        return '未知';
    }
  }

  void _showDetailDialog(Map<String, dynamic> command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('指令详情', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('指令', command['command'] ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('操作', command['operation'] ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('时间', _formatDate(command['timestamp'])),
              const Divider(color: Colors.grey),
              _buildDetailRow('状态', _getStatusText(command['status'] ?? '')),
              if (command['error'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('错误', command['error']),
              ],
              if (command['evidence'] != null) ...[
                const Divider(color: Colors.grey),
                const Text(
                  '证据',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    command['evidence'].toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (command['status'] == 'failed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _retryCommand(command);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('重试'),
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

  Future<void> _retryCommand(Map<String, dynamic> command) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在重新执行...'), backgroundColor: Colors.blue),
      );
    }

    try {
      // 修复：executeCommand 返回 bool，不是 Map
      final success = await ApiService.executeCommand(
        command['command'],
        'retry_user', // 可考虑从会话中获取真实用户ID
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('执行成功'), backgroundColor: Colors.green),
          );
        }
        _loadData();
      } else {
        throw Exception('执行失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重试失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指令历史'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'success', child: Text('成功')),
              const PopupMenuItem(value: 'failed', child: Text('失败')),
              const PopupMenuItem(value: 'pending', child: Text('执行中')),
            ],
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
              : _filteredCommands.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无指令记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCommands.length,
                      itemBuilder: (context, index) {
                        final cmd = _filteredCommands[index];
                        return _buildCommandItem(cmd);
                      },
                    ),
    );
  }

  Widget _buildCommandItem(Map<String, dynamic> cmd) {
    final command = cmd['command'] ?? '';
    final status = cmd['status'] ?? '';
    final timestamp = cmd['timestamp'];

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(cmd),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == 'success'
                      ? Icons.check
                      : (status == 'failed' ? Icons.close : Icons.hourglass_empty),
                  color: _getStatusColor(status),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}