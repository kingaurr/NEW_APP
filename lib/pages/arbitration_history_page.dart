// lib/pages/arbitration_history_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 仲裁历史页面
class ArbitrationHistoryPage extends StatefulWidget {
  const ArbitrationHistoryPage({super.key});

  @override
  State<ArbitrationHistoryPage> createState() => _ArbitrationHistoryPageState();
}

class _ArbitrationHistoryPageState extends State<ArbitrationHistoryPage> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<dynamic> _records = [];
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });
    }

    try {
      final result = await ApiService.getArbitrationHistory(
        page: _currentPage,
        limit: 20,
      );
      if (result != null) {
        final history = result['history'] as List<dynamic>? ?? [];
        final total = result['total'] as int? ?? 0;
        setState(() {
          if (loadMore) {
            _records.addAll(history);
          } else {
            _records = history;
          }
          _total = total;
          _hasMore = _records.length < total;
        });
      }
    } catch (e) {
      if (!loadMore) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _currentPage++;
    await _loadData(loadMore: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('仲裁历史'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败: $_error', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadData(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white38, size: 64),
            SizedBox(height: 16),
            Text(
              '暂无仲裁记录',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 $_total 条记录',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _records.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _records.length) {
                // 加载更多指示器
                if (_isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  _loadMore();
                  return const SizedBox.shrink();
                }
              }
              return _buildRecordCard(_records[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(dynamic record) {
    final timestamp = record['timestamp'] as String? ?? '';
    final leftBrain = record['left_brain'] as Map<String, dynamic>? ?? {};
    final rightBrain = record['right_brain'] as Map<String, dynamic>? ?? {};
    final conflictType = record['conflict_type'] as String? ?? 'unknown';
    final arbitrationResult = record['arbitration_result'] as String? ?? '';
    final reasoning = record['reasoning'] as String? ?? '';

    Color resultColor;
    IconData resultIcon;
    String resultText;
    if (arbitrationResult == 'buy') {
      resultColor = Colors.green;
      resultIcon = Icons.trending_up;
      resultText = '买入';
    } else if (arbitrationResult == 'sell') {
      resultColor = Colors.red;
      resultIcon = Icons.trending_down;
      resultText = '卖出';
    } else {
      resultColor = Colors.grey;
      resultIcon = Icons.pause;
      resultText = '持有';
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: resultColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDetailDialog(record);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timestamp,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(resultIcon, color: resultColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          resultText,
                          style: TextStyle(color: resultColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
                          '左脑',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leftBrain['decision'] ?? '未知',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          '置信度: ${((leftBrain['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.compare_arrows, color: Colors.white54),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '右脑',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rightBrain['decision'] ?? '未知',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          '置信度: ${((rightBrain['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '冲突类型: $conflictType',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (reasoning.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reasoning,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(dynamic record) {
    final leftBrain = record['left_brain'] as Map<String, dynamic>? ?? {};
    final rightBrain = record['right_brain'] as Map<String, dynamic>? ?? {};
    final reasoning = record['reasoning'] as String? ?? '';
    final arbitrationResult = record['arbitration_result'] as String? ?? '';
    final weight = record['weight'] as num? ?? 0;
    final lockDays = record['lock_days'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '仲裁详情',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('左脑决策', leftBrain['decision'] ?? '未知'),
              _buildDetailSection('左脑置信度', '${((leftBrain['confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
              _buildDetailSection('左脑理由', leftBrain['reason'] ?? '无'),
              const Divider(color: Colors.white24),
              _buildDetailSection('右脑决策', rightBrain['decision'] ?? '未知'),
              _buildDetailSection('右脑置信度', '${((rightBrain['confidence'] ?? 0) * 100).toStringAsFixed(1)}%'),
              _buildDetailSection('右脑理由', rightBrain['reason'] ?? '无'),
              const Divider(color: Colors.white24),
              _buildDetailSection('仲裁结果', arbitrationResult),
              _buildDetailSection('最终权重', weight.toStringAsFixed(2)),
              _buildDetailSection('锁定期', '$lockDays 天'),
              _buildDetailSection('仲裁理由', reasoning),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}