// lib/widgets/signal_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 信号条目组件
/// 显示AI生成的交易信号，支持查看详情和执行
class SignalItem extends StatefulWidget {
  final Map<String, dynamic> signal;
  final VoidCallback? onExecuted;

  const SignalItem({
    super.key,
    required this.signal,
    this.onExecuted,
  });

  @override
  State<SignalItem> createState() => _SignalItemState();
}

class _SignalItemState extends State<SignalItem> {
  bool _isExpanded = false;
  bool _isExecuting = false;

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      case 'hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'buy':
        return '买入';
      case 'sell':
        return '卖出';
      case 'hold':
        return '持有';
      default:
        return '观望';
    }
  }

  Future<void> _executeSignal() async {
    final action = widget.signal['action'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认执行', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要执行信号吗？\n'
          '股票: ${widget.signal['name']} (${widget.signal['code']})\n'
          '操作: ${_getActionText(action)}\n'
          '价格: ¥${widget.signal['price']}\n'
          '置信度: ${(widget.signal['confidence'] * 100).toInt()}%',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action),
              foregroundColor: Colors.white,
            ),
            child: Text(_getActionText(action)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      final result = await ApiService.executeSignal(widget.signal['id']);
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getActionText(action)}信号已执行'),
              backgroundColor: _getActionColor(action),
            ),
          );
          widget.onExecuted?.call();
        }
      } else {
        throw Exception(result?['message'] ?? '执行失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('信号详情', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('股票', widget.signal['name'] ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('代码', widget.signal['code'] ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('操作', _getActionText(widget.signal['action'] ?? '')),
              const Divider(color: Colors.grey),
              _buildDetailRow('价格', '¥${widget.signal['price']}'),
              const Divider(color: Colors.grey),
              _buildDetailRow('置信度', '${(widget.signal['confidence'] * 100).toInt()}%'),
              const Divider(color: Colors.grey),
              _buildDetailRow('生成时间', widget.signal['timestamp']?.substring(0, 19) ?? ''),
              if (widget.signal['reason'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('理由', widget.signal['reason']),
              ],
              if (widget.signal['left_brain_decision'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('左脑决策', widget.signal['left_brain_decision']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (widget.signal['action'] != 'hold')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeSignal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getActionColor(widget.signal['action']),
                foregroundColor: Colors.white,
              ),
              child: Text(_getActionText(widget.signal['action'])),
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

  @override
  Widget build(BuildContext context) {
    final action = widget.signal['action'] ?? 'hold';
    final code = widget.signal['code'] ?? '';
    final name = widget.signal['name'] ?? '';
    final price = widget.signal['price'] ?? 0.0;
    final confidence = widget.signal['confidence'] ?? 0.5;
    final reason = widget.signal['reason'] ?? '';
    final timestamp = widget.signal['timestamp'];

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getActionColor(action).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: _showDetailDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getActionColor(action).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action == 'buy'
                          ? Icons.trending_up
                          : (action == 'sell' ? Icons.trending_down : Icons.remove),
                      color: _getActionColor(action),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getActionText(action),
                        style: TextStyle(
                          color: _getActionColor(action),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '置信度 ${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: confidence >= 0.7 ? Colors.green : Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTime(timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                  if (action != 'hold')
                    ElevatedButton(
                      onPressed: _isExecuting ? null : _executeSignal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionColor(action),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      child: _isExecuting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_getActionText(action)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}