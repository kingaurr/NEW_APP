// lib/pages/real_trade_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/position_item.dart';
import '../widgets/trade_pool_item.dart';
import '../widgets/signal_item.dart';
import '../widgets/shadow_summary.dart';

class RealTradePage extends StatefulWidget {
  const RealTradePage({super.key});

  @override
  State<RealTradePage> createState() => _RealTradePageState();
}

class _RealTradePageState extends State<RealTradePage> {
  bool _isLoading = true;
  bool _isCollapsed = false;
  String _currentMode = 'sim';
  Map<String, dynamic> _summary = {};
  List<dynamic> _positions = [];
  List<dynamic> _tradePool = [];
  List<dynamic> _signals = [];
  Map<String, dynamic> _shadowCompare = {};
  String _errorMessage = '';

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
        setState(() {
          _currentMode = result['mode'];
        });
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
        content: Text(
          '确定要切换到${newMode == 'real' ? '实盘' : '模拟'}模式吗？',
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text('确认切换'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.setMode(newMode);
      if (result != null && result['success'] == true) {
        setState(() {
          _currentMode = newMode;
        });
        _showMessage('已切换到${newMode == 'real' ? '实盘' : '模拟'}模式');
        _loadData();
      } else {
        throw Exception('切换失败');
      }
    } catch (e) {
      _showMessage('切换失败: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getFund(),
        ApiService.getPositions(),
        ApiService.getTradePool(),
        ApiService.getSignalHistory(),
        ApiService.getShadowRealtimeCompare(),
      ]);

      // 1. 资金（调试弹窗）
      double fund = 0.0;
      if (results[0] != null && results[0] is Map<String, dynamic>) {
        final fundData = results[0] as Map<String, dynamic>;
        fund = (fundData['available_fund'] ?? fundData['current_fund'] ?? 0.0).toDouble();
        // 显示资金数值
        _showMessage('💰 资金: ¥$fund', isError: false);
      } else {
        _showMessage('❌ getFund 返回空', isError: true);
      }

      // 2. 持仓市值
      double positionValue = 0.0;
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        final positionsMap = results[1] as Map<String, dynamic>;
        for (var pos in positionsMap.values) {
          if (pos is Map && pos.containsKey('value')) {
            positionValue += (pos['value'] as num).toDouble();
          }
        }
      }

      // 3. 摘要
      setState(() {
        _summary = {
          'total_assets': fund + positionValue,
          'today_pnl': 0.0,
          'position_ratio': positionValue / (fund > 0 ? fund : 1.0),
          'risk_status': 'normal',
          'today_trades': 0,
        };
      });

      // 4. 持仓列表
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        final positionsMap = results[1] as Map<String, dynamic>;
        final positionsList = positionsMap.entries.map((entry) {
          final value = entry.value;
          if (value is Map) {
            return {
              'code': entry.key,
              ...value,
            };
          }
          return {'code': entry.key, 'value': value};
        }).toList();
        _positions = positionsList;
      }

      // 5. 交易池
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        final tradePoolMap = results[2] as Map<String, dynamic>;
        _tradePool = tradePoolMap['stocks'] ?? [];
      }

      // 6. 信号历史
      if (results[3] != null && results[3] is Map<String, dynamic>) {
        final signalsMap = results[3] as Map<String, dynamic>;
        _signals = signalsMap['signals'] ?? [];
      }

      // 7. 影子对比
      if (results[4] != null && results[4] is Map<String, dynamic>) {
        _shadowCompare = results[4] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('加载实盘数据失败: $e');
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

  Color _getRiskColor(String status) {
    switch (status) {
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'fuse':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getRiskText(String status) {
    switch (status) {
      case 'normal':
        return '正常';
      case 'warning':
        return '警告';
      case 'fuse':
        return '熔断';
      default:
        return '正常';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
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
                          onPressed: _loadData,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: _switchMode,
                                      child: Text(
                                        _currentMode == 'real' ? '切换模拟' : '切换实盘',
                                        style: const TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(
                                      '¥${_formatNumber(_summary['total_assets'] ?? 0)}',
                                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('今日盈亏', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(
                                      '${(_summary['today_pnl'] ?? 0) >= 0 ? '+' : ''}¥${_formatNumber((_summary['today_pnl'] ?? 0).abs())}',
                                      style: TextStyle(
                                        color: (_summary['today_pnl'] ?? 0) >= 0 ? Colors.green : Colors.red,
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
                                    const Text('仓位比例', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Row(
                                      children: [
                                        Text(
                                          '${((_summary['position_ratio'] ?? 0) * 100).toInt()}%',
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: LinearProgressIndicator(
                                            value: _summary['position_ratio'] ?? 0,
                                            backgroundColor: Colors.grey[800],
                                            color: (_summary['position_ratio'] ?? 0) > 0.8 ? Colors.orange : Colors.green,
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
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(_summary['risk_status'] ?? 'normal').withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRiskText(_summary['risk_status'] ?? 'normal'),
                                        style: TextStyle(color: _getRiskColor(_summary['risk_status'] ?? 'normal'), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('今日交易次数', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text('${_summary['today_trades'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 当前持仓
                        if (_positions.isNotEmpty) ...[
                          const Text('当前持仓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ..._positions.map((position) => PositionItem(
                                position: position,
                                onPositionChanged: _loadData,
                              )),
                        ],

                        const SizedBox(height: 16),

                        // AI交易池
                        if (_tradePool.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('AI交易池', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/trade_pool'),
                                child: const Text('查看更多', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._tradePool.take(5).map((stock) => TradePoolItem(stock: stock, onTrade: _loadData)),
                        ],

                        const SizedBox(height: 16),

                        // 最近信号记录
                        if (_signals.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('最近信号', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/signal_history'),
                                child: const Text('查看更多', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._signals.take(5).map((signal) => SignalItem(signal: signal, onExecuted: _loadData)),
                        ],

                        const SizedBox(height: 16),

                        // 虚拟对比栏
                        GestureDetector(
                          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                          child: Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.compare_arrows, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('影子账户对比', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
                                  Icon(_isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!_isCollapsed) ShadowSummary(onApplySuggestion: _loadData),
                      ],
                    ),
                  ),
      ),
    );
  }
}