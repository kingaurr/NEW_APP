// lib/widgets/ai_status_bar.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class AIStatusBar extends StatefulWidget {
  final VoidCallback? onRefresh;
  const AIStatusBar({super.key, this.onRefresh});

  @override
  State<AIStatusBar> createState() => _AIStatusBarState();
}

class _AIStatusBarState extends State<AIStatusBar> {
  bool _isLoading = true;
  Map<String, dynamic> _rightBrain = {};
  Map<String, dynamic> _leftBrain = {};
  Map<String, dynamic> _outerBrain = {};
  int _pendingSuggestions = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Map<String, dynamic> _safeParseMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  int _safeListLength(dynamic data) {
    if (data == null) return 0;
    if (data is List) return data.length;
    if (data is Map) return data.keys.length;
    return 0;
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getRightBrainStatus().catchError((e) {
          debugPrint('getRightBrainStatus 错误: $e');
          return {'mode': 'error', 'model': ''};
        }),
        ApiService.getLeftBrainStatus().catchError((e) {
          debugPrint('getLeftBrainStatus 错误: $e');
          return {'mode': 'error', 'model': ''};
        }),
        ApiService.getEvolutionReport().catchError((e) {
          debugPrint('getEvolutionReport 错误: $e');
          return {'status': 'idle'};
        }),
        ApiService.getPendingAdviceCount().catchError((e) {
          debugPrint('getPendingAdviceCount 错误: $e');
          return 0;
        }),
      ]);

      _rightBrain = _safeParseMap(results[0]);
      _leftBrain = _safeParseMap(results[1]);
      final report = _safeParseMap(results[2]);
      _outerBrain = {
        'status': report['status'] ?? 'idle',
        'last_run_time': report['last_run'],
        'new_rules_count': _safeListLength(report['new_rules']),
      };
      final pendingData = results[3];
      if (pendingData != null) {
        if (pendingData is int) {
          _pendingSuggestions = pendingData;
        } else if (pendingData is Map) {
          _pendingSuggestions = (pendingData['count'] as int?) ?? 0;
        } else if (pendingData is List) {
          _pendingSuggestions = pendingData.length;
        } else {
          _pendingSuggestions = 0;
        }
      } else {
        _pendingSuggestions = 0;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('加载AI状态失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  String _formatModelName(String model) {
    if (model == 'deepseek-chat') return 'DeepSeek';
    if (model == 'qwen3.5-plus') return '千问';
    if (model.isEmpty) return '';
    return model;
  }

  Color _getModeColor(String mode) {
    if (mode == 'API_DRIVEN') return Colors.green;
    if (mode == 'LOCAL_RULE') return Colors.orange;
    if (mode == 'error') return Colors.red;
    return Colors.grey;
  }

  // 修改状态文字：在线 / 离线(本地) / 异常
  String _getModeText(String mode) {
    if (mode == 'API_DRIVEN') return '在线';
    if (mode == 'LOCAL_RULE') return '离线(本地)';
    if (mode == 'error') return '异常';
    return mode.isEmpty ? '未知' : mode;
  }

  Color _getOuterStatusColor(String status) {
    switch (status) {
      case 'running':
      case 'completed':
        return Colors.green;
      case 'idle':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getOuterStatusText(String status) {
    switch (status) {
      case 'running':
        return '运行中';
      case 'completed':
        return '已完成';
      case 'idle':
        return '待执行';
      case 'error':
        return '异常';
      default:
        return status;
    }
  }

  Widget _buildBrainChip(String label, Map<String, dynamic> data) {
    final mode = data['mode']?.toString() ?? 'unknown';
    final model = data['model']?.toString() ?? '';
    final color = _getModeColor(mode);
    final modeText = _getModeText(mode);
    final modelDisplay = _formatModelName(model);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(width: 4),
          Text(modeText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          if (modelDisplay.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text('($modelDisplay)', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  void _navigateToBrainDetail(String brainType) {
    Navigator.pushNamed(context, '/brain_detail', arguments: {'type': brainType});
  }

  void _navigateToGuardianSuggestions() {
    Navigator.pushNamed(context, '/guardian_suggestions');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes == 0) return '刚刚';
          return '${diff.inMinutes}分钟前';
        }
        return '${diff.inHours}小时前';
      } else if (diff.inDays == 1) {
        return '昨天';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}天前';
      }
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12))),
            IconButton(icon: const Icon(Icons.refresh, size: 16), onPressed: _loadStatus),
          ],
        ),
      );
    }

    final outerStatus = _outerBrain['status']?.toString() ?? 'idle';
    final outerLastRun = _outerBrain['last_run_time'];
    final outerNewRules = _outerBrain['new_rules_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI状态', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('right'),
                  child: _buildBrainChip('右脑', _rightBrain),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('left'),
                  child: _buildBrainChip('左脑', _leftBrain),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('outer'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getOuterStatusColor(outerStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: _getOuterStatusColor(outerStatus), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('外脑', style: TextStyle(color: Colors.white, fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(_getOuterStatusText(outerStatus), style: TextStyle(color: _getOuterStatusColor(outerStatus), fontSize: 11, fontWeight: FontWeight.w500)),
                        if (outerNewRules > 0) ...[
                          const SizedBox(width: 4),
                          Text('+$outerNewRules', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (outerLastRun != null) ...[
            const SizedBox(height: 8),
            Text('外脑上次运行: ${_formatDate(outerLastRun.toString())}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _navigateToGuardianSuggestions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _pendingSuggestions > 0 ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('守门员建议', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  if (_pendingSuggestions > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$_pendingSuggestions', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else
                    const Text('无新建议', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}