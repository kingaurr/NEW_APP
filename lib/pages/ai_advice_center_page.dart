// pages/ai_advice_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'advice_detail_page.dart';

class AiAdviceCenterPage extends StatefulWidget {
  const AiAdviceCenterPage({Key? key}) : super(key: key);

  @override
  _AiAdviceCenterPageState createState() => _AiAdviceCenterPageState();
}

class _AiAdviceCenterPageState extends State<AiAdviceCenterPage> {
  late Future<List<dynamic>> _pendingAdvicesFuture;
  late Future<List<dynamic>> _historyAdvicesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pendingAdvicesFuture = ApiService.getPendingAdvices();
      _historyAdvicesFuture = ApiService.getHistoryAdvices();
    });
  }

  Future<void> _resolveAdvice(String adviceId, String decision, String summary) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          '$decision 建议',
          style: theme.textTheme.titleMedium,
        ),
        content: Text('确定要$decision建议 “$summary” 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == '同意' ? theme.colorScheme.primary : theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(decision),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.resolveAdvice(adviceId, decision);
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已$decision (模拟操作)'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      _loadData(); // 刷新列表
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI优化建议'),
          bottom: TabBar(
            tabs: const [
              Tab(text: '待处理'),
              Tab(text: '历史'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingList(theme),
            _buildHistoryList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _pendingAdvicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
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
          padding: const EdgeInsets.all(8),
          itemCount: advices.length,
          itemBuilder: (ctx, index) {
            final item = advices[index];
            final confidence = item['confidence'] != null ? (item['confidence'] * 100).toInt() : 0;
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['summary'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '类型: ${item['type'] ?? '未知'} · 预期: ${item['expected_profit'] ?? '0%'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '置信度: $confidence% · ${item['created_at'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: theme.colorScheme.primary),
                          onPressed: () => _resolveAdvice(item['id'], '同意', item['summary']),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.colorScheme.error),
                          onPressed: () => _resolveAdvice(item['id'], '拒绝', item['summary']),
                        ),
                      ],
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

  Widget _buildHistoryList(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: _historyAdvicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              '加载失败: ${snapshot.error ?? '未知错误'}',
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
          padding: const EdgeInsets.all(8),
          itemCount: advices.length,
          itemBuilder: (ctx, index) {
            final item = advices[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  item['summary'] ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${item['result'] ?? ''} · ${item['executed_at'] ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.history, color: theme.colorScheme.primary),
              ),
            );
          },
        );
      },
    );
  }
}