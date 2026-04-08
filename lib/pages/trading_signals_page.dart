// lib/pages/trading_signals_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

class TradingSignalsPage extends StatefulWidget {
  const TradingSignalsPage({super.key});

  @override
  State<TradingSignalsPage> createState() => _TradingSignalsPageState();
}

class _TradingSignalsPageState extends State<TradingSignalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _tradePool = [];
  List<dynamic> _shadowPool = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _error = '';

  String _sortBy = 'score';
  String _filterIndustry = '';
  List<String> _industries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.getTradingSignals();
      if (mounted) {
        setState(() {
          _tradePool = data?['trade_pool'] ?? [];
          _shadowPool = data?['shadow_pool'] ?? [];
          _extractIndustries();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    try {
      final data = await ApiService.getTradingSignals();
      if (mounted) {
        setState(() {
          _tradePool = data?['trade_pool'] ?? [];
          _shadowPool = data?['shadow_pool'] ?? [];
          _extractIndustries();
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  void _extractIndustries() {
    final industries = <String>{};
    for (final stock in _tradePool) {
      final industry = stock['industry'] ?? stock['sector'] ?? '';
      if (industry.isNotEmpty) {
        industries.add(industry);
      }
    }
    for (final stock in _shadowPool) {
      final industry = stock['industry'] ?? stock['sector'] ?? '';
      if (industry.isNotEmpty) {
        industries.add(industry);
      }
    }
    _industries = industries.toList()..sort();
  }

  List<dynamic> _getCurrentPool() {
    final pool = _tabController.index == 0 ? _tradePool : _shadowPool;
    List<dynamic> filtered = List.from(pool);

    if (_filterIndustry.isNotEmpty) {
      filtered = filtered.where((stock) {
        final industry = stock['industry'] ?? stock['sector'] ?? '';
        return industry == _filterIndustry;
      }).toList();
    }

    if (_sortBy == 'score') {
      filtered.sort((a, b) {
        final scoreA = (a['total_score'] ?? a['score'] ?? 0).toDouble();
        final scoreB = (b['total_score'] ?? b['score'] ?? 0).toDouble();
        return scoreB.compareTo(scoreA);
      });
    } else if (_sortBy == 'industry') {
      filtered.sort((a, b) {
        final industryA = a['industry'] ?? a['sector'] ?? '';
        final industryB = b['industry'] ?? b['sector'] ?? '';
        return industryA.compareTo(industryB);
      });
    }

    return filtered;
  }

  Future<void> _removeStock(Map<String, dynamic> stock) async {
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'remove_stock',
      operationDesc: '剔除股票',
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证失败，无法剔除股票'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final stockCode = stock['code'] ?? stock['symbol'] ?? '';
    final stockName = stock['name'] ?? stockCode;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final result = await ApiService.removeFromTradingSignals(stockCode);
      if (mounted) {
        if (result['success'] == true) {
          await _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已剔除 $stockName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '剔除失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('剔除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _promoteToTradePool(Map<String, dynamic> stock) async {
    final authenticated = await BiometricsHelper.authenticateForOperation(
      operation: 'promote_stock',
      operationDesc: '提升到交易池',
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证失败，无法提升'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final stockCode = stock['code'] ?? stock['symbol'] ?? '';
    final stockName = stock['name'] ?? stockCode;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final result = await ApiService.promoteToTradingSignals(stockCode);
      if (mounted) {
        if (result['success'] == true) {
          await _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已提升 $stockName 到交易池'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '提升失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提升失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showStockDetail(Map<String, dynamic> stock) {
    Navigator.pushNamed(
      context,
      '/stock_detail',
      arguments: {
        'code': stock['code'] ?? stock['symbol'] ?? '',
        'name': stock['name'] ?? '',
      },
    );
  }

  Widget _buildScoreRow(Map<String, dynamic> stock) {
    final scores = [
      {'label': '技术', 'value': stock['tech_score'] ?? 0},
      {'label': '资金', 'value': stock['fund_score'] ?? 0},
      {'label': '基本', 'value': stock['fundamental_score'] ?? 0},
      {'label': '情绪', 'value': stock['sentiment_score'] ?? 0},
      {'label': '行业', 'value': stock['sector_score'] ?? 0},
      {'label': '动量', 'value': stock['momentum_score'] ?? 0},
    ];

    return Row(
      children: scores.map((s) {
        final value = (s['value'] as num).toDouble();
        return Expanded(
          child: Tooltip(
            message: '${s['label']}: ${value.toStringAsFixed(1)}',
            child: Column(
              children: [
                Text(
                  s['label']!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockItem(Map<String, dynamic> stock, bool isTradePool) {
    final totalScore = (stock['total_score'] ?? stock['score'] ?? 0).toDouble();
    final isHeld = stock['is_held'] ?? false;
    final isGray = stock['is_gray'] ?? false;
    final reason = stock['reason'] ?? stock['selected_reason'] ?? '';
    final ruleId = stock['rule_id'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: () => _showStockDetail(stock),
        onLongPress: () => _showStockOptions(stock, isTradePool),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stock['name'] ?? stock['code'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stock['code'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${totalScore.toStringAsFixed(1)}分',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isHeld)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已持仓',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  if (isGray) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '灰度中',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _buildScoreRow(stock),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ruleId.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showRuleDetail(ruleId),
                        child: const Icon(Icons.menu_book, size: 14, color: Color(0xFFD4AF37)),
                      ),
                  ],
                ),
              ],
              if (!isTradePool) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _promoteToTradePool(stock),
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('提升到交易池'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStockOptions(Map<String, dynamic> stock, bool isTradePool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('剔除股票'),
              onTap: () {
                Navigator.pop(context);
                _removeStock(stock);
              },
            ),
            if (!isTradePool)
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Color(0xFFD4AF37)),
                title: const Text('提升到交易池'),
                onTap: () {
                  Navigator.pop(context);
                  _promoteToTradePool(stock);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRuleDetail(String ruleId) {
    // 跳转到规则详情页
    Navigator.pushNamed(
      context,
      '/rule_detail',
      arguments: {'rule_id': ruleId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易信号池'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '交易信号池'),
            Tab(text: '影子候选池'),
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: _sortBy,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: const Color(0xFF2A2A2A),
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'score', child: Text('按得分排序')),
                                  DropdownMenuItem(value: 'industry', child: Text('按行业排序')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _sortBy = value);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: _filterIndustry.isEmpty ? null : _filterIndustry,
                                isExpanded: true,
                                hint: const Text('全部行业', style: TextStyle(color: Colors.grey)),
                                underline: const SizedBox(),
                                dropdownColor: const Color(0xFF2A2A2A),
                                style: const TextStyle(color: Colors.white),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('全部行业')),
                                  ..._industries.map((industry) {
                                    return DropdownMenuItem(value: industry, child: Text(industry));
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _filterIndustry = value ?? '';
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _getCurrentPool().length,
                          itemBuilder: (context, index) {
                            final stock = _getCurrentPool()[index];
                            final isTradePool = _tabController.index == 0;
                            return _buildStockItem(stock, isTradePool);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}