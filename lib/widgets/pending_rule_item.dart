// lib/widgets/pending_rule_item.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../pages/rule_detail_page.dart';
import 'evidence_viewer.dart';

/// 待审核规则条目组件
/// 用于展示外脑生成的待审核规则，支持批准/拒绝操作
class PendingRuleItem extends StatefulWidget {
  final Map<String, dynamic> rule;
  final VoidCallback? onStatusChanged;

  const PendingRuleItem({
    super.key,
    required this.rule,
    this.onStatusChanged,
  });

  @override
  State<PendingRuleItem> createState() => _PendingRuleItemState();
}

class _PendingRuleItemState extends State<PendingRuleItem> {
  bool _isProcessing = false;
  bool _showEvidence = false;

  Future<void> _approve() async {
    final confirmed = await _showConfirmDialog(
      title: '批准规则',
      content: '确定要批准规则 "${widget.rule['name']}" 吗？\n批准后规则将立即生效。',
      confirmText: '批准',
      isDanger: false,
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 修复：使用 approveRule 方法，返回 bool
      final success = await ApiService.approveRule(
        widget.rule['id'] ?? widget.rule['rule_id'],
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('规则已批准，正在生效'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStatusChanged?.call();
        }
      } else {
        throw Exception('批准失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批准失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    final reason = await _showReasonDialog();
    if (reason == null) return;

    final confirmed = await _showConfirmDialog(
      title: '拒绝规则',
      content: '确定要拒绝规则 "${widget.rule['name']}" 吗？',
      confirmText: '拒绝',
      isDanger: true,
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 修复：使用 rejectRule 方法，返回 bool
      final success = await ApiService.rejectRule(
        widget.rule['id'] ?? widget.rule['rule_id'],
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('规则已拒绝'),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onStatusChanged?.call();
        }
      } else {
        throw Exception('拒绝失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒绝失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required bool isDanger,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('拒绝原因', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '请输入拒绝原因（可选）',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      '/rule_detail',
      arguments: widget.rule,
    );
  }

  Widget _buildMetricChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? const Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.rule['backtest_metrics'] ?? {};
    final winRate = metrics['win_rate'] ?? 0;
    final sharpe = metrics['sharpe'] ?? 0;
    final drawdown = metrics['max_drawdown'] ?? 0;
    final profitRatio = metrics['profit_ratio'] ?? 0;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          InkWell(
            onTap: _navigateToDetail,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.rule,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rule['name'] ?? '未命名规则',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '来源: ${widget.rule['source'] ?? '外脑'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '待审核',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 回测指标
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricChip(
                  '胜率',
                  '${(winRate * 100).toInt()}%',
                  color: winRate >= 0.55 ? Colors.green : Colors.red,
                ),
                _buildMetricChip(
                  '夏普',
                  sharpe.toStringAsFixed(2),
                  color: sharpe >= 0.8 ? Colors.green : Colors.red,
                ),
                _buildMetricChip(
                  '回撤',
                  '${(drawdown * 100).toInt()}%',
                  color: drawdown <= 0.15 ? Colors.green : Colors.red,
                ),
                _buildMetricChip(
                  '盈亏比',
                  profitRatio.toStringAsFixed(1),
                  color: profitRatio >= 1.5 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _reject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _approve,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isProcessing ? '处理中...' : '批准'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 展开证据区域
          if (_showEvidence && widget.rule['evidence'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: EvidenceViewer(
                evidence: widget.rule['evidence'],
                initiallyExpanded: true,
              ),
            ),

          // 显示证据按钮
          if (widget.rule['evidence'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showEvidence = !_showEvidence;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showEvidence ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(_showEvidence ? '收起证据' : '查看证据'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}