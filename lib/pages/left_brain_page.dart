// pages/left_brain_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class LeftBrainPage extends StatefulWidget {
  const LeftBrainPage({Key? key}) : super(key: key);

  @override
  _LeftBrainPageState createState() => _LeftBrainPageState();
}

class _LeftBrainPageState extends State<LeftBrainPage> {
  Map<String, dynamic>? _status;
  List<dynamic> _decisions = [];
  bool _isLoadingStatus = true;
  bool _isLoadingDecisions = true;
  String? _statusError;
  String? _decisionsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStatus(), _loadDecisions()]);
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _statusError = null;
    });
    try {
      final data = await ApiService.getLeftBrainStatus();
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

  Future<void> _loadDecisions() async {
    setState(() {
      _isLoadingDecisions = true;
      _decisionsError = null;
    });
    try {
      final data = await ApiService.getLeftBrainDecisions();
      if (data == null) {
        setState(() => _decisionsError = '加载失败');
      } else {
        setState(() => _decisions = data);
      }
    } catch (e) {
      setState(() => _decisionsError = '异常: $e');
    } finally {
      setState(() => _isLoadingDecisions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('左脑详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
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
            // 最近决策列表
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最近决策', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _isLoadingDecisions
                        ? const Center(child: CircularProgressIndicator())
                        : _decisionsError != null
                            ? Text(_decisionsError!, style: TextStyle(color: theme.colorScheme.error))
                            : _decisions.isEmpty
                                ? Center(
                                    child: Text(
                                      '暂无决策',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _decisions.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final decision = _decisions[index];
                                      final approved = decision['approved'] == true;
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: approved ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              approved ? Icons.check : Icons.close,
                                              color: approved ? Colors.green : Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        title: Text(decision['code'] ?? '未知'),
                                        subtitle: Text(decision['reason'] ?? ''),
                                        trailing: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (decision['position_ratio'] != null)
                                              Text(
                                                '仓位: ${(decision['position_ratio'] * 100).toStringAsFixed(0)}%',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            Text(
                                              _formatTime(decision['timestamp']),
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
      ),
    );
  }

  Widget _buildStatusContent(ThemeData theme) {
    if (_status == null) return const SizedBox.shrink();
    return Column(
      children: [
        _infoRow(theme, '模式', _status!['mode'] ?? '未知'),
        _infoRow(theme, '模型', _status!['model'] ?? '未知'),
        _infoRow(theme, '熔断', _status!['fuse_triggered'] == true ? '已触发' : '正常'),
        if (_status!['keyword_optimizers'] != null)
          ..._buildKeywordOptimizers(theme, _status!['keyword_optimizers']),
      ],
    );
  }

  List<Widget> _buildKeywordOptimizers(ThemeData theme, Map<String, dynamic> optimizers) {
    List<Widget> widgets = [];
    optimizers.forEach((regime, weights) {
      if (weights is Map) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regime, style: theme.textTheme.titleSmall),
                ...weights.entries.map((e) => _infoRow(theme, e.key, e.value.toString())),
              ],
            ),
          ),
        );
      }
    });
    return widgets;
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