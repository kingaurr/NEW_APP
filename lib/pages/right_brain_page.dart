// lib/pages/right_brain_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 右脑详情页
/// 显示右脑状态、今日信号、信号历史记录，以及每条信号的思维链（thinking_trace）
class RightBrainPage extends StatefulWidget {
  const RightBrainPage({super.key});

  @override
  State<RightBrainPage> createState() => _RightBrainPageState();
}

class _RightBrainPageState extends State<RightBrainPage> {
  bool _isLoading = true;
  Map<String, dynamic> _status = {};
  List<dynamic> _signals = [];
  String _error = '';

  // 用于记录展开的信号ID（思维链）
  final Set<String> _expandedSignalIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _error = '';
    try {
      final status = await ApiService.getRightBrainStatus();
      final signals = await ApiService.getRightBrainSignals();
      if (mounted) {
        setState(() {
          _status = status ?? {};
          _signals = signals ?? [];
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

  void _toggleThinkingTrace(String signalId) {
    setState(() {
      if (_expandedSignalIds.contains(signalId)) {
        _expandedSignalIds.remove(signalId);
      } else {
        _expandedSignalIds.add(signalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('右脑详情'),
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
                      _buildSignalsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final mode = _status['mode'] ?? '未知';
    final model = _status['model'] ?? _status['model_name'] ?? '未配置';
    final todaySignals = _status['today_signals'] ?? 0;
    final avgConfidence = (_status['avg_confidence'] ?? 0.5).toDouble();
    final costToday = (_status['cost_today'] ?? 0.0).toDouble();
    final useApi = _status['use_api'] ?? false;

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
                Icon(Icons.psychology, color: Color(0xFFD4AF37), size: 28),
                SizedBox(width: 8),
                Text('右脑状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('状态', mode),
            _buildInfoRow('模式', useApi ? 'API驱动' : '本地规则'),
            _buildInfoRow('模型', model),
            const Divider(color: Colors.grey, height: 24),
            _buildInfoRow('今日信号', todaySignals.toString()),
            _buildInfoRow('平均置信度', '${(avgConfidence * 100).toInt()}%'),
            _buildInfoRow('API调用成本', '¥${costToday.toStringAsFixed(4)}'),
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

  Widget _buildSignalsList() {
    if (_signals.isEmpty) {
      return const Card(
        color: Color(0xFF2A2A2A),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无信号记录', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('信号历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _signals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final signal = _signals[index];
            return _buildSignalCard(signal);
          },
        ),
      ],
    );
  }

  Widget _buildSignalCard(Map<String, dynamic> signal) {
    final signalId = signal['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final action = signal['action'] ?? 'hold';
    final confidence = (signal['confidence'] ?? 0.5).toDouble();
    final reason = signal['reason'] ?? '';
    final thinkingTrace = signal['thinking_trace'] ?? signal['trace']; // 兼容字段名
    final timestamp = signal['timestamp'] ?? '';
    final isExpanded = _expandedSignalIds.contains(signalId);

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleThinkingTrace(signalId),
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
              if (isExpanded && thinkingTrace != null && thinkingTrace.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 8),
                const Text('思考过程', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildThinkingTraceItems(thinkingTrace),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildThinkingTraceItems(dynamic trace) {
    if (trace is Map) {
      return trace.entries.map((entry) {
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
    } else if (trace is List) {
      return trace.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('• $item', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        );
      }).toList();
    } else if (trace is String) {
      return [
        Text(trace, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ];
    } else {
      return [
        const Text('无详细思考数据', style: TextStyle(color: Colors.grey, fontSize: 12)),
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