// pages/right_brain_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class RightBrainPage extends StatefulWidget {
  const RightBrainPage({Key? key}) : super(key: key);

  @override
  _RightBrainPageState createState() => _RightBrainPageState();
}

class _RightBrainPageState extends State<RightBrainPage> {
  Map<String, dynamic>? _status;
  List<dynamic> _signals = [];
  bool _isLoadingStatus = true;
  bool _isLoadingSignals = true;
  String? _statusError;
  String? _signalsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStatus(), _loadSignals()]);
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _statusError = null;
    });
    try {
      final data = await ApiService.getRightBrainStatus();
      if (data == null) {
        setState(() => _statusError = '加载失败');
      } else {
        setState(() => _status = data);
      }
    } catch (e) {
      setState(() => _statusError = '异常: $e');
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _loadSignals() async {
    setState(() {
      _isLoadingSignals = true;
      _signalsError = null;
    });
    try {
      final data = await ApiService.getRightBrainSignals();
      if (data == null) {
        setState(() => _signalsError = '加载失败');
      } else {
        setState(() => _signals = data);
      }
    } catch (e) {
      setState(() => _signalsError = '异常: $e');
    } finally {
      setState(() => _isLoadingSignals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('右脑详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ListView(
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
                  Text('运行状态', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _isLoadingStatus
                      ? const Center(child: CircularProgressIndicator())
                      : _statusError != null
                          ? Text(_statusError!, style: TextStyle(color: theme.colorScheme.error))
                          : _buildStatusContent(theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 最近信号列表
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最近信号', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _isLoadingSignals
                      ? const Center(child: CircularProgressIndicator())
                      : _signalsError != null
                          ? Text(_signalsError!, style: TextStyle(color: theme.colorScheme.error))
                          : _signals.isEmpty
                              ? Center(
                                  child: Text(
                                    '暂无信号',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _signals.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final signal = _signals[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _signalColor(signal['action']).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            signal['action']?.substring(0, 1).toUpperCase() ?? '?',
                                            style: TextStyle(
                                              color: _signalColor(signal['action']),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(signal['code'] ?? '未知'),
                                      subtitle: Text(signal['reason'] ?? ''),
                                      trailing: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '置信度: ${signal['confidence'] ?? 0}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          Text(
                                            _formatTime(signal['timestamp']),
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(ThemeData theme) {
    if (_status == null) return const SizedBox.shrink();
    return Column(
      children: [
        _infoRow(theme, '模式', _status!['mode'] ?? '未知'),
        _infoRow(theme, '模型', _status!['model'] ?? '未知'),
        _infoRow(theme, '上次调用', _formatTime(_status!['last_call'])),
        _infoRow(theme, '使用API', _status!['use_api'] == true ? '是' : '否'),
        _infoRow(theme, '调用间隔', '${_status!['call_interval'] ?? 300}秒'),
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

  Color _signalColor(String? action) {
    switch (action) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      case 'hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) return '无';
    final dt = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute}';
  }
}