// lib/pages/system_log_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemLogPage extends StatefulWidget {
  const SystemLogPage({Key? key}) : super(key: key);

  @override
  _SystemLogPageState createState() => _SystemLogPageState();
}

class _SystemLogPageState extends State<SystemLogPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;
  String _selectedLevel = 'ALL'; // ALL, ERROR, WARNING, INFO

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // TODO: 替换为真实 API 调用，例如 ApiService.getSystemLogs(level: _selectedLevel)
      await Future.delayed(const Duration(milliseconds: 500));
      // 模拟数据
      _logs = [
        {
          'timestamp': '2026-03-17 15:23:45',
          'level': 'ERROR',
          'message': '数据源 tushare 连接超时',
          'file': 'datasource_tushare.py',
          'line': 102,
          'stack': 'Traceback...',
        },
        {
          'timestamp': '2026-03-17 15:10:22',
          'level': 'WARNING',
          'message': '内存使用率 86%',
          'file': 'monitor.py',
          'line': 45,
        },
        {
          'timestamp': '2026-03-17 14:55:03',
          'level': 'INFO',
          'message': '选股器完成筛选，生成 50 只候选股',
          'file': 'stock_selector.py',
          'line': 210,
        },
        {
          'timestamp': '2026-03-17 14:30:11',
          'level': 'ERROR',
          'message': '左脑模型调用失败: timeout',
          'file': 'ai_left_brain.py',
          'line': 188,
          'stack': 'requests.exceptions.Timeout...',
        },
        {
          'timestamp': '2026-03-17 14:00:00',
          'level': 'INFO',
          'message': '系统启动完成',
          'file': 'main.py',
          'line': 1,
        },
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedLevel == 'ALL') return _logs;
    return _logs.where((log) => log['level'] == _selectedLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统日志'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedLevel = value;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'ALL', child: Text('全部')),
              const PopupMenuItem(value: 'ERROR', child: Text('错误')),
              const PopupMenuItem(value: 'WARNING', child: Text('警告')),
              const PopupMenuItem(value: 'INFO', child: Text('信息')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
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
              : _filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        '暂无日志',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (ctx, index) {
                        final log = _filteredLogs[index];
                        final level = log['level'] ?? 'INFO';
                        final color = level == 'ERROR'
                            ? theme.colorScheme.error
                            : (level == 'WARNING' ? theme.colorScheme.secondary : theme.colorScheme.primary);
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              _showLogDetail(context, log);
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
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                level,
                                                style: theme.textTheme.bodySmall?.copyWith(color: color),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                log['message'] ?? '',
                                                style: theme.textTheme.bodyMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log['timestamp'] ?? '',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showLogDetail(BuildContext context, Map<String, dynamic> log) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '日志详情',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        final content = '''
时间: ${log['timestamp']}
级别: ${log['level']}
消息: ${log['message']}
文件: ${log['file']}:${log['line']}
堆栈: ${log['stack'] ?? '无'}
''';
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow(theme, '时间', log['timestamp']),
                      _buildDetailRow(theme, '级别', log['level']),
                      _buildDetailRow(theme, '消息', log['message']),
                      _buildDetailRow(theme, '文件', '${log['file']}:${log['line']}'),
                      if (log['stack'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '堆栈信息',
                          style: theme.textTheme.titleSmall,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            log['stack']!,
                            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}