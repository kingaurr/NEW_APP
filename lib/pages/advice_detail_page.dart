// pages/advice_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';

// 模拟指纹验证（需替换为真实 local_auth 实现）
Future<bool> _authenticateWithBiometrics() async {
  // TODO: 集成 local_auth 插件
  return await showDialog<bool>(
    context: navigatorKey.currentContext!,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).dialogBackgroundColor,
      title: const Text('指纹验证'),
      content: const Text('请按指纹以继续操作'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('模拟验证通过'),
        ),
      ],
    ),
  ) ?? false;
}

class AdviceDetailPage extends StatefulWidget {
  final String adviceId;

  const AdviceDetailPage({Key? key, required this.adviceId}) : super(key: key);

  @override
  _AdviceDetailPageState createState() => _AdviceDetailPageState();
}

class _AdviceDetailPageState extends State<AdviceDetailPage> {
  Map<String, dynamic>? _advice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdviceDetail();
  }

  Future<void> _loadAdviceDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAdviceDetail(widget.adviceId);
      if (data == null) {
        setState(() {
          _error = '建议不存在或加载失败';
        });
      } else {
        setState(() {
          _advice = data;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载异常: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(String decision) async {
    // 如果启用了指纹锁，先验证
    bool fingerprintEnabled = true; // TODO: 从存储读取
    if (fingerprintEnabled) {
      bool authenticated = await _authenticateWithBiometrics();
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
        return;
      }
    }

    final success = await ApiService.resolveAdvice(widget.adviceId, decision);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建议已$decision')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('建议详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdviceDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_advice == null) return const SizedBox.shrink();
    final advice = _advice!;
    final status = advice['status'] ?? 'unknown';
    final type = advice['type'] ?? '未知';
    final source = advice['source'] ?? '未知';
    final priority = advice['priority'] ?? 3;
    final createdAt = advice['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch((advice['created_at'] * 1000).toInt())
        : null;
    final content = advice['content'] is Map ? advice['content'] : {};
    final validationResult = advice['validation_result'] as Map?;

    final bool isActionable = (status == 'pending' || status == 'waiting_approval');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 状态卡片
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '建议 #${advice['id']}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(theme, status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusText(status),
                        style: theme.textTheme.bodySmall?.copyWith(color: _statusColor(theme, status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(theme, '类型', type),
                _infoRow(theme, '来源', source),
                _infoRow(theme, '优先级', '$priority'),
                if (createdAt != null)
                  _infoRow(theme, '创建时间', '${createdAt.toLocal()}'.split('.')[0]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 建议内容卡片
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('建议内容', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('内容已复制')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    content.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 验证报告卡片
        if (validationResult != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('验证报告', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _infoRow(theme, '状态', validationResult['status'] ?? '未知'),
                  if (validationResult['message'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationResult['message'],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  if (validationResult['metrics'] != null) ...[
                    const Divider(height: 24),
                    Text('指标', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ..._buildMetrics(theme, validationResult['metrics']),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // 操作按钮（仅当可操作时显示）
        if (isActionable)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction('approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('同意'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction('reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('拒绝'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'pending':
      case 'waiting_approval':
        return Colors.orange;
      case 'validating':
        return Colors.blue;
      case 'executed':
        return theme.colorScheme.primary;
      case 'rejected':
      case 'expired':
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return '待验证';
      case 'validating':
        return '验证中';
      case 'waiting_approval':
        return '待审批';
      case 'executed':
        return '已执行';
      case 'rejected':
        return '已拒绝';
      case 'expired':
        return '已过期';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }

  List<Widget> _buildMetrics(ThemeData theme, Map<String, dynamic> metrics) {
    List<Widget> rows = [];
    metrics.forEach((key, value) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key, style: theme.textTheme.bodySmall),
              Text(value.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    });
    return rows;
  }
}