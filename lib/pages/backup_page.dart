// pages/backup_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';
import '../utils/biometrics_helper.dart'; // 导入真实指纹工具

class BackupPage extends StatefulWidget {
  const BackupPage({Key? key}) : super(key: key);

  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<dynamic> _backups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getBackups();
      if (data == null) {
        setState(() {
          _error = '加载失败';
        });
      } else {
        setState(() {
          _backups = data;
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

  Future<void> _createBackup() async {
    // 指纹验证（高风险操作）
    bool authenticated = await BiometricsHelper.authenticate(
      reason: '请验证指纹以创建备份',
    );
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指纹验证失败，操作取消')),
      );
      return;
    }

    final result = await ApiService.createBackup();
    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份创建成功')),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建备份失败')),
      );
    }
  }

  Future<void> _restoreBackup(String filename) async {
    // 指纹验证（高风险操作）
    bool authenticated = await BiometricsHelper.authenticate(
      reason: '请验证指纹以恢复备份',
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
        title: const Text('确认恢复'),
        content: Text('确定要从备份 $filename 恢复吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('恢复'),
          ),
        ],
      ),
    ) ?? false;
    if (!confirm) return;

    final success = await ApiService.restoreBackup(filename);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已从 $filename 恢复')),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复失败')),
      );
    }
  }

  void _downloadBackup(String filename) {
    // 直接打开下载链接（在Web或移动端可能不同，这里演示通过浏览器下载）
    // 实际可能需要调用一个下载接口，例如 '/api/backup/download/$filename'
    final url = '${ApiService._baseUrl}/backup/download/$filename';
    // TODO: 使用 url_launcher 或 WebView 下载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('下载功能待实现: $url')),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : Column(
                  children: [
                    // 手动创建备份按钮
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _createBackup,
                        icon: const Icon(Icons.add),
                        label: const Text('创建新备份'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // 备份列表
                    Expanded(
                      child: _backups.isEmpty
                          ? Center(
                              child: Text(
                                '暂无备份',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _backups.length,
                              itemBuilder: (context, index) {
                                final backup = _backups[index];
                                final filename = backup['filename'] ?? '未知';
                                final dateStr = backup['date'] ?? '';
                                final size = backup['size'] ?? 0;
                                final mtime = backup['mtime'] ?? 0;
                                final date = mtime != 0
                                    ? DateTime.fromMillisecondsSinceEpoch(mtime * 1000)
                                    : null;
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                filename,
                                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _formatSize(size),
                                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (date != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('yyyy-MM-dd HH:mm').format(date),
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => _downloadBackup(filename),
                                              icon: const Icon(Icons.download, size: 18),
                                              label: const Text('下载'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () => _restoreBackup(filename),
                                              icon: const Icon(Icons.restore, size: 18),
                                              label: const Text('恢复'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: theme.colorScheme.error,
                                                foregroundColor: theme.colorScheme.onError,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}