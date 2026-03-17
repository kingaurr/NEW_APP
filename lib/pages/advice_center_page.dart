// pages/advice_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'advice_detail_page.dart'; // 需要提前创建，如果还没有可先注释

/// 优化建议中心页面
class AdviceCenterPage extends StatefulWidget {
  const AdviceCenterPage({Key? key}) : super(key: key);

  @override
  _AdviceCenterPageState createState() => _AdviceCenterPageState();
}

class _AdviceCenterPageState extends State<AdviceCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _pendingFuture;
  late Future<List<dynamic>> _historyFuture;
  bool _isLoading = false;

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

  void _loadData() {
    setState(() {
      _isLoading = true;
      _pendingFuture = ApiService.getPendingAdvices();
      _historyFuture = ApiService.getHistoryAdvices();
    });
    // 等 futures 完成后关闭 loading
    Future.wait([_pendingFuture, _historyFuture]).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('优化建议中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待处理'),
            Tab(text: '历史'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingList(theme),
                _buildHistoryList(theme),
              ],
            ),
    );
  }

  Widget _buildPendingList(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final advices = snapshot.data!;
        if (advices.isEmpty) {
          return Center(
            child: Text(
              '暂无待处理建议',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: advices.length,
          itemBuilder: (context, index) {
            final item = advices[index];
            return _buildAdviceCard(theme, item, isPending: true);
          },
        );
      },
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          );
        }
        final advices = snapshot.data!;
        if (advices.isEmpty) {
          return Center(
            child: Text(
              '暂无历史建议',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: advices.length,
          itemBuilder: (context, index) {
            final item = advices[index];
            return _buildAdviceCard(theme, item, isPending: false);
          },
        );
      },
    );
  }

  Widget _buildAdviceCard(ThemeData theme, Map<String, dynamic> item, {required bool isPending}) {
    // 提取字段（与 ApiService 模拟数据保持一致）
    final id = item['id'] ?? '未知';
    final type = item['type'] ?? '未知';
    final summary = item['summary'] ?? (isPending ? '无描述' : '已处理建议');
    final createdAt = item['created_at'] ?? (isPending ? '' : item['executed_at'] ?? '');

    // 待处理特有字段
    final expectedProfit = isPending ? item['expected_profit'] : null;
    final confidence = isPending ? item['confidence'] : null;

    // 历史特有字段
    final result = !isPending ? item['result'] : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 跳转到详情页，传递建议ID（实际应传递整个建议对象或至少ID）
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdviceDetailPage(adviceId: id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：类型 + ID + 时间
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(theme, type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: theme.textTheme.bodySmall?.copyWith(color: _typeColor(theme, type)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      id,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 摘要描述
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // 底部指标
              if (isPending && expectedProfit != null && confidence != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIndicator(
                      theme,
                      label: '预期收益',
                      value: expectedProfit,
                      color: theme.colorScheme.primary,
                    ),
                    _buildIndicator(
                      theme,
                      label: '置信度',
                      value: '${(confidence * 100).toStringAsFixed(0)}%',
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              if (!isPending && result != null)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(ThemeData theme, String type) {
    switch (type) {
      case '规则':
        return theme.colorScheme.primary;
      case '参数':
        return theme.colorScheme.secondary;
      case '策略':
        return Colors.orange;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildIndicator(ThemeData theme, {required String label, required String value, required Color color}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}