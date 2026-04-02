// lib/widgets/trade_pool_item.dart
import 'package:flutter/material.dart';
import '../pages/candidates_detail_page.dart';

/// 交易池条目组件（静态只读，无交互，避免 Release 崩溃）
class TradePoolItem extends StatelessWidget {
  final Map<String, dynamic> stock;

  const TradePoolItem({
    super.key,
    required this.stock,
  });

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

  @override
  Widget build(BuildContext context) {
    final code = stock['code'] ?? '';
    final name = stock['name'] ?? '';
    final currentPrice = (stock['current_price'] ?? 0.0).toDouble();
    final changePercent = (stock['change_percent'] ?? 0.0).toDouble();
    final score = (stock['score'] ?? 0.5).toDouble();
    final reason = stock['reason'] ?? '';
    final volume = (stock['volume'] ?? 0).toInt();
    final turnover = (stock['turnover'] ?? 0).toInt();

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getScoreColor(score).withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/candidates_detail', arguments: stock);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：名称、代码、价格、涨跌幅
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(code, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('¥${currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(color: changePercent >= 0 ? Colors.green : Colors.red, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：得分、推荐理由
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('得分 ${(score * 100).toInt()}', style: TextStyle(color: _getScoreColor(score), fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reason, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              // 第三行：成交量和成交额
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('成交量', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(_formatNumber(volume.toDouble()), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('成交额', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('¥${_formatNumber(turnover.toDouble())}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}