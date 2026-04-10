// lib/pages/trade_monitor_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 交易监控页面
/// 聚合展示持仓、委托、成交、资金流水
class TradeMonitorPage extends StatefulWidget {
  const TradeMonitorPage({super.key});

  @override
  State<TradeMonitorPage> createState() => _TradeMonitorPageState();
}

class _TradeMonitorPageState extends State<TradeMonitorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _initialTab = 0;

  // 持仓数据
  List<dynamic> _positions = [];
  bool _loadingPositions = true;

  // 委托/订单数据
  List<dynamic> _orders = [];
  bool _loadingOrders = true;

  // 成交数据
  List<dynamic> _trades = [];
  bool _loadingTrades = true;

  // 资金流水
  List<dynamic> _fundFlows = [];
  bool _loadingFundFlows = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从路由参数获取初始 Tab
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final tab = args['initialTab'];
      if (tab != null && tab is int && tab >= 0 && tab < 4) {
        _initialTab = tab;
        _tabController.index = tab;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadPositions(),
      _loadOrders(),
      _loadTrades(),
      _loadFundFlows(),
    ]);
  }

  Future<void> _loadPositions() async {
    setState(() => _loadingPositions = true);
    try {
      final data = await ApiService.getPositions();
      if (mounted) {
        final list = <dynamic>[];
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map) {
              list.add({'code': key, ...value});
            }
          });
        }
        setState(() {
          _positions = list;
          _loadingPositions = false;
        });
      }
    } catch (e) {
      debugPrint('加载持仓失败: $e');
      setState(() => _loadingPositions = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final data = await ApiService.getRecentOrders();
      if (mounted) {
        setState(() {
          _orders = data ?? [];
          _loadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint('加载委托失败: $e');
      setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadTrades() async {
    setState(() => _loadingTrades = true);
    try {
      // 成交记录复用订单接口，筛选已成交
      final data = await ApiService.getRecentOrders();
      if (mounted) {
        final trades = (data ?? []).where((o) => o['status'] == 'filled').toList();
        setState(() {
          _trades = trades;
          _loadingTrades = false;
        });
      }
    } catch (e) {
      debugPrint('加载成交失败: $e');
      setState(() => _loadingTrades = false);
    }
  }

  Future<void> _loadFundFlows() async {
    setState(() => _loadingFundFlows = true);
    try {
      // 资金流水可从资金历史接口获取
      final data = await ApiService.getFund();
      if (mounted) {
        final history = data?['history'] as List<dynamic>? ?? [];
        setState(() {
          _fundFlows = history;
          _loadingFundFlows = false;
        });
      }
    } catch (e) {
      debugPrint('加载资金流水失败: $e');
      setState(() => _loadingFundFlows = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易监控'),
        backgroundColor: const Color(0xFF1E1E1E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '持仓'),
            Tab(text: '委托'),
            Tab(text: '成交'),
            Tab(text: '资金流水'),
          ],
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD4AF37),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPositionsTab(),
          _buildOrdersTab(),
          _buildTradesTab(),
          _buildFundFlowsTab(),
        ],
      ),
    );
  }

  Widget _buildPositionsTab() {
    if (_loadingPositions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_positions.isEmpty) {
      return const Center(child: Text('暂无持仓', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadPositions,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _positions.length,
        itemBuilder: (context, index) {
          final pos = _positions[index];
          return _buildPositionCard(pos);
        },
      ),
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> pos) {
    final code = pos['code'] ?? '';
    final name = pos['name'] ?? code;
    final shares = pos['shares'] ?? 0;
    final price = pos['avg_price'] ?? pos['price'] ?? 0.0;
    final value = pos['value'] ?? (shares * price);
    final pnl = pos['pnl'] ?? 0.0;
    final pnlPct = pos['pnl_pct'] ?? 0.0;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  code,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$shares 股', style: const TextStyle(color: Colors.white70)),
                Text('成本 ¥${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                Text('市值 ¥${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${pnl >= 0 ? '+' : ''}¥${pnl.toStringAsFixed(2)} (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: pnl >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('暂无委托', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final code = order['code'] ?? '';
    final action = order['action'] ?? '';
    final price = order['price'] ?? 0.0;
    final shares = order['shares'] ?? 0;
    final status = order['status'] ?? 'pending';
    final timestamp = order['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch((order['created_at'] * 1000).toInt())
        : null;

    final isBuy = action == 'buy';
    final statusColor = status == 'filled' ? Colors.green : (status == 'cancelled' ? Colors.red : Colors.orange);
    final statusText = status == 'filled' ? '已成' : (status == 'cancelled' ? '已撤' : '待报');

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isBuy ? Colors.green : Colors.red).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isBuy ? '买' : '卖',
                  style: TextStyle(
                    color: isBuy ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(code, style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$shares 股 × ¥${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${(shares * price).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (timestamp != null)
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradesTab() {
    if (_loadingTrades) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_trades.isEmpty) {
      return const Center(child: Text('今日无成交', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadTrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _trades.length,
        itemBuilder: (context, index) {
          final trade = _trades[index];
          return _buildOrderCard(trade); // 复用委托卡片样式
        },
      ),
    );
  }

  Widget _buildFundFlowsTab() {
    if (_loadingFundFlows) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fundFlows.isEmpty) {
      return const Center(child: Text('暂无资金流水', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadFundFlows,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _fundFlows.length,
        itemBuilder: (context, index) {
          final flow = _fundFlows[index];
          return _buildFundFlowCard(flow);
        },
      ),
    );
  }

  Widget _buildFundFlowCard(Map<String, dynamic> flow) {
    final date = flow['date'] ?? '';
    final fund = flow['fund'] ?? 0.0;
    final dailyPnl = flow['daily_pnl'] ?? 0.0;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFD4AF37)),
        title: Text(date, style: const TextStyle(color: Colors.white)),
        subtitle: Text('资产 ¥${fund.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          '${dailyPnl >= 0 ? '+' : ''}¥${dailyPnl.toStringAsFixed(2)}',
          style: TextStyle(
            color: dailyPnl >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}