// lib/pages/alert_list_page.dart
import 'package:flutter/material.dart';
import 'alert_detail_page.dart';

class AlertListPage extends StatefulWidget {
  const AlertListPage({Key? key}) : super(key: key);

  @override
  _AlertListPageState createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // TODO: 替换为真实 API 调用
      await Future.delayed(const Duration(milliseconds: 500));
      // 模拟数据
      _alerts = [
        {
          'id': 'a1',
          'level': 'ERROR',
          'content': '数据源 tushare 连续失败 3 次',
          'time': '2026-03-17 15:23',
          'read': false,
        },
        {
          'id': 'a2',
          'level': 'WARNING',
          'content': '内存使用率超过 85%',
          'time': '2026-03-17 14:10',
          'read': true,
        },
        {
          'id': 'a3',
          'level': 'ERROR',
          'content': '右脑模型调用超时',
          'time': '2026-03-17 11:45',
          'read': false,
        },
        {
          'id': 'a4',
          'level': 'INFO',
          'content': '系统模式切换为 模拟',
          'time': '2026-03-17 09:30',
          'read': true,
        },
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    // TODO: 调用 API 标记已读
    setState(() {
      final index = _alerts.indexWhere((a) => a['id'] == id);
      if (index != -1) _alerts[index]['read'] = true;
    });
  }

  Future<void> _markAllRead() async {
    // TODO: 调用 API 全部标记已读
    setState(() {
      for (var a in _alerts) a['read'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              : _alerts.isEmpty
                  ? Center(
                      child: Text(
                        '暂无告警',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (ctx, index) {
                        final alert = _alerts[index];
                        final level = alert['level'] ?? 'INFO';
                        final isError = level == 'ERROR';
                        final isWarning = level == 'WARNING';
                        final color = isError
                            ? theme.colorScheme.error
                            : (isWarning ? theme.colorScheme.secondary : theme.colorScheme.primary);
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () async {
                              final shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlertDetailPage(alert: alert),
                                ),
                              );
                              if (shouldRefresh == true) {
                                await _markAsRead(alert['id']);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert['content'] ?? '',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: alert['read'] == false ? FontWeight.bold : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          alert['time'] ?? '',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (alert['read'] == false)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}