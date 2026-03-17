// lib/pages/audit_log_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({Key? key}) : super(key: key);

  @override
  _AuditLogPageState createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

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
      // TODO: 替换为真实 API 调用，例如 ApiService.getAuditLogs()
      await Future.delayed(const Duration(milliseconds: 500));
      // 模拟数据
      _logs = [
        {
          'time': '2026-03-17 15:30:22',
          'operator': 'admin',
          'action': '模式切换',
          'detail': '从 sim 切换为 real',
          'result': '成功',
          'ip': '192.168.1.100',
        },
        {
          'time': '2026-03-17 14:20:11',
          'operator': 'admin',
          'action': '修改资金',
          'detail': '从 ¥100000 修改为 ¥150000',
          'result': '成功',
          'ip': '192.168.1.100',
        },
        {
          'time': '2026-03-17 11:05:03',
          'operator': 'system',
          'action': '执行优化建议',
          'detail': '采纳规则 adv_001 (提高均线突破阈值)',
          'result': '成功',
          'ip': '127.0.0.1',
        },
        {
          'time': '2026-03-17 09:45:33',
          'operator': 'admin',
          'action': '登录',
          'detail': '密码登录',
          'result': '成功',
          'ip': '192.168.1.100',
        },
        {
          'time': '2026-03-16 22:10:18',
          'operator': 'admin',
          'action': '修改预算',
          'detail': '月预算从 200 修改为 250',
          'result': '成功',
          'ip': '192.168.1.100',
        },
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('审计日志'),
        actions: [
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
              : _logs.isEmpty
                  ? Center(
                      child: Text(
                        '暂无审计日志',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (ctx, index) {
                        final log = _logs[index];
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
                                  Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              log['action'] ?? '',
                                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              log['time'] ?? '',
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log['detail'] ?? '',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '操作人: ${log['operator']}  IP: ${log['ip']}  结果: ${log['result']}',
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
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '审计日志详情',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    final content = '''
时间: ${log['time']}
操作人: ${log['operator']}
IP: ${log['ip']}
动作: ${log['action']}
详情: ${log['detail']}
结果: ${log['result']}
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
            _buildDetailRow(theme, '时间', log['time']),
            _buildDetailRow(theme, '操作人', log['operator']),
            _buildDetailRow(theme, 'IP', log['ip']),
            _buildDetailRow(theme, '动作', log['action']),
            _buildDetailRow(theme, '详情', log['detail']),
            _buildDetailRow(theme, '结果', log['result']),
            const SizedBox(height: 20),
          ],
        ),
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
            width: 60,
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