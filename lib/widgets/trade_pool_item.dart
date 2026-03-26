// lib/widgets/trade_pool_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/candidates_detail_page.dart';

/// 交易池条目组件
/// 显示AI推荐的股票，支持查看详情和买入
class TradePoolItem extends StatefulWidget {
  final Map<String, dynamic> stock;
  final VoidCallback? onTrade;

  const TradePoolItem({
    super.key,
    required this.stock,
    this.onTrade,
  });

  @override
  State<TradePoolItem> createState() => _TradePoolItemState();
}

class _TradePoolItemState extends State<TradePoolItem> {
  bool _isExpanded = false;
  bool _isBuying = false;
  final TextEditingController _sharesController = TextEditingController();

  @override
  void dispose() {
    _sharesController.dispose();
    super.dispose();
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

  Future<void> _buyStock() async {
    final sharesText = _sharesController.text.trim();
    if (sharesText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入买入数量'), backgroundColor: Colors.red),
      );
      return;
    }

    final shares = int.tryParse(sharesText);
    if (shares == null || shares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的数量'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认买入', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要买入 ${widget.stock['name']} (${widget.stock['code']}) 吗？\n'
          '当前价: ¥${widget.stock['current_price']}\n'
          '数量: ${shares}股\n'
          '预估金额: ¥${_formatNumber(widget.stock['current_price'] * shares)}',
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
            child: const Text('买入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isBuying = true;
    });

    try {
      final result = await ApiService.buyStock(
        code: widget.stock['code'],
        shares: shares,
        price: widget.stock['current_price'],
      );

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('买入成功'), backgroundColor: Colors.green),
          );
          widget.onTrade?.call();
        }
      } else {
        throw Exception(result?['message'] ?? '买入失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('买入失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
      }
    }
  }

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      '/candidates_detail',
      arguments: widget.stock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.stock['code'] ?? '';
    final name = widget.stock['name'] ?? '';
    final currentPrice = widget.stock['current_price'] ?? 0.0;
    final changePercent = widget.stock['change_percent'] ?? 0.0;
    final score = widget.stock['score'] ?? 0.5;
    final reason = widget.stock['reason'] ?? '';
    final volume = widget.stock['volume'] ?? 0;
    final turnover = widget.stock['turnover'] ?? 0;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getScoreColor(score).withOpacity(0.3),
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
                            '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changePercent >= 0 ? Colors.green : Colors.red,
                              fontSize: 11,
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
                          color: _getScoreColor(score).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '得分 ${(score * 100).toInt()}',
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '成交量',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _formatNumber(volume.toDouble()),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '成交额',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '¥${_formatNumber(turnover.toDouble())}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sharesController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '买入数量',
                              labelStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFD4AF37)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            onPressed: _isBuying ? null : _buyStock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isBuying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('买入'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // 展开按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                          if (!_isExpanded) {
                            _sharesController.clear();
                          }
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
                          Text(_isExpanded ? '收起' : '买入'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _navigateToDetail,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                      ),
                      child: const Text('详情'),
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