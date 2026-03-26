// lib/pages/brain_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 左右脑详情页面
/// 显示右脑/左脑的详细状态、信号列表、决策记录
class BrainDetailPage extends StatefulWidget {
  final String brainType; // 'right' 或 'left'

  const BrainDetailPage({super.key, required this.brainType});

  @override
  State<BrainDetailPage> createState() => _BrainDetailPageState();
}

class _BrainDetailPageState extends State<BrainDetailPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic> _status = {};
  List<dynamic> _records = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.brainType == 'right') {
        final status = await ApiService.getRightBrainStatus();
        final signals = await ApiService.getRightBrainSignals();
        if (status != null) _status = status;
        if (signals != null) _records = signals;
      } else {
        final status = await ApiService.getLeftBrainStatus();
        final decisions = await ApiService.getLeftBrainDecisions();
        if (status != null) _status = status;
        if (decisions != null) _records = decisions;
      }
    } catch (e) {
      debugPrint('加载${widget.brainType == 'right' ? '右脑' : '左脑'}数据失败: $e');
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

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadData();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'normal':
      case 'healthy':
        return '正常';
      case 'warning':
      case 'degraded':
        return '预警';
      case 'error':
      case 'failed':
        return '异常';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
      case 'healthy':
        return Colors.green;
      case 'warning':
      case 'degraded':
        return Colors.orange;
      case 'error':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRight = widget.brainType == 'right';
    final title = isRight ? '右脑详情' : '左脑详情';
    final mode = _status['mode'] ?? (isRight ? 'deepseek-chat' : 'qwen-plus');
    final model = _status['model'] ?? (isRight ? 'DeepSeek' : '千问');
    final status = _status['status'] ?? 'unknown';
    final todayCount = _status['today_signals'] ?? _status['today_decisions'] ?? 0;
    final avgConfidence = _status['avg_confidence'] ?? 0.5;
    final apiCalls = _status['api_calls'] ?? 0;
    final cost = _status['cost'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 状态卡片
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _getStatusColor(status).withOpacity(0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '状态: ${_getStatusText(status)}',
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '模式: $mode',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '$todayCount',
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isRight ? '今日信号' : '今日决策',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${(avgConfidence * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            '平均置信度',
                                            style: TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            apiCalls.toString(),
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'API调用',
                                            style: TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '预估成本',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '¥${cost.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 记录列表
                        if (_records.isNotEmpty) ...[
                          const Text(
                            isRight ? '最近信号' : '最近决策',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._records.take(10).map((record) => _buildRecordItem(record)),
                        ] else ...[
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              isRight ? '暂无信号记录' : '暂无决策记录',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final isRight = widget.brainType == 'right';
    final timestamp = record['timestamp'];
    final confidence = record['confidence'] ?? 0.5;

    if (isRight) {
      final action = record['action'] ?? 'hold';
      final code = record['code'] ?? '';
      final name = record['name'] ?? '';
      final price = record['price'] ?? 0.0;

      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: action == 'buy'
                          ? Colors.green.withOpacity(0.2)
                          : (action == 'sell' ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action == 'buy'
                          ? Icons.trending_up
                          : (action == 'sell' ? Icons.trending_down : Icons.remove),
                      color: action == 'buy'
                          ? Colors.green
                          : (action == 'sell' ? Colors.red : Colors.grey),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$name ($code)',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text(
                    _formatDate(timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    action == 'buy' ? '买入' : (action == 'sell' ? '卖出' : '持有'),
                    style: TextStyle(
                      color: action == 'buy'
                          ? Colors.green
                          : (action == 'sell' ? Colors.red : Colors.grey),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¥${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '置信度 ${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: confidence >= 0.7 ? Colors.green : Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      final decision = record['decision'] ?? '';
      final reason = record['reason'] ?? '';
      final approved = record['approved'] ?? false;

      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    approved ? Icons.check_circle : Icons.cancel,
                    color: approved ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      decision,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      approved ? '已批准' : '已否决',
                      style: TextStyle(
                        color: approved ? Colors.green : Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '置信度 ${(confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: confidence >= 0.7 ? Colors.green : Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}