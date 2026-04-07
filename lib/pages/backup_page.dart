// lib/pages/backup_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 备份管理页面
/// 显示备份列表，支持创建备份和恢复备份
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isLoading = true;
  List<dynamic> _backups = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    // 修复：添加 mounted 检查
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final backups = await ApiService.getBackups();
      if (mounted) {
        setState(() {
          _backups = backups ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载备份列表失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以创建备份',
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final result = await ApiService.createBackup();
      if (mounted) {
        if (result?['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份创建成功'), backgroundColor: Colors.green),
          );
          _loadBackups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: ${result?['error'] ?? '未知错误'}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建异常: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认恢复备份', style: TextStyle(color: Colors.white)),
        content: const Text(
          '恢复备份将覆盖当前数据，操作不可逆。确定要继续吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 指纹验证
    final authenticated = await BiometricsHelper.authenticateAndGetToken(
      reason: '验证指纹以恢复备份',
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final result = await ApiService.restoreBackup(backupId);
      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份恢复成功'), backgroundColor: Colors.green),
          );
          _loadBackups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('恢复失败'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复异常: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '未知';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _createBackup,
            tooltip: '创建备份',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBackups,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _backups.isEmpty
                  ? const Center(
                      child: Text('暂无备份', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final backup = _backups[index];
                        final backupId = backup['id'] ?? backup['backup_id'] ?? '';
                        final createdAt = backup['created_at'] ?? backup['timestamp'] ?? '';
                        final size = backup['size'] ?? 0;
                        return Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.archive, color: Color(0xFFD4AF37)),
                            title: Text(
                              backupId,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '创建时间: ${_formatDate(createdAt)}  大小: ${(size / 1024).toStringAsFixed(2)} KB',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _restoreBackup(backupId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('恢复'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}