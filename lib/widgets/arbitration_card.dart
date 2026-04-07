// lib/widgets/arbitration_card.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/arbitration_detail_page.dart';

/// AI页面 - 仲裁记录卡片
/// 显示最新一次左右脑冲突的仲裁摘要，点击可查看详情
class ArbitrationCard extends StatefulWidget {
  const ArbitrationCard({super.key});

  @override
  State<ArbitrationCard> createState() => _ArbitrationCardState();
}

class _ArbitrationCardState extends State<ArbitrationCard> {
  Map<String, dynamic> _arbitration = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getLatestArbitration();
      if (mounted) {
        setState(() {
          _arbitration = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('加载失败: $_error', style: const TextStyle(color: Colors.grey)),
              TextButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_arbitration.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('暂无仲裁记录', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final left = _arbitration['left_brain'] ?? {};
    final right = _arbitration['right_brain'] ?? {};
    final result = _arbitration['arbitration_result'] ?? '未知';
    final conflictType = _arbitration['conflict_type'] ?? '未知';
    final timestamp = _arbitration['timestamp'] ?? '';

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArbitrationDetailPage()),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel, size: 20),
                  const SizedBox(width: 8),
                  const Text('最新仲裁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_formatTime(timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDecisionChip('左脑', left['decision'] ?? '?', left['confidence'] ?? 0.0),
                  ),
                  const Icon(Icons.vs, color: Colors.grey),
                  Expanded(
                    child: _buildDecisionChip('右脑', right['decision'] ?? '?', right['confidence'] ?? 0.0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConflictColor(conflictType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.scale, size: 14, color: _getConflictColor(conflictType)),
                    const SizedBox(width: 4),
                    Text('冲突: $conflictType', style: TextStyle(color: _getConflictColor(conflictType), fontSize: 12)),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 4),
                    Text('裁决: $result', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('查看详情', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFD4AF37)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionChip(String title, String decision, double confidence) {
    Color decisionColor;
    if (decision == 'buy') decisionColor = Colors.green;
    else if (decision == 'sell') decisionColor = Colors.red;
    else decisionColor = Colors.grey;
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: decisionColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(decision.toUpperCase(), style: TextStyle(color: decisionColor, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text('${(confidence * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getConflictColor(String type) {
    switch (type) {
      case 'direction': return Colors.orange;
      case 'position': return Colors.purple;
      case 'time': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        if (diff.inHours == 0) return '${diff.inMinutes}分钟前';
        return '${diff.inHours}小时前';
      } else if (diff.inDays == 1) {
        return '昨天';
      } else {
        return '${diff.inDays}天前';
      }
    } catch (e) {
      return '';
    }
  }
}