// lib/widgets/fund_card.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 资金卡片组件
/// 显示总资产、今日盈亏、仓位比例等信息
class FundCard extends StatefulWidget {
  final bool isReal; // true: 实盘, false: 模拟
  final VoidCallback? onRefresh;

  const FundCard({
    super.key,
    required this.isReal,
    this.onRefresh,
  });

  @override
  State<FundCard> createState() => _FundCardState();
}

class _FundCardState extends State<FundCard> {
  bool _isLoading = true;
  bool _isCollapsed = false;
  Map<String, dynamic> _fundData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFundData();
  }

  Future<void> _loadFundData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getFund();
      if (result != null) {
        setState(() {
          _fundData = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取资金信息失败';
        });
      }
    } catch (e) {
      debugPrint('加载资金信息失败: $e');
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

  String _getPnlPrefix(double pnl) {
    if (pnl > 0) return '+';
    if (pnl < 0) return '-';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final totalAssets = (widget.isReal
            ? _fundData['real_total']
            : _fundData['sim_total']) ??
        0.0;
    final todayPnl = (widget.isReal
            ? _fundData['real_today_pnl']
            : _fundData['sim_today_pnl']) ??
        0.0;
    final positionRatio = (widget.isReal
            ? _fundData['real_position_ratio']
            : _fundData['sim_position_ratio']) ??
        0.0;

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

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isReal ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isReal ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isReal ? '实盘账户' : '模拟账户',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  child: Icon(
                    _isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          if (!_isCollapsed) ...[
            const Divider(color: Colors.grey, height: 1),

            // 资金信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '总资产',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '¥${_formatNumber(totalAssets)}',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '今日盈亏',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${_getPnlPrefix(todayPnl)}¥${_formatNumber(todayPnl.abs())}',
                        style: TextStyle(
                          color: _getPnlColor(todayPnl),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '仓位比例',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Text(
                            '${(positionRatio * 100).toInt()}%',
                            style: TextStyle(
                              color: positionRatio > 0.8 ? Colors.orange : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: positionRatio,
                              backgroundColor: Colors.grey[800],
                              color: positionRatio > 0.8 ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadFundData,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('刷新'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (widget.isReal) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showSwitchConfirmDialog();
                        },
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('切换模拟'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
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
              ),
          ],
        ],
      ),
    );
  }

  void _showSwitchConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认切换', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要从实盘切换到模拟账户吗？\n切换后实盘交易将暂停。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text('切换'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _switchToSim();
    }
  }

  Future<void> _switchToSim() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.setMode('sim');
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已切换到模拟账户'), backgroundColor: Colors.green),
          );
          widget.onRefresh?.call();
          _loadFundData();
        }
      } else {
        throw Exception(result?['message'] ?? '切换失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e'), backgroundColor: Colors.red),
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
}