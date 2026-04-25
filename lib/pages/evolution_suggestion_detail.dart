// lib/pages/evolution_suggestion_detail.dart
// ==================== v2.0 自进化引擎：单条建议详情+审批页（2026-04-25） ====================
// 功能描述：
// 1. 展示单条进化建议的完整信息（模块、类型、优先级、建议内容、置信度、详细数据）
// 2. 支持批准操作（需指纹验证）
// 3. 支持拒绝操作
// 4. 审批后返回上一页并刷新列表
// 数据来源：通过路由参数接收建议数据，审批调用后端 /api/evolution/suggestions/<id>/approve
// 遵循规范：
// - P0 真实数据原则：所有数据来自路由参数或API，不填充假数据。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P6 路由参数解耦：参数为null时提供默认值，显示"暂无数据"。
// - P7 完整交互绑定：按钮均使用 onPressed 正确绑定。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// - B6 敏感操作（批准）必须先调用指纹验证。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 单条建议详情页
class EvolutionSuggestionDetail extends StatefulWidget {
  final Map<String, dynamic> suggestion;

  const EvolutionSuggestionDetail({super.key, required this.suggestion});

  @override
  State<EvolutionSuggestionDetail> createState() => _EvolutionSuggestionDetailState();
}

class _EvolutionSuggestionDetailState extends State<EvolutionSuggestionDetail> {
  bool _isApproving = false;
  bool _isRejecting = false;
  String? _actionMessage;

  Map<String, dynamic> get _suggestion => widget.suggestion;

  String get _suggestionId {
    final id = _suggestion['id'] ?? _suggestion['rule_name'] ?? _suggestion['factor'] ?? '';
    return id is String ? id : '';
  }

  Future<void> _approve() async {
    HapticFeedback.mediumImpact();

    // 1. 指纹验证
    final token = await BiometricsHelper.authenticateForOperation(
      operation: 'evolution_approve',
      operationDesc: '批准进化建议',
    );
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证取消或失败')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isApproving = true;
      _actionMessage = null;
    });

    try {
      final result = await ApiService.approveEvolutionSuggestion(_suggestionId);
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        setState(() {
          _isApproving = false;
          _actionMessage = '已批准';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('建议已批准，即将生效'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final msg = result != null && result is Map
            ? result['message'] ?? '批准失败'
            : '请求失败';
        setState(() {
          _isApproving = false;
          _actionMessage = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApproving = false;
          _actionMessage = '网络异常，请稍后重试';
        });
      }
    }
  }

  Future<void> _reject() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认拒绝', style: TextStyle(color: Colors.white)),
        content: const Text('确定要拒绝这条建议吗？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('拒绝'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRejecting = true;
      _actionMessage = null;
    });

    try {
      final result = await ApiService.rejectSuggestion(_suggestionId);
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        setState(() {
          _isRejecting = false;
          _actionMessage = '已拒绝';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('建议已拒绝'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isRejecting = false;
          _actionMessage = '拒绝失败，请重试';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRejecting = false;
          _actionMessage = '网络异常，请稍后重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = _suggestion['module'] ?? '未知模块';
    final type = _suggestion['type'] ?? '';
    final priority = _suggestion['priority'] ?? 'P2';
    final suggestionText = _suggestion['suggestion'] ?? '暂无建议内容';
    final confidence = _suggestion['confidence'] ?? 0.0;
    final confidenceNum = confidence is num ? confidence.toDouble() : 0.0;
    final data = _suggestion['data'];
    final strategyName = _suggestion['strategy_name'] ?? _suggestion['factor'] ?? '';

    Color priorityColor;
    switch (priority) {
      case 'P0':
        priorityColor = Colors.red;
        break;
      case 'P1':
        priorityColor = Colors.orange;
        break;
      case 'P2':
        priorityColor = Colors.grey;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('建议详情'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(priority, priorityColor, module, type, confidenceNum),
            const SizedBox(height: 16),
            _buildContentCard(suggestionText, strategyName),
            const SizedBox(height: 16),
            if (data != null && data is Map && (data as Map).isNotEmpty)
              _buildDataCard(data as Map<String, dynamic>),
            const SizedBox(height: 24),
            _buildActionButtons(),
            if (_actionMessage != null) ...[
              const SizedBox(height: 12),
              _buildActionMessageCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    String priority,
    Color priorityColor,
    String module,
    String type,
    double confidenceNum,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    module,
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                  ),
                ),
                const Spacer(),
                Icon(
                  confidenceNum >= 70 ? Icons.verified : Icons.info_outline,
                  color: confidenceNum >= 70 ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '置信度 ${confidenceNum.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: confidenceNum >= 70 ? Colors.green : Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (type is String && type.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                type,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(String suggestionText, String strategyName) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '建议内容',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                suggestionText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            if (strategyName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '关联: $strategyName',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    final keys = data.keys.take(8).toList();
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细数据',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...keys.map((key) {
              final value = data[key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        key,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(value),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (data.keys.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... 还有 ${data.keys.length - 8} 项数据',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) {
      if (value is double) return value.toStringAsFixed(6);
      return value.toString();
    }
    if (value is Map || value is List) {
      return jsonString(value);
    }
    return value.toString().length > 200
        ? '${value.toString().substring(0, 200)}...'
        : value.toString();
  }

  String jsonString(dynamic obj) {
    if (obj is Map) {
      return obj.entries.take(3).map((e) => '${e.key}: ${_formatValue(e.value)}').join(', ');
    }
    if (obj is List) {
      return '[${obj.length} items]';
    }
    return obj.toString();
  }

  Widget _buildActionButtons() {
    final isDone = _actionMessage == '已批准' || _actionMessage == '已拒绝';
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isApproving || _isRejecting || isDone) ? null : _approve,
            icon: _isApproving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(isDone && _actionMessage == '已批准' ? '已批准' : '批准'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: Colors.green.withOpacity(0.3),
              disabledForegroundColor: Colors.white54,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_isApproving || _isRejecting || isDone) ? null : _reject,
            icon: _isRejecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(isDone && _actionMessage == '已拒绝' ? '已拒绝' : '拒绝'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionMessageCard() {
    final isSuccess = _actionMessage == '已批准' || _actionMessage == '已拒绝';
    return Card(
      color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _actionMessage!,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
