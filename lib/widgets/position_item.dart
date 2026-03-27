// lib/widgets/position_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/position_detail_page.dart';

/// 持仓条目组件
/// 显示单只股票的持仓信息，支持点击查看详情
class PositionItem extends StatefulWidget {
  final Map<String, dynamic> position;
  final VoidCallback? onPositionChanged;

  const PositionItem({
    super.key,
    required this.position,
    this.onPositionChanged,
  });

  @override
  State<PositionItem> createState() => _PositionItemState();
}

class _PositionItemState extends State<PositionItem> {
  bool _isExpanded = false;
  bool _isSelling = false;

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getPnlColor(double pnl) {
    if (pnl > 0) return Colors.green;
    if (pnl < 0) return Colors.red;
    return Colors.grey;
  }

  String _getPnlPrefix(double pnl) {
    if (pnl > 0) return '+';
    if (pnl < 0) return '-';
    return '';
  }

  Future<void> _sellPosition() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认卖出', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要卖出 ${widget.position['name']} (${widget.position['code']}) 吗？\n'
          '数量: ${widget.position['shares']}股\n'
          '当前价: ¥${widget.position['current_price']}\n'
          '预估金额: ¥${_formatNumber(widget.position['market_value'])}',
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
            child: const Text('卖出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSelling = true;
    });

    try {
      // 修复：sellPosition 第一个参数是位置参数 code，第二个是命名参数 shares
      final success = await ApiService.sellPosition(
        widget.position['code'],
        shares: widget.position['shares'],
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('卖出成功'), backgroundColor: Colors.green),
          );
          widget.onPositionChanged?.call();
        }
      } else {
        throw Exception('卖出失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('卖出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelling = false;
        });
      }
    }
  }

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      '/position_detail',
      arguments: widget.position,
    ).then((_) {
      widget.onPositionChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.position['code'] ?? '';
    final name = widget.position['name'] ?? '';
    final currentPrice = widget.position['current_price'] ?? 0.0;
    final shares = widget.position['shares'] ?? 0;
    final marketValue = widget.position['market_value'] ?? 0.0;
    final pnl = widget.position['pnl'] ?? 0.0;
    final pnlPercent = widget.position['pnl_percent'] ?? 0.0;
    final stopLoss = widget.position['stop_loss'];
    final takeProfit = widget.position['take_profit'];

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPnlColor(pnl).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: _navigateToDetail,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 主要信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                            '¥${currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${shares}股',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '市值',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '¥${_formatNumber(marketValue)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '盈亏',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_getPnlPrefix(pnl)}¥${_formatNumber(pnl.abs())}',
                              style: TextStyle(
                                color: _getPnlColor(pnl),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_getPnlPrefix(pnlPercent)}${(pnlPercent.abs() * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: _getPnlColor(pnl),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 扩展信息
            if (_isExpanded) ...[
              const Divider(color: Colors.grey, height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (stopLoss != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '止损价',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '¥${stopLoss.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    if (takeProfit != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '止盈价',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '¥${takeProfit.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // 操作按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(_isExpanded ? '收起' : '详情'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSelling ? null : _sellPosition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: _isSelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('卖出'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}