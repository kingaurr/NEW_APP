// lib/pages/arbitration_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class ArbitrationDetailPage extends StatefulWidget {
  const ArbitrationDetailPage({super.key, this.arbitrationId});

  final String? arbitrationId;

  @override
  State<ArbitrationDetailPage> createState() => _ArbitrationDetailPageState();
}

class _ArbitrationDetailPageState extends State<ArbitrationDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _arbitration = {};
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('仲裁详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('加载失败: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildDecisionCard('左脑', _arbitration['left_brain']),
                      const SizedBox(height: 16),
                      _buildDecisionCard('右脑', _arbitration['right_brain']),
                      const SizedBox(height: 24),
                      _buildArbitrationResult(),
                      const SizedBox(height: 24),
                      _buildReasoning(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final timestamp = _arbitration['timestamp'] ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, size: 28),
                const SizedBox(width: 8),
                const Text('仲裁记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('时间: $timestamp', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConflictColor(_arbitration['conflict_type']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '冲突类型: ${_arbitration['conflict_type'] ?? '未知'}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(String title, dynamic decision) {
    if (decision == null) return const SizedBox.shrink();
    final action = decision['decision'] ?? '未知';
    final confidence = (decision['confidence'] ?? 0.0).toDouble();
    final reason = decision['reason'] ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(title == '左脑' ? Icons.psychology : Icons.bolt, size: 24),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: action == 'buy' ? Colors.green : (action == 'sell' ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(action.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: confidence, backgroundColor: Colors.grey[800]),
            const SizedBox(height: 8),
            Text('置信度: ${(confidence * 100).toInt()}%', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text('理由: $reason', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildArbitrationResult() {
    final result = _arbitration['arbitration_result'] ?? '未知';
    final weight = _arbitration['weight'] ?? 0.0;
    final lockDays = _arbitration['lock_days'] ?? 0;
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.scale, size: 28),
                SizedBox(width: 8),
                Text('仲裁结果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('最终决策: $result', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('权重因子: $weight', style: const TextStyle(color: Colors.grey)),
            Text('执行锁定期: $lockDays 天', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoning() {
    final reasoning = _arbitration['reasoning'] ?? '';
    if (reasoning.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('裁决依据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(reasoning, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Color _getConflictColor(String? type) {
    switch (type) {
      case 'direction':
        return Colors.orange;
      case 'position':
        return Colors.purple;
      case 'time':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}