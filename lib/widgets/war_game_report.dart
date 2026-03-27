// lib/widgets/war_game_report.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 红蓝军报告组件
/// 显示红蓝军对抗结果，支持查看详情
class WarGameReport extends StatefulWidget {
  final bool isLight; // true: 轻量对抗（白天每小时）, false: 深度报告（夜间）

  const WarGameReport({super.key, required this.isLight});

  @override
  State<WarGameReport> createState() => _WarGameReportState();
}

class _WarGameReportState extends State<WarGameReport> {
  bool _isLoading = true;
  bool _isExpanded = false;
  Map<String, dynamic> _report = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = widget.isLight
          ? await ApiService.getLatestLightWarGame()
          : await ApiService.getLatestDeepWarGame();

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _report = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取${widget.isLight ? '轻量' : '深度'}红蓝军报告失败';
        });
      }
    } catch (e) {
      debugPrint('加载红蓝军报告失败: $e');
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

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getReturnColor(double ret) {
    if (ret > 0) return Colors.green;
    if (ret < 0) return Colors.red;
    return Colors.grey;
  }

  String _getWinnerText(String winner) {
    if (winner == 'blue') return '蓝军';
    if (winner == 'red') return '红军';
    return '平局';
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          widget.isLight ? '轻量对抗报告' : '深度对抗报告',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('时间', _report['timestamp']?.substring(0, 19) ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('市场状态', _report['market_style'] ?? '震荡'),
              const Divider(color: Colors.grey),
              _buildDetailRow('蓝军收益', '${(_report['blue_return'] ?? 0) >= 0 ? '+' : ''}${(_report['blue_return'] ?? 0) * 100}%'),
              const Divider(color: Colors.grey),
              _buildDetailRow('红军收益', '${(_report['red_return'] ?? 0) >= 0 ? '+' : ''}${(_report['red_return'] ?? 0) * 100}%'),
              const Divider(color: Colors.grey),
              _buildDetailRow('胜者', _getWinnerText(_report['winner'] ?? '')),
              if (!widget.isLight && _report['suggestion'] != null) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('建议', _report['suggestion']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (!widget.isLight && _report['suggestion'] != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applySuggestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('应用建议'),
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

  Future<void> _applySuggestion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认应用建议', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要应用红蓝军建议吗？\n${_report['suggestion']}',
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
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('应用'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 修复：applyWarGameSuggestion 返回 bool
      final success = await ApiService.applyWarGameSuggestion(_report['id']);
      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建议已应用'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('应用失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('应用失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final blueReturn = _report['blue_return'] ?? 0.0;
    final redReturn = _report['red_return'] ?? 0.0;
    final winner = _report['winner'] ?? '';
    final marketStyle = _report['market_style'] ?? '震荡';
    final suggestion = _report['suggestion'];

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: winner == 'blue'
              ? Colors.blue.withOpacity(0.3)
              : (winner == 'red' ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
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
              // 头部
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: winner == 'blue'
                          ? Colors.blue.withOpacity(0.2)
                          : (winner == 'red' ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      winner == 'blue'
                          ? Icons.shield
                          : (winner == 'red' ? Icons.flash_on : Icons.remove),
                      color: winner == 'blue' ? Colors.blue : (winner == 'red' ? Colors.red : Colors.grey),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isLight ? '轻量对抗' : '深度对抗',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '市场: $marketStyle',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: winner == 'blue'
                          ? Colors.blue.withOpacity(0.2)
                          : (winner == 'red' ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '胜者: ${_getWinnerText(winner)}',
                      style: TextStyle(
                        color: winner == 'blue' ? Colors.blue : (winner == 'red' ? Colors.red : Colors.grey),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 收益对比
              Row(
                children: [
                  Expanded(
                    child: _buildReturnCard('蓝军', blueReturn, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReturnCard('红军', redReturn, Colors.red),
                  ),
                ],
              ),

              // 建议
              if (suggestion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 时间
              const SizedBox(height: 8),
              Text(
                _formatTime(_report['timestamp']),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnCard(String name, double ret, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ret >= 0 ? '+' : ''}${(ret * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: _getReturnColor(ret),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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