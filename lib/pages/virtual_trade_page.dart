// lib/pages/virtual_trade_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/fund_card.dart';
import '../widgets/shadow_summary.dart';
import '../widgets/war_game_report.dart';
import '../widgets/pending_rule_item.dart';

/// 虚拟交易页面
/// 策略验证中心：影子账户、红蓝军、压力测试、待验证规则
class VirtualTradePage extends StatefulWidget {
  const VirtualTradePage({super.key});

  @override
  State<VirtualTradePage> createState() => _VirtualTradePageState();
}

class _VirtualTradePageState extends State<VirtualTradePage> {
  bool _isLoading = true;
  bool _isWarGameExpanded = false;
  bool _isStressTestExpanded = false;
  bool _isPendingRulesExpanded = false;
  Map<String, dynamic> _shadowStatus = {};
  Map<String, dynamic> _lightWarGame = {};
  Map<String, dynamic> _deepWarGame = {};
  Map<String, dynamic> _stressTest = {};
  List<dynamic> _pendingRules = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getShadowStatus(),
        ApiService.getLatestLightWarGame(),
        ApiService.getLatestDeepWarGame(),
        ApiService.getStressTestLatest(), // 使用 getStressTestLatest
        ApiService.getPendingRules(),
      ]);

      // 1. 影子账户状态
      if (results[0] != null && results[0] is Map<String, dynamic>) {
        setState(() {
          _shadowStatus = results[0] as Map<String, dynamic>;
        });
      }

      // 2. 轻量红蓝军
      if (results[1] != null && results[1] is Map<String, dynamic>) {
        setState(() {
          _lightWarGame = results[1] as Map<String, dynamic>;
        });
      }

      // 3. 深度红蓝军
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        setState(() {
          _deepWarGame = results[2] as Map<String, dynamic>;
        });
      }

      // 4. 压力测试报告
      if (results[3] != null && results[3] is Map<String, dynamic>) {
        setState(() {
          _stressTest = results[3] as Map<String, dynamic>;
        });
      }

      // 5. 待验证规则
      if (results[4] != null && results[4] is Map<String, dynamic>) {
        final pendingMap = results[4] as Map<String, dynamic>;
        setState(() {
          _pendingRules = pendingMap['rules'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('加载虚拟交易数据失败: $e');
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

  String _getConclusionText(String winner) {
    if (winner == 'blue') return '蓝军胜出';
    if (winner == 'red') return '红军胜出';
    return '平局';
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
                        // 影子账户摘要
                        const Text(
                          '影子账户',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ShadowSummary(
                          onApplySuggestion: _loadData,
                        ),

                        const SizedBox(height: 16),

                        // 红蓝军轻量对抗（白天每小时结果）
                        if (_lightWarGame.isNotEmpty)
                          Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.sports_mma,
                                        color: Color(0xFFD4AF37),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '轻量对抗',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _lightWarGame['timestamp']?.substring(5, 16) ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildWarGameCard('蓝军', _lightWarGame['blue_return'] ?? 0, Colors.blue),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildWarGameCard('红军', _lightWarGame['red_return'] ?? 0, Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '结论：${_getConclusionText(_lightWarGame['winner'] ?? '')}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/war_game_history');
                                    },
                                    child: const Text(
                                      '查看历史',
                                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 红蓝军深度报告（昨夜）
                        if (_deepWarGame.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isWarGameExpanded = !_isWarGameExpanded;
                              });
                            },
                            child: Card(
                              color: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.insights,
                                          color: Color(0xFFD4AF37),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            '深度对抗报告',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          _isWarGameExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    if (_isWarGameExpanded) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        '场景: ${_deepWarGame['scenario'] ?? '2015年股灾'}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildWarGameCard('蓝军', _deepWarGame['blue_return'] ?? 0, Colors.blue),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildWarGameCard('红军', _deepWarGame['red_return'] ?? 0, Colors.red),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '结论: ${_deepWarGame['conclusion'] ?? '建议收紧止损'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _applySuggestion(_deepWarGame);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFD4AF37),
                                            foregroundColor: Colors.black,
                                          ),
                                          child: const Text('应用建议'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 压力测试报告
                        if (_stressTest.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isStressTestExpanded = !_isStressTestExpanded;
                              });
                            },
                            child: Card(
                              color: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.speed,
                                          color: Color(0xFFD4AF37),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            '压力测试报告',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          _isStressTestExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    if (_isStressTestExpanded) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            '通过率',
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                          Text(
                                            '${(_stressTest['pass_rate'] ?? 0) * 100}%',
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            '极端行情亏损',
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                          Text(
                                            '${(_stressTest['extreme_loss'] ?? 0) * 100}%',
                                            style: TextStyle(
                                              color: (_stressTest['extreme_loss'] ?? 0) < -0.2 ? Colors.red : Colors.orange,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '结论: ${_stressTest['conclusion'] ?? '系统可承受'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 待验证规则
                        if (_pendingRules.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPendingRulesExpanded = !_isPendingRulesExpanded;
                              });
                            },
                            child: Card(
                              color: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.rule,
                                          color: Color(0xFFD4AF37),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            '待验证规则',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${_pendingRules.length}',
                                            style: const TextStyle(color: Colors.orange, fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _isPendingRulesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    if (_isPendingRulesExpanded) ...[
                                      const SizedBox(height: 12),
                                      ..._pendingRules.take(5).map((rule) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: PendingRuleItem(
                                              rule: rule,
                                              onStatusChanged: _loadData,
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWarGameCard(String name, double ret, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '${ret >= 0 ? '+' : ''}${(ret * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: ret >= 0 ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applySuggestion(Map<String, dynamic> deepReport) async {
    if (deepReport.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认应用建议', style: TextStyle(color: Colors.white)),
        content: Text(deepReport['suggestion'] ?? '应用深度对抗报告的建议', style: const TextStyle(color: Colors.white70)),
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

    try {
      // 使用已有的 applyWarGameSuggestion 接口，传递报告ID（如果存在）
      final reportId = deepReport['id'] ?? '';
      final result = await ApiService.applyWarGameSuggestion(reportId);
      if (result?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('建议已应用'), backgroundColor: Colors.green),
          );
          _loadData();
        }
      } else {
        throw Exception(result?['message'] ?? '应用失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('应用失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}