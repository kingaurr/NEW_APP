// lib/pages/left_brain_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 左脑详情页
/// 显示左脑状态、今日决策、决策历史记录，以及每条决策的辩论日志（debate_log）
class LeftBrainPage extends StatefulWidget {
  const LeftBrainPage({super.key});

  @override
  State<LeftBrainPage> createState() => _LeftBrainPageState();
}

class _LeftBrainPageState extends State<LeftBrainPage> {
  bool _isLoading = true;
  Map<String, dynamic> _status = {};
  List<dynamic> _decisions = [];
  String _error = '';

  final Set<String> _expandedDecisionIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _error = '';
    try {
      final status = await ApiService.getLeftBrainStatus();
      final decisions = await ApiService.getLeftBrainDecisions();
      if (mounted) {
        setState(() {
          _status = status ?? {};
          _decisions = decisions ?? [];
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

  void _toggleDebateLog(String decisionId) {
    if (!mounted) return;
    setState(() {
      if (_expandedDecisionIds.contains(decisionId)) {
        _expandedDecisionIds.remove(decisionId);
      } else {
        _expandedDecisionIds.add(decisionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('左脑详情'),
        backgroundColor: const Color(0xFF1E1E1E),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildDecisionsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final mode = _status['mode'] ?? '未知';
    final model = _status['model'] ?? _status['model_name'] ?? '未配置';
    final statusText = _status['status'] ?? _status['state'] ?? '未知';
    final todayDecisions = _status['today_decisions'] ?? 0;
    final avgConfidence = (_status['avg_confidence'] ?? 0.5).toDouble();
    final costToday = (_status['cost_today'] ?? 0.0).toDouble();
    final fuseTriggered = _status['fuse_triggered'] ?? false;

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Color(0xFFD4AF37), size: 28),
                SizedBox(width: 8),
                Text('左脑状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('状态', statusText),
            _buildInfoRow('模式', mode == 'API_DRIVEN' ? 'API驱动' : mode),
            _buildInfoRow('模型', model),
            const Divider(color: Colors.grey, height: 24),
            _buildInfoRow('今日决策', todayDecisions.toString()),
            _buildInfoRow('平均置信度', '${(avgConfidence * 100).toInt()}%'),
            _buildInfoRow('API调用成本', '¥${costToday.toStringAsFixed(4)}'),
            const Divider(color: Colors.grey, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('熔断状态', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: fuseTriggered ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fuseTriggered ? '已触发' : '正常',
                    style: TextStyle(
                      color: fuseTriggered ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDecisionsList() {
    if (_decisions.isEmpty) {
      return Card(
        color: const Color(0xFF2A2A2A),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.shield, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('暂无决策记录', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                '请等待左脑生成决策',
                style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('决策历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _decisions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final decision = _decisions[index];
            return _buildDecisionCard(decision);
          },
        ),
      ],
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> decision) {
    final decisionId = decision['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final action = decision['action'] ?? decision['decision'] ?? 'hold';
    final confidence = (decision['confidence'] ?? 0.5).toDouble();
    final reason = decision['reason'] ?? '';
    final debateLog = decision['debate_log'] ?? decision['log'];
    final timestamp = decision['timestamp'] ?? '';
    final isExpanded = _expandedDecisionIds.contains(decisionId);

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleDebateLog(decisionId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: action == 'buy'
                          ? Colors.green.withOpacity(0.2)
                          : (action == 'sell' ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      action.toUpperCase(),
                      style: TextStyle(
                        color: action == 'buy' ? Colors.green : (action == 'sell' ? Colors.red : Colors.grey),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTime(timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('置信度: ${(confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFD4AF37),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reason,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (isExpanded && debateLog != null && debateLog.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 8),
                const Text('辩论日志', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildDebateLogItems(debateLog),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDebateLogItems(dynamic log) {
    if (log is Map) {
      return log.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.key}: ', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList();
    } else if (log is List) {
      return log.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('• $item', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        );
      }).toList();
    } else if (log is String) {
      return [
        Text(log, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ];
    } else {
      return [
        const Text('无详细辩论数据', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ];
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
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
      return timestamp.toString().substring(0, 16);
    }
  }
}