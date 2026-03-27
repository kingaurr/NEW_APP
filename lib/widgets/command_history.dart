// lib/widgets/command_history.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 指令历史组件
/// 显示用户语音指令执行历史，支持查看详情和重试
class CommandHistory extends StatefulWidget {
  final int limit;

  const CommandHistory({super.key, this.limit = 20});

  @override
  State<CommandHistory> createState() => _CommandHistoryState();
}

class _CommandHistoryState extends State<CommandHistory> {
  bool _isLoading = true;
  List<dynamic> _commands = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getCommandHistory(limit: widget.limit);
      // 后端返回格式: { "history": [...] }
      if (result != null && result is Map && result['history'] != null) {
        setState(() {
          _commands = result['history'];
        });
      } else {
        setState(() {
          _commands = [];
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes == 0) {
            return '刚刚';
          }
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
              _buildDetailRow('时间', command['timestamp']?.substring(0, 19) ?? ''),
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
            width: 60,
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
      // 使用 ApiService.commandExecute 获取完整结果
      final result = await ApiService.commandExecute(
        command['command'],
        'retry_user', // 可考虑从上下文获取真实用户ID
        skipAuth: true, // 重试时跳过认证（或需重新认证，根据业务决定）
      );

      if (result != null && result is Map && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '执行成功'), backgroundColor: Colors.green),
          );
        }
        _loadHistory();
      } else {
        throw Exception(result?['message'] ?? '执行失败');
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
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '指令历史',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadHistory,
                  tooltip: '刷新',
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // 内容
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorMessage.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadHistory,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _commands.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              '暂无指令历史',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _commands.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                          itemBuilder: (context, index) {
                            final cmd = _commands[index];
                            return _buildCommandItem(cmd);
                          },
                        ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(Map<String, dynamic> cmd) {
    final command = cmd['command'] ?? '';
    final status = cmd['status'] ?? '';
    final timestamp = cmd['timestamp'];

    return InkWell(
      onTap: () => _showDetailDialog(cmd),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.length > 30 ? '${command.substring(0, 30)}...' : command,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}