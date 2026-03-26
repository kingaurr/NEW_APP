// lib/widgets/ai_status_bar.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// AI状态栏组件
/// 显示左右脑状态、外脑状态、守门员建议数量
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

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 并行获取所有状态
      final results = await Future.wait([
        ApiService.getRightBrainStatus(),
        ApiService.getLeftBrainStatus(),
        ApiService.getOuterBrainStatus(),
        ApiService.getPendingAdviceCount(),
      ]);

      if (results[0] != null) _rightBrain = results[0];
      if (results[1] != null) _leftBrain = results[1];
      if (results[2] != null) _outerBrain = results[2];
      if (results[3] != null) {
        _pendingSuggestions = results[3]['count'] ?? 0;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载AI状态失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
      case 'healthy':
      case 'running':
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

  Widget _buildStatusChip(String label, String status, {String? extra}) {
    final color = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (extra != null) ...[
            const SizedBox(width: 4),
            Text(
              extra,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToBrainDetail(String brainType) {
    Navigator.pushNamed(
      context,
      '/brain_detail',
      arguments: {'type': brainType},
    );
  }

  void _navigateToGuardianSuggestions() {
    Navigator.pushNamed(context, '/guardian_suggestions');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: _loadStatus,
            ),
          ],
        ),
      );
    }

    final rightStatus = _rightBrain['status'] ?? 'unknown';
    final leftStatus = _leftBrain['status'] ?? 'unknown';
    final outerStatus = _outerBrain['status'] ?? 'unknown';
    final outerLastRun = _outerBrain['last_run_time'];
    final outerNewRules = _outerBrain['new_rules_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI状态',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('right'),
                  child: _buildStatusChip('右脑', rightStatus),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('left'),
                  child: _buildStatusChip('左脑', leftStatus),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToBrainDetail('outer'),
                  child: _buildStatusChip(
                    '外脑',
                    outerStatus,
                    extra: outerNewRules > 0 ? '+$outerNewRules' : null,
                  ),
                ),
              ),
            ],
          ),
          if (outerLastRun != null) ...[
            const SizedBox(height: 8),
            Text(
              '外脑上次运行: ${_formatDate(outerLastRun)}',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
          const SizedBox(height: 8),
          // 守门员建议红点
          GestureDetector(
            onTap: _navigateToGuardianSuggestions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _pendingSuggestions > 0
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    '守门员建议',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  if (_pendingSuggestions > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_pendingSuggestions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      '无新建议',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}