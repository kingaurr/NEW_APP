// lib/widgets/strategy_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/strategy_detail_page.dart';

/// 策略条目组件
/// 显示策略信息，支持查看详情、启用/禁用、调整权重
class StrategyItem extends StatefulWidget {
  final Map<String, dynamic> strategy;
  final VoidCallback? onStrategyChanged;

  const StrategyItem({
    super.key,
    required this.strategy,
    this.onStrategyChanged,
  });

  @override
  State<StrategyItem> createState() => _StrategyItemState();
}

class _StrategyItemState extends State<StrategyItem> {
  bool _isExpanded = false;
  bool _isUpdating = false;
  double _weight = 0.0;

  @override
  void initState() {
    super.initState();
    _weight = widget.strategy['weight'] ?? 0.1;
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

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightBlue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _toggleEnabled() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final newEnabled = !(widget.strategy['enabled'] ?? true);
      // 修复：updateStrategyStatus 返回 bool
      final success = await ApiService.updateStrategyStatus(
        widget.strategy['id'],
        newEnabled,
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newEnabled ? '策略已启用' : '策略已禁用'),
              backgroundColor: newEnabled ? Colors.green : Colors.orange,
            ),
          );
          widget.onStrategyChanged?.call();
        }
      } else {
        throw Exception('操作失败');
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
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateWeight() async {
    final controller = TextEditingController(text: (_weight * 100).toStringAsFixed(0));
    final newWeight = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('调整权重', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '权重 (%)',
            labelStyle: TextStyle(color: Colors.grey),
            suffixText: '%',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0 && value <= 100) {
                Navigator.pop(context, value / 100);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入0-100之间的数字'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (newWeight == null || newWeight == _weight) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 修复：updateStrategyWeight 返回 bool
      final success = await ApiService.updateStrategyWeight(
        widget.strategy['id'],
        newWeight,
      );

      if (success == true) {
        setState(() {
          _weight = newWeight;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('权重已更新'), backgroundColor: Colors.green),
          );
          widget.onStrategyChanged?.call();
        }
      } else {
        throw Exception('更新失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      '/strategy_detail',
      arguments: widget.strategy,
    ).then((_) {
      widget.onStrategyChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.strategy['name'] ?? '未命名';
    final type = widget.strategy['type'] ?? 'unknown';
    final winRate = widget.strategy['win_rate'] ?? 0.5;
    final sharpe = widget.strategy['sharpe'] ?? 0.5;
    final drawdown = widget.strategy['max_drawdown'] ?? 0.2;
    final enabled = widget.strategy['enabled'] ?? true;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          InkWell(
            onTap: _navigateToDetail,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getScoreColor(winRate).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      type == 'trend' ? Icons.trending_up : (type == 'mean_reversion' ? Icons.compare_arrows : Icons.auto_awesome),
                      color: _getScoreColor(winRate),
                      size: 20,
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: enabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enabled ? '启用' : '禁用',
                                style: TextStyle(
                                  color: enabled ? Colors.green : Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '权重 ${(_weight * 100).toInt()}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () => _showMenu(),
                  ),
                ],
              ),
            ),
          ),

          // 指标
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetricChip('胜率', '${(winRate * 100).toInt()}%', winRate >= 0.55),
                _buildMetricChip('夏普', sharpe.toStringAsFixed(2), sharpe >= 0.8),
                _buildMetricChip('回撤', '${(drawdown * 100).toInt()}%', drawdown <= 0.15),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating ? null : _updateWeight,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('调整权重'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _toggleEnabled,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(enabled ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(enabled ? '禁用' : '启用'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabled ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: isGood ? Colors.green : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFD4AF37)),
              title: const Text('查看详情', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart, color: Color(0xFFD4AF37)),
              title: const Text('查看回测报告', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到回测报告页面
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('淘汰策略', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showKillConfirmDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showKillConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认淘汰', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要淘汰策略 "${widget.strategy['name']}" 吗？\n淘汰后策略将被移入影子副本。',
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
            child: const Text('淘汰'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 修复：killStrategy 返回 bool
      final success = await ApiService.killStrategy(widget.strategy['id']);
      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('策略已淘汰'), backgroundColor: Colors.orange),
          );
          widget.onStrategyChanged?.call();
        }
      } else {
        throw Exception('淘汰失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('淘汰失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}