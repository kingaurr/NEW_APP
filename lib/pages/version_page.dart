// pages/version_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:flutter/services.dart';
import '../utils/biometrics_helper.dart'; // 导入指纹工具类

class VersionPage extends StatefulWidget {
  const VersionPage({Key? key}) : super(key: key);

  @override
  _VersionPageState createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage> {
  List<dynamic> _versions = [];
  bool _isLoading = true;
  String? _error;
  Set<String> _expandedIds = {}; // 展开的版本ID

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getVersions();
      if (data == null) {
        setState(() {
          _error = '加载失败';
        });
      } else {
        setState(() {
          _versions = data;
        });
      }
    } catch (e) {
      setState(() {
        _error = '异常: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rollback(String versionId) async {
    // 指纹验证（高风险操作，强制验证）
    bool authenticated = await BiometricsHelper.authenticate(
      reason: '请验证指纹以回滚版本',
    );
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指纹验证失败，操作取消')),
      );
      return;
    }

    // 二次确认
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认回滚'),
        content: Text('确定要回滚到版本 $versionId 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('回滚'),
          ),
        ],
      ),
    ) ?? false;
    if (!confirm) return;

    // 执行回滚
    final success = await ApiService.rollbackVersion(versionId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已成功回滚到版本 $versionId')),
      );
      _loadVersions(); // 刷新列表
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回滚失败，请重试')),
      );
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVersions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : _versions.isEmpty
                  ? Center(
                      child: Text(
                        '暂无版本记录',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _versions.length,
                      itemBuilder: (context, index) {
                        final v = _versions[index];
                        final id = v['id'] ?? '未知';
                        final timestamp = v['timestamp'] ?? 0;
                        final source = v['source'] ?? '未知';
                        final description = v['description'] ?? '';
                        final isExpanded = _expandedIds.contains(id);
                        final date = timestamp != 0
                            ? DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt())
                            : null;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _toggleExpand(id),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          id,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (date != null)
                                    Text(
                                      '${date.toLocal()}'.split('.')[0],
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          source,
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(description, style: theme.textTheme.bodyMedium),
                                  ],
                                  if (isExpanded) ...[
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _rollback(id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                          ),
                                          child: const Text('回滚到此版本'),
                                        ),
                                      ],
                                    ),
                                  ],
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