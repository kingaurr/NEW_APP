// lib/widgets/guardian_suggestion_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 守门员建议条目组件
/// 展示守门员生成的优化建议，支持采纳/拒绝/查看详情
class GuardianSuggestionItem extends StatefulWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback? onStatusChanged;

  const GuardianSuggestionItem({
    super.key,
    required this.suggestion,
    this.onStatusChanged,
  });

  @override
  State<GuardianSuggestionItem> createState() => _GuardianSuggestionItemState();
}

class _GuardianSuggestionItemState extends State<GuardianSuggestionItem> {
  bool _isProcessing = false;
  bool _isExpanded = false;

  Color _getPriorityColor(String priority) {
    switch (priority) {
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

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('采纳建议', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要采纳此建议吗？\n${widget.suggestion['title']}',
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('采纳'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ApiService.acceptSuggestion(widget.suggestion['id']);
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建议已采纳'), backgroundColor: Colors.green),
          );
          widget.onStatusChanged?.call();
        }
      } else {
        throw Exception(result?['message'] ?? '操作失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('拒绝建议', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要拒绝此建议吗？\n${widget.suggestion['title']}',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('拒绝'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ApiService.rejectSuggestion(widget.suggestion['id']);
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建议已拒绝'), backgroundColor: Colors.orange),
          );
          widget.onStatusChanged?.call();
        }
      } else {
        throw Exception(result?['message'] ?? '操作失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(widget.suggestion['title'] ?? '建议详情', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('优先级', _getPriorityText(widget.suggestion['priority'] ?? 'medium')),
              const Divider(color: Colors.grey),
              _buildDetailRow('生成时间', widget.suggestion['timestamp']?.substring(0, 19) ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('描述', widget.suggestion['description'] ?? ''),
              if (widget.suggestion['impact'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('影响评估', widget.suggestion['impact']),
              ],
              if (widget.suggestion['confidence'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('置信度', '${(widget.suggestion['confidence'] * 100).toInt()}%'),
              ],
              if (widget.suggestion['reasoning'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('决策依据', widget.suggestion['reasoning']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _accept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('采纳'),
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
            width: 80,
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
    final priority = widget.suggestion['priority'] ?? 'medium';
    final title = widget.suggestion['title'] ?? '';
    final description = widget.suggestion['description'] ?? '';
    final confidence = widget.suggestion['confidence'] ?? 0.5;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor(priority).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    priority == 'critical'
                        ? Icons.warning
                        : (priority == 'high' ? Icons.priority_high : Icons.lightbulb),
                    color: _getPriorityColor(priority),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPriorityText(priority),
                              style: TextStyle(
                                color: _getPriorityColor(priority),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '置信度 ${(confidence * 100).toInt()}%',
                            style: TextStyle(
                              color: confidence >= 0.7 ? Colors.green : Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 描述
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: _isExpanded ? 10 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 展开/收起
          if (description.length > 80)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  _isExpanded ? '收起' : '展开',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                ),
              ),
            ),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _reject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _accept,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(_isProcessing ? '处理中...' : '采纳'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _showDetailDialog,
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  tooltip: '详情',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}