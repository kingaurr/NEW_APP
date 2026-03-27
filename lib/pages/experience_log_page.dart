// lib/pages/experience_log_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 实战经验日志页面
/// 查看历史经验记录（批准/淘汰/调整等）
class ExperienceLogPage extends StatefulWidget {
  const ExperienceLogPage({super.key});

  @override
  State<ExperienceLogPage> createState() => _ExperienceLogPageState();
}

class _ExperienceLogPageState extends State<ExperienceLogPage> {
  bool _isLoading = true;
  List<dynamic> _experiences = [];
  String _filterAction = '';
  int _currentPage = 0;
  final int _pageSize = 20;

  final List<String> _actionOptions = [
    '',
    'approve',
    'reject',
    'kill',
    'adjust',
    'restore',
  ];

  @override
  void initState() {
    super.initState();
    _loadExperiences();
  }

  Future<void> _loadExperiences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getExperienceLogs(limit: _pageSize);
      // 兼容后端返回 List 或 {logs: [...]} 两种格式
      List<dynamic> logsList = [];
      if (result != null) {
        if (result is List) {
          logsList = result as List<dynamic>;
        } else if (result is Map && result['logs'] is List) {
          logsList = result['logs'] as List<dynamic>;
        }
      }
      setState(() {
        _experiences = logsList;
      });
    } catch (e) {
      debugPrint('加载经验日志失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredExperiences {
    if (_filterAction.isEmpty) return _experiences;
    return _experiences.where((exp) {
      final action = exp['action'] ?? '';
      return action == _filterAction;
    }).toList();
  }

  String _getActionName(String action) {
    const names = {
      'approve': '批准',
      'reject': '拒绝',
      'kill': '淘汰',
      'adjust': '调整',
      'restore': '恢复',
    };
    return names[action] ?? action;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'kill':
        return Colors.orange;
      case 'adjust':
        return Colors.blue;
      case 'restore':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'kill':
        return Icons.delete;
      case 'adjust':
        return Icons.tune;
      case 'restore':
        return Icons.restore;
      default:
        return Icons.info;
    }
  }

  String _formatAttributionScore(double score) {
    if (score > 0.05) return '✅ 效果显著 +${(score * 100).toInt()}%';
    if (score > 0) return '📈 略有改善 +${(score * 100).toInt()}%';
    if (score < -0.05) return '❌ 效果负面 ${(score * 100).toInt()}%';
    if (score < 0) return '📉 略有下降 ${(score * 100).toInt()}%';
    return '⚖️ 效果平平';
  }

  void _showDetailDialog(Map<String, dynamic> exp) {
    final patternFlags = exp['pattern_flags'] as List? ?? [];
    final performanceBefore = exp['performance_before'];
    final performanceAfter = exp['performance_after'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            Icon(_getActionIcon(exp['action']), color: _getActionColor(exp['action']), size: 24),
            const SizedBox(width: 8),
            Text(
              _getActionName(exp['action']),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('目标', exp['target_name']),
              const Divider(color: Colors.grey),
              _buildDetailRow('时间', exp['timestamp']?.substring(0, 19) ?? ''),
              const Divider(color: Colors.grey),
              _buildDetailRow('原因', exp['reason']),
              const Divider(color: Colors.grey),
              _buildDetailRow('效果', _formatAttributionScore(exp['attribution_score'] ?? 0)),
              if (performanceBefore != null && performanceAfter != null) ...[
                const Divider(color: Colors.grey),
                _buildPerformanceRow('胜率', performanceBefore['win_rate'], performanceAfter['win_rate']),
                _buildPerformanceRow('夏普', performanceBefore['sharpe'], performanceAfter['sharpe']),
                _buildPerformanceRow('回撤', performanceBefore['max_drawdown'], performanceAfter['max_drawdown'], isReverse: true),
              ],
              if (patternFlags.isNotEmpty) ...[
                const Divider(color: Colors.grey),
                _buildDetailRow('模式标记', patternFlags.join(', ')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, double? before, double? after, {bool isReverse = false}) {
    if (before == null || after == null) return const SizedBox.shrink();

    final beforePercent = (before * 100).toInt();
    final afterPercent = (after * 100).toInt();
    final isBetter = isReverse ? after <= before : after >= before;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$beforePercent%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Icon(
                  isBetter ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isBetter ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  '$afterPercent%',
                  style: TextStyle(
                    color: isBetter ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实战经验日志'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExperiences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 筛选条件栏
                if (_filterAction.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFF2A2A2A),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_getActionName(_filterAction)),
                          onDeleted: () {
                            setState(() {
                              _filterAction = '';
                            });
                            // 无需重新加载，因为筛选是在内存中进行的
                            setState(() {});
                          },
                          backgroundColor: Colors.grey[800],
                          deleteIconColor: Colors.white,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterAction = '';
                            });
                          },
                          child: const Text('清除筛选'),
                        ),
                      ],
                    ),
                  ),

                // 经验列表
                Expanded(
                  child: _filteredExperiences.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无经验记录',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredExperiences.length,
                          itemBuilder: (context, index) {
                            final exp = _filteredExperiences[index];
                            return _buildExperienceItem(exp);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildExperienceItem(Map<String, dynamic> exp) {
    final action = exp['action'];
    final patternFlags = exp['pattern_flags'] as List? ?? [];
    final hasPattern = patternFlags.isNotEmpty;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasPattern
            ? BorderSide(color: Colors.orange.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(exp),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getActionColor(action).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActionIcon(action),
                      color: _getActionColor(action),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getActionName(action),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          exp['target_name'],
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    exp['timestamp']?.substring(5, 16) ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exp['reason'],
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatAttributionScore(exp['attribution_score'] ?? 0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  if (hasPattern) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '⚠️ 命中模式',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选日志', style: TextStyle(color: Colors.white)),
        content: DropdownButtonFormField<String>(
          value: _filterAction.isEmpty ? null : _filterAction,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '操作类型',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          items: _actionOptions.map((op) {
            return DropdownMenuItem(
              value: op.isEmpty ? null : op,
              child: Text(op.isEmpty ? '全部' : _getActionName(op)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filterAction = value ?? '';
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}