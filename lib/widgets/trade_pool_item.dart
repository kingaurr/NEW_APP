// lib/widgets/trade_pool_item.dart
import 'package:flutter/material.dart';

class TradePoolItem extends StatelessWidget {
  final Map<String, dynamic> stock;
  final VoidCallback? onTrade;

  const TradePoolItem({
    super.key,
    required this.stock,
    this.onTrade,
  });

  @override
  Widget build(BuildContext context) {
    final name = stock['name'] ?? '';
    final code = stock['code'] ?? '';
    final currentPrice = (stock['current_price'] ?? 0.0).toDouble();
    final changePercent = (stock['change_percent'] ?? 0.0).toDouble();
    final score = (stock['score'] ?? 0.5).toDouble();

    Color getScoreColor(double score) {
      if (score >= 0.8) return Colors.green;
      if (score >= 0.6) return Colors.lightBlue;
      if (score >= 0.4) return Colors.orange;
      return Colors.red;
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getScoreColor(score).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('得分 ${(score * 100).toInt()}', style: TextStyle(color: getScoreColor(score), fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}