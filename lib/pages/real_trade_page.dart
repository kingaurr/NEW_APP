// lib/pages/real_trade_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/position_item.dart';

class RealTradePage extends StatefulWidget {
  const RealTradePage({super.key});

  @override
  RealTradePageState createState() => RealTradePageState();
}

class RealTradePageState extends State<RealTradePage> {
  bool _isLoading = true;
  String _currentMode = 'sim';
  double _fund = 0.0;
  double _positionValue = 0.0;
  List<dynamic> _positions = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final result = await ApiService.getMode();
      if (result != null && result['mode'] != null) {
        setState(() => _currentMode = result['mode']);
      }
    } catch (e) {
      debugPrint('加载模式失败: $e');
    }
  }

  Future<void> _switchMode() async {
    final newMode = _currentMode == 'real' ? 'sim' : 'real';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('切换模式', style: TextStyle(color: Colors.white)),
        content: Text('确定要切换到${newMode == 'real' ? '实盘' : '模拟'}模式吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认切换')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.setMode(newMode);
      if (result != null && result['success'] == true) {
        setState(() => _currentMode = newMode);
        _showMessage('已切换到${newMode == 'real' ? '实盘' : '模拟'}模式');
        _loadData();
      } else throw Exception('切换失败');
    } catch (e) {
      _showMessage('切换失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        ApiService.getFund(),
        ApiService.getPositions(),
      ]);
      double fund = 0.0;
      if (results[0] != null && results[0] is Map<String, dynamic>) {
        final fd = results[0] as Map<String, dynamic>;
        fund = (fd['available_fund'] ?? fd['current_fund'] ?? 0.0).toDouble();
      }
      double positionValue = 0.0;
      List<dynamic> positionsList = [];
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        final pm = results[1] as Map<String, dynamic>;
        for (var entry in pm.entries) {
          final code = entry.key;
          final pos = entry.value;
          if (pos is Map) {
            final value = pos['value']?.toDouble() ?? 0.0;
            positionValue += value;
            positionsList.add({
              'code': code,
              ...pos,
            });
          }
        }
      }
      setState(() {
        _fund = fund;
        _positionValue = positionValue;
        _positions = positionsList;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(double v) {
    if (v >= 1e8) return '${(v/1e8).toStringAsFixed(2)}亿';
    if (v >= 1e4) return '${(v/1e4).toStringAsFixed(2)}万';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 资金卡片
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _currentMode == 'real' ? Colors.red : Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _currentMode == 'real' ? '实盘账户' : '模拟账户',
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: _switchMode,
                                      child: Text(
                                        _currentMode == 'real' ? '切换模拟' : '切换实盘',
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text('¥${_formatNumber(_fund + _positionValue)}',
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
                                    Row(
                                      children: [
                                        Text('${(_positionValue / (_fund > 0 ? _fund : 1) * 100).toInt()}%',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: LinearProgressIndicator(
                                            value: _positionValue / (_fund > 0 ? _fund : 1),
                                            backgroundColor: Colors.grey[800],
                                            color: (_positionValue / (_fund > 0 ? _fund : 1)) > 0.8 ? Colors.orange : Colors.green,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('风控状态', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                      child: const Text('正常', style: TextStyle(color: Colors.green, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('今日交易次数', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const Text('0', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 持仓列表
                        if (_positions.isNotEmpty) ...[
                          const Text('当前持仓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ..._positions.map((position) => PositionItem(
                                position: position,
                                onPositionChanged: _loadData,
                              )),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}