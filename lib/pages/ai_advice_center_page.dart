// lib/pages/ai_advice_center_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class AiAdviceCenterPage extends StatefulWidget {
  const AiAdviceCenterPage({Key? key}) : super(key: key);

  @override
  State<AiAdviceCenterPage> createState() => _AiAdviceCenterPageState();
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$decision 建议'),
        content: Text('确定要$decision建议 “$summary” 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(decision),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.resolveAdvice(adviceId, decision);
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已$decision (模拟操作)')),
      );
      _loadData(); // 刷新列表
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI优化建议'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '待处理'),
              Tab(text: '历史'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingList(),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return FutureBuilder<List<dynamic>>(
      future: _pendingAdvicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final advices = snapshot.data!;
        if (advices.isEmpty) {
          return const Center(child: Text('暂无待处理建议'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: advices.length,
          itemBuilder: (ctx, index) {
            final item = advices[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(item['summary'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('类型: ${item['type'] ?? '未知'} · 预期: ${item['expected_profit'] ?? '0%'}'),
                    Text('置信度: ${item['confidence'] != null ? (item['confidence']*100).toInt() : 0}% · ${item['created_at'] ?? ''}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _resolveAdvice(item['id'], '同意', item['summary']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _resolveAdvice(item['id'], '拒绝', item['summary']),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<dynamic>>(
      future: _historyAdvicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('加载失败: ${snapshot.error ?? '未知错误'}'));
        }
        final advices = snapshot.data!;
        if (advices.isEmpty) {
          return const Center(child: Text('暂无历史建议'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: advices.length,
          itemBuilder: (ctx, index) {
            final item = advices[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(item['summary'] ?? ''),
                subtitle: Text('${item['result'] ?? ''} · ${item['executed_at'] ?? ''}'),
                trailing: const Icon(Icons.history, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}