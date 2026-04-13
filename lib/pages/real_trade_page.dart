// lib/pages/real_trade_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/position_item.dart';
// import '../widgets/trade_pool_item.dart'; // 暂时注释
import '../widgets/signal_item.dart';
import '../widgets/shadow_summary.dart';
// ========== 新增导入：指纹验证 ==========
import '../utils/biometrics_helper.dart';
// ====================================

class RealTradePage extends StatefulWidget {
  const RealTradePage({super.key});

  @override
  RealTradePageState createState() => RealTradePageState();
}

class RealTradePageState extends State<RealTradePage> {
  bool _isLoading = true;
  bool _isCollapsed = false;
  String _currentMode = 'sim';
  double _fund = 0.0;
  double _positionValue = 0.0;
  List<dynamic> _positions = [];
  // List<dynamic> _tradePool = []; // 暂时注释
  List<dynamic> _signals = [];
  Map<String, dynamic> _shadowCompare = {};
  String _errorMessage = '';

  // ========== 新增：交易池摘要数据 ==========
  Map<String, dynamic> _tradePoolSummary = {
    'count': 0,
    'avgScore': 0.0,
  };
  // =======================================

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMode();
  }

  void refresh() {
    _loadData();
  }

  Future<void> _loadMode() async {
    try {
      final result = await ApiService.getMode();
      if (result != null) {
        final mode = result['mode'];
        if (mode != null && mounted) {
          setState(() {
            _currentMode = mode.toString();
          });
        }
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

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await ApiService.setMode(newMode);
      if (!mounted) return;
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

  // ========== 新增：一键平仓方法 ==========
  Future<void> _clearAllPositions() async {
    // 先确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认一键平仓', style: TextStyle(color: Colors.white)),
        content: const Text(
          '此操作将卖出所有持仓股票，是否继续？',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认平仓'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'clear_all_positions',
      operationDesc: '一键平仓',
    );
    if (!authenticated) {
      _showMessage('指纹验证失败，无法平仓', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.clearAllPositions();
      if (!mounted) return;
      if (result == true) {
        _showMessage('一键平仓成功');
        await _loadData();
      } else {
        throw Exception('平仓请求失败');
      }
    } catch (e) {
      _showMessage('平仓失败: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ====================================

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getFund(),
        ApiService.getPositions(),
        ApiService.getSignalHistory(),
        ApiService.getShadowRealtimeCompare(),
        // ========== 新增：获取交易池数据 ==========
        ApiService.getTradingSignals(),
      ]);

      if (!mounted) return;

      // 安全类型转换：使用 is 判断，处理可空类型
      double fund = 0.0;
      final fundResult = results[0];
      if (fundResult is Map) {
        // 先转为 Map<dynamic, dynamic>，再安全取值
        final map = Map<String, dynamic>.from(fundResult);
        fund = (map['available_fund'] ?? map['current_fund'] ?? 0.0).toDouble();
      }

      double positionValue = 0.0;
      List<dynamic> positionsList = [];
      final positionsResult = results[1];
      if (positionsResult is Map) {
        final map = Map<String, dynamic>.from(positionsResult);
        for (var entry in map.entries) {
          final code = entry.key;
          final pos = entry.value;
          if (pos is Map) {
            final value = (pos['value'] ?? 0.0).toDouble();
            positionValue += value;
            positionsList.add({'code': code, ...pos});
          }
        }
      }

      List<dynamic> signalsList = [];
      final signalsResult = results[2];
      if (signalsResult is Map) {
        final map = Map<String, dynamic>.from(signalsResult);
        final sigs = map['signals'];
        if (sigs is List) {
          signalsList = sigs;
        }
      }

      Map<String, dynamic> shadowCompareMap = {};
      final shadowResult = results[3];
      if (shadowResult is Map) {
        shadowCompareMap = Map<String, dynamic>.from(shadowResult);
      }

      // ========== 新增：处理交易池摘要 ==========
      Map<String, dynamic> tradePoolSummary = {'count': 0, 'avgScore': 0.0};
      final tradingSignalsResult = results[4];
      if (tradingSignalsResult is Map) {
        final map = Map<String, dynamic>.from(tradingSignalsResult);
        final tradePool = map['trade_pool'];
        if (tradePool is List) {
          double totalScore = 0.0;
          for (var stock in tradePool) {
            if (stock is Map) {
              totalScore += (stock['total_score'] ?? stock['score'] ?? 0).toDouble();
            }
          }
          tradePoolSummary = {
            'count': tradePool.length,
            'avgScore': tradePool.isEmpty ? 0.0 : totalScore / tradePool.length,
          };
        }
      }

      if (!mounted) return;
      setState(() {
        _fund = fund;
        _positionValue = positionValue;
        _positions = positionsList;
        _signals = signalsList;
        _shadowCompare = shadowCompareMap;
        _tradePoolSummary = tradePoolSummary;
      });
    } catch (e, stack) {
      debugPrint('加载实盘数据失败: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败: $e';
      });
      // 仅当错误信息非空时弹窗，避免空错误弹窗
      if (_errorMessage.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('加载失败'),
            content: Text('错误: $e\n\n请将截图发给开发者'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
            ],
          ),
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
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage),
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
                        // 资金卡片（排版优化：紧凑双列布局）
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // 账户标识行
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
                                // 双列布局：左列（总资产/今日盈亏），右列（仓位/风控/交易次数）
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 左列
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('总资产', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text('¥${_formatNumber(_fund + _positionValue)}',
                                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          const Text('今日盈亏', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          const Text('¥0.00', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    // 右列
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('仓位比例', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text('${(_positionValue / (_fund > 0 ? _fund : 1) * 100).toInt()}%',
                                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: LinearProgressIndicator(
                                                  value: _positionValue / (_fund > 0 ? _fund : 1),
                                                  backgroundColor: Colors.grey[800],
                                                  color: (_positionValue / (_fund > 0 ? _fund : 1)) > 0.8 ? Colors.orange : Colors.green,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Text('风控状态', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                            child: const Text('正常', style: TextStyle(color: Colors.green, fontSize: 12)),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text('今日交易次数', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          const Text('0', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ========== 新增：交易池摘要卡片 ==========
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/trading_signals'),
                          child: Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('今日交易池', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_tradePoolSummary['count']} 只股票 · 平均得分 ${_tradePoolSummary['avgScore'].toStringAsFixed(1)}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // =====================================

                        // ========== 新增：一键平仓按钮（仅当有持仓时显示） ==========
                        if (_positions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _clearAllPositions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('一键平仓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        // =====================================================

                        // 当前持仓
                        if (_positions.isNotEmpty) ...[
                          const Text('当前持仓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ..._positions.map((position) => PositionItem(
                                position: position,
                                onPositionChanged: _loadData,
                              )),
                        ] else ...[
                          // 新增：无持仓占位提示
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: const Text('暂无持仓', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // 最近信号记录（只展示最近3条，符合计划书）
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
                          const SizedBox(height: 8),
                          ..._signals.take(3).map((signal) => SignalItem(signal: signal, onExecuted: _loadData)),
                        ],

                        const SizedBox(height: 8),

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