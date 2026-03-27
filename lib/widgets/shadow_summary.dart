// lib/widgets/shadow_summary.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 影子账户摘要组件
/// 显示影子账户与实盘账户的对比信息
class ShadowSummary extends StatefulWidget {
  final VoidCallback? onApplySuggestion;

  const ShadowSummary({super.key, this.onApplySuggestion});

  @override
  State<ShadowSummary> createState() => _ShadowSummaryState();
}

class _ShadowSummaryState extends State<ShadowSummary> {
  bool _isLoading = true;
  bool _isApplying = false;
  Map<String, dynamic> _shadowData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadShadowData();
  }

  Future<void> _loadShadowData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getShadowStatus();
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _shadowData = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取影子账户信息失败';
        });
      }
    } catch (e) {
      debugPrint('加载影子账户数据失败: $e');
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

  String _formatNumber(double value) {
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}亿';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Color _getPnlColor(double pnl) {
    if (pnl > 0) return Colors.green;
    if (pnl < 0) return Colors.red;
    return Colors.grey;
  }

  String _getComparisonText(double diff) {
    if (diff > 0) return '优于';
    if (diff < 0) return '劣于';
    return '持平';
  }

  Future<void> _applySuggestion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认应用建议', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要将影子账户的配置应用到实盘吗？\n'
          '当前实盘${_getComparisonText(_shadowData['diff'])}影子账户。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('应用'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isApplying = true;
    });

    try {
      // 修复：applyShadowSuggestion 返回 bool
      final success = await ApiService.applyShadowSuggestion();
      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建议已应用'), backgroundColor: Colors.green),
          );
          widget.onApplySuggestion?.call();
          _loadShadowData();
        }
      } else {
        throw Exception('应用失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('应用失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final shadowTotal = _shadowData['shadow_total'] ?? 0.0;
    final realTotal = _shadowData['real_total'] ?? 0.0;
    final shadowPnl = _shadowData['shadow_pnl'] ?? 0.0;
    final realPnl = _shadowData['real_pnl'] ?? 0.0;
    final diff = _shadowData['diff'] ?? 0.0;
    final suggestion = _shadowData['suggestion'] ?? '';

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: diff > 0 ? Colors.green.withOpacity(0.3) : (diff < 0 ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 20),
                SizedBox(width: 8),
                Text(
                  '影子账户对比',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 对比卡片
            Row(
              children: [
                Expanded(
                  child: _buildAccountCard(
                    title: '实盘账户',
                    total: realTotal,
                    pnl: realPnl,
                    isShadow: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccountCard(
                    title: '影子账户',
                    total: shadowTotal,
                    pnl: shadowPnl,
                    isShadow: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 对比结论
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: diff > 0 ? Colors.green.withOpacity(0.1) : (diff < 0 ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    diff > 0 ? Icons.trending_up : (diff < 0 ? Icons.trending_down : Icons.remove),
                    color: _getPnlColor(diff),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.isNotEmpty ? suggestion : '影子账户${_getComparisonText(diff)}实盘账户',
                      style: TextStyle(
                        color: _getPnlColor(diff),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 应用建议按钮
            if (diff != 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : _applySuggestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isApplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('应用建议 (${diff > 0 ? '跟随影子' : '优化实盘'})'),
                  ),
                ),
              ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required String title,
    required double total,
    required double pnl,
    required bool isShadow,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${_formatNumber(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pnl >= 0 ? '+' : ''}¥${_formatNumber(pnl.abs())}',
            style: TextStyle(
              color: _getPnlColor(pnl),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}