// lib/widgets/fund_card.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 资金卡片组件
class FundCard extends StatefulWidget {
  final bool isReal;
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

  @override
  Widget build(BuildContext context) {
    final totalAssets = _fundData['current_fund'] ?? 0.0;

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
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('¥${_formatNumber(totalAssets)}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('今日盈亏', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Text('¥0.00', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('仓位比例', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Text('0%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadFundData,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('刷新'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey)),
                    ),
                  ),
                  if (widget.isReal) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSwitchConfirmDialog,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('切换模拟'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12))),
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
        content: const Text('确定要从实盘切换到模拟账户吗？\n切换后实盘交易将暂停。', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('切换')),
        ],
      ),
    );
    if (confirmed == true) await _switchToSim();
  }

  Future<void> _switchToSim() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.setMode('sim');
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已切换到模拟账户'), backgroundColor: Colors.green));
          widget.onRefresh?.call();
          _loadFundData();
        }
      } else {
        throw Exception(result?['message'] ?? '切换失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('切换失败: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}