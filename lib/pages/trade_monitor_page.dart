// pages/trade_monitor_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class TradeMonitorPage extends StatefulWidget {
  const TradeMonitorPage({Key? key}) : super(key: key);

  @override
  _TradeMonitorPageState createState() => _TradeMonitorPageState();
}

class _TradeMonitorPageState extends State<TradeMonitorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>?>? _candidatesFuture;
  Future<Map<String, dynamic>?>? _positionsFuture;
  Future<List<dynamic>?>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _candidatesFuture = ApiService.getCandidates();
      _positionsFuture = ApiService.getPositions();
      _ordersFuture = ApiService.getRecentOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易监控'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '选股池'),
            Tab(text: '持仓'),
            Tab(text: '委托'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCandidatesTab(),
            _buildPositionsTab(),
            _buildOrdersTab(),
          ],
        ),
      ),
    );
  }

  // ---------- 选股池标签页 ----------
  Widget _buildCandidatesTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _candidatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('加载失败'));
        }
        final data = snapshot.data!;
        final tradePool = data['trade_pool'] as List<dynamic>? ?? [];
        final shadowPool = data['shadow_pool'] as List<dynamic>? ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 交易池
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('交易池', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...tradePool.map((item) => _buildCandidateItem(item)).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 影子池
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('影子池', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...shadowPool.map((code) => Text(code)).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCandidateItem(Map<String, dynamic> item) {
    return ListTile(
      title: Text(item['code'] ?? ''),
      subtitle: Text('得分: ${item['score'] ?? 0}'),
      trailing: Text(item['reason'] ?? ''),
    );
  }

  // ---------- 持仓标签页 ----------
  Widget _buildPositionsTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _positionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('加载失败'));
        }
        final positions = snapshot.data!;
        // positions 可能是一个 Map，键为股票代码，值为持仓详情
        if (positions.isEmpty) {
          return const Center(child: Text('暂无持仓'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: positions.length,
          itemBuilder: (ctx, idx) {
            final code = positions.keys.elementAt(idx);
            final detail = positions[code];
            return Card(
              child: ListTile(
                title: Text(code),
                subtitle: Text('数量: ${detail['shares'] ?? 0}  成本: ${detail['cost'] ?? 0}'),
                trailing: Text('浮动盈亏: ${detail['pnl']?.toStringAsFixed(2) ?? '0.00'}'),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- 委托标签页 ----------
  Widget _buildOrdersTab() {
    return FutureBuilder<List<dynamic>?>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('加载失败'));
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('暂无委托记录'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, index) {
            final order = orders[index];
            return Card(
              child: ListTile(
                title: Text('${order['code'] ?? ''}  ${order['action'] ?? ''}'),
                subtitle: Text('数量: ${order['shares'] ?? 0}  价格: ${order['price'] ?? 0}'),
                trailing: Text(order['status'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}