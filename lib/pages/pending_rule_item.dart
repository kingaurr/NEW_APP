// lib/widgets/pending_rule_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 待审核规则条目组件
/// 支持显示来源（外脑/社区）和 LLM 评分，提供批准/拒绝按钮（需指纹）
class PendingRuleItem extends StatefulWidget {
  final Map<String, dynamic> rule;
  final VoidCallback onStatusChanged;

  const PendingRuleItem({
    super.key,
    required this.rule,
    required this.onStatusChanged,
  });

  @override
  State<PendingRuleItem> createState() => _PendingRuleItemState();
}

class _PendingRuleItemState extends State<PendingRuleItem> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    if (_isProcessing) return;
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以批准规则',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final success = await ApiService.approveRule(widget.rule['id']);
      if (success) {
        _showMessage('规则已批准');
        widget.onStatusChanged();
      } else {
        _showMessage('批准失败', isError: true);
      }
    } catch (e) {
      _showMessage('操作异常: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    if (_isProcessing) return;
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以拒绝规则',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，操作取消', isError: true);
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final success = await ApiService.rejectRule(widget.rule['id']);
      if (success) {
        _showMessage('规则已拒绝');
        widget.onStatusChanged();
      } else {
        _showMessage('拒绝失败', isError: true);
      }
    } catch (e) {
      _showMessage('操作异常: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ruleId = widget.rule['id'] ?? '';
    final name = widget.rule['name'] ?? ruleId;
    final source = widget.rule['source'] ?? '外脑';
    final llmScore = widget.rule['llm_score'] ?? widget.rule['quality_score'];
    final winRate = widget.rule['win_rate'] ?? 0.0;
    final maxDrawdown = widget.rule['max_drawdown'] ?? 0.0;
    final reason = widget.rule['reason'] ?? '';

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: source == '社区' ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    source,
                    style: TextStyle(color: source == '社区' ? Colors.blue : Colors.purple, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (llmScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LLM评分: ${llmScore is int ? llmScore : (llmScore * 100).toInt()}',
                      style: const TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '胜率: ${(winRate * 100).toInt()}%',
                  style: const TextStyle(color: Colors.green, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  '最大回撤: ${(maxDrawdown * 100).toInt()}%',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : _reject,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('拒绝'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('批准'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}