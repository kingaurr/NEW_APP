// lib/pages/position_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 持仓详情页面
/// 显示单只持仓的详细信息，支持修改止损止盈、卖出
class PositionDetailPage extends StatefulWidget {
  final Map<String, dynamic> position;

  const PositionDetailPage({super.key, required this.position});

  @override
  State<PositionDetailPage> createState() => _PositionDetailPageState();
}

class _PositionDetailPageState extends State<PositionDetailPage> {
  bool _isLoading = true;
  bool _isSelling = false;
  bool _isUpdatingStopLoss = false;
  Map<String, dynamic> _detail = {};
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _takeProfitController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getPositionDetail(widget.position['code']);
      if (result != null) {
        setState(() {
          _detail = result;
          _stopLossController.text = _detail['stop_loss']?.toStringAsFixed(2) ?? '';
          _takeProfitController.text = _detail['take_profit']?.toStringAsFixed(2) ?? '';
        });
      } else {
        setState(() {
          _errorMessage = '获取持仓详情失败';
        });
      }
    } catch (e) {
      debugPrint('加载持仓详情失败: $e');
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

  Future<void> _updateStopLoss() async {
    final stopLossText = _stopLossController.text.trim();
    if (stopLossText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入止损价'), backgroundColor: Colors.red),
      );
      return;
    }

    final stopLoss = double.tryParse(stopLossText);
    if (stopLoss == null || stopLoss <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的止损价'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUpdatingStopLoss = true;
    });

    try {
      final result = await ApiService.updateStopLoss(
        widget.position['code'],
        stopLoss,
      );

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('止损价已更新'), backgroundColor: Colors.green),
          );
          _loadDetail();
        }
      } else {
        throw Exception(result?['message'] ?? '更新失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStopLoss = false;
        });
      }
    }
  }

  Future<void> _updateTakeProfit() async {
    final takeProfitText = _takeProfitController.text.trim();
    if (takeProfitText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入止盈价'), backgroundColor: Colors.red),
      );
      return;
    }

    final takeProfit = double.tryParse(takeProfitText);
    if (takeProfit == null || takeProfit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的止盈价'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUpdatingStopLoss = true;
    });

    try {
      final result = await ApiService.updateTakeProfit(
        widget.position['code'],
        takeProfit,
      );

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('止盈价已更新'), backgroundColor: Colors.green),
          );
          _loadDetail();
        }
      } else {
        throw Exception(result?['message'] ?? '更新失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStopLoss = false;
        });
      }
    }
  }

  Future<void> _sellPosition() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认卖出', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要卖出 ${widget.position['name']} (${widget.position['code']}) 吗？\n'
          '数量: ${widget.position['shares']}股\n'
          '当前价: ¥${widget.position['current_price']}\n'
          '预估金额: ¥${_formatNumber(widget.position['market_value'])}',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('卖出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSelling = true;
    });

    try {
      final result = await ApiService.sellPosition(
        code: widget.position['code'],
        shares: widget.position['shares'],
      );

      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('卖出成功'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result?['message'] ?? '卖出失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('卖出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.position['code'] ?? '';
    final name = widget.position['name'] ?? '';
    final shares = widget.position['shares'] ?? 0;
    final avgPrice = widget.position['avg_price'] ?? 0.0;
    final currentPrice = widget.position['current_price'] ?? 0.0;
    final marketValue = widget.position['market_value'] ?? 0.0;
    final pnl = widget.position['pnl'] ?? 0.0;
    final pnlPercent = widget.position['pnl_percent'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('$name ($code)'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 价格卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '当前价格',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '成本均价',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${avgPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 持仓信息卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow('持仓数量', '${shares}股'),
                              const Divider(color: Colors.grey),
                              _buildInfoRow('持仓市值', '¥${_formatNumber(marketValue)}'),
                              const Divider(color: Colors.grey),
                              _buildInfoRow('浮动盈亏', '${pnl >= 0 ? '+' : ''}¥${_formatNumber(pnl.abs())}', pnl),
                              const Divider(color: Colors.grey),
                              _buildInfoRow('盈亏比例', '${pnlPercent >= 0 ? '+' : ''}${(pnlPercent * 100).toStringAsFixed(2)}%', pnl),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 止损止盈设置
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '止损止盈设置',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _stopLossController,
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '止损价',
                                        labelStyle: TextStyle(color: Colors.grey),
                                        border: OutlineInputBorder(),
                                        suffixText: '元',
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFFD4AF37)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _isUpdatingStopLoss ? null : _updateStopLoss,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isUpdatingStopLoss
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('更新'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _takeProfitController,
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '止盈价',
                                        labelStyle: TextStyle(color: Colors.grey),
                                        border: OutlineInputBorder(),
                                        suffixText: '元',
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFFD4AF37)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _isUpdatingStopLoss ? null : _updateTakeProfit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isUpdatingStopLoss
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('更新'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 卖出按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSelling ? null : _sellPosition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('卖出'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, [double? pnl]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: pnl != null ? _getPnlColor(pnl) : Colors.white,
              fontSize: 14,
              fontWeight: pnl != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}