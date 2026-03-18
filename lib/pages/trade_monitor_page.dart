// pages/trade_monitor_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'candidates_detail_page.dart'; // 导入候选详情页

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

  Future<void> _liquidateAll() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('一键平仓', style: theme.textTheme.titleMedium),
        content: const Text('确定要清仓所有股票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.liquidateAll();
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('一键平仓指令已发送'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('平仓失败'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCandidatesTab(theme),
            _buildPositionsTab(theme),
            _buildOrdersTab(theme),
          ],
        ),
      ),
    );
  }

  // ---------- 选股池标签页 ----------
  Widget _buildCandidatesTab(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _candidatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('选股池加载错误: ${snapshot.error}');
          return _buildErrorWidget(theme, '选股池加载失败', _loadData);
        }
        if (snapshot.data == null) {
          return Center(
            child: Text(
              '暂无数据',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        final data = snapshot.data!;
        final tradePool = data['trade_pool'] as List<dynamic>? ?? [];
        final shadowPool = data['shadow_pool'] as List<dynamic>? ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '交易池',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (tradePool.isEmpty)
                      Text('暂无', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                    else
                      ...tradePool.map((item) => _buildCandidateItem(theme, item)).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '影子池',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (shadowPool.isEmpty)
                      Text('暂无', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                    else
                      ...shadowPool.map((code) => _buildShadowItem(theme, code)).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCandidateItem(ThemeData theme, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidatesDetailPage(stock: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item['code'] ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '得分: ${item['score'] ?? 0}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item['reason'] ?? '',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowItem(ThemeData theme, dynamic code) {
    String codeStr = code is String ? code : code.toString();
    // 构造一个简单的股票对象用于详情页
    Map<String, dynamic> stockItem = {
      'code': codeStr,
      'score': 0.5,
      'reason': '影子池股票',
    };
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidatesDetailPage(stock: stockItem),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          codeStr,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  // ---------- 持仓标签页 ----------
  Widget _buildPositionsTab(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _positionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('持仓加载错误: ${snapshot.error}');
          return _buildErrorWidget(theme, '持仓加载失败', _loadData);
        }
        if (snapshot.data == null) {
          return Center(
            child: Text(
              '暂无持仓',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        final positions = snapshot.data!;
        if (positions.isEmpty) {
          return Center(
            child: Text(
              '暂无持仓',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _liquidateAll,
                icon: const Icon(Icons.clean_hands),
                label: const Text('一键平仓'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: positions.length,
                itemBuilder: (ctx, idx) {
                  final code = positions.keys.elementAt(idx);
                  final detail = positions[code] as Map<String, dynamic>? ?? {};
                  final shares = detail['shares'] ?? 0;
                  final cost = detail['cost'] ?? 0.0;
                  final pnl = detail['pnl'] ?? 0.0;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (pnl >= 0 ? theme.colorScheme.primary : theme.colorScheme.error).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: pnl >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '数量: $shares 成本: ¥${cost.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- 委托标签页 ----------
  Widget _buildOrdersTab(ThemeData theme) {
    return FutureBuilder<List<dynamic>?>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('委托加载错误: ${snapshot.error}');
          return _buildErrorWidget(theme, '委托加载失败', _loadData);
        }
        if (snapshot.data == null) {
          return Center(
            child: Text(
              '暂无委托记录',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return Center(
            child: Text(
              '暂无委托记录',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, index) {
            final order = orders[index] as Map<String, dynamic>? ?? {};
            final code = order['code'] ?? '';
            final action = order['action'] ?? '';
            final shares = order['shares'] ?? 0;
            final price = order['price'] ?? 0.0;
            final status = order['status'] ?? '';
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$code $action',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(theme, status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: theme.textTheme.bodySmall?.copyWith(color: _statusColor(theme, status)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '数量: $shares 价格: ¥${price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- 错误提示组件 ----------
  Widget _buildErrorWidget(ThemeData theme, String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'filled':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'canceled':
        return theme.colorScheme.onSurfaceVariant;
      case 'rejected':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}