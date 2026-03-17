// lib/pages/heart_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class HeartDetailPage extends StatefulWidget {
  const HeartDetailPage({Key? key}) : super(key: key);

  @override
  _HeartDetailPageState createState() => _HeartDetailPageState();
}

class _HeartDetailPageState extends State<HeartDetailPage> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getHeartSummary();
      if (data == null) {
        setState(() {
          _error = '加载失败';
        });
      } else {
        setState(() {
          _summary = data;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('心脏详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(theme, '系统信息', [
                      _buildInfoRow(theme, '模式', _summary?['system']?['mode'] ?? 'sim'),
                      _buildInfoRow(theme, '心率', '${_summary?['system']?['heart_rate'] ?? 60} bpm'),
                      _buildInfoRow(theme, '紧急停止', _summary?['system']?['emergency_stop'] == true ? '是' : '否'),
                    ]),
                    _buildSection(theme, '熔断状态', [
                      _buildInfoRow(theme, '触发', _summary?['fuse']?['triggered'] == true ? '是' : '否'),
                      if (_summary?['fuse']?['triggered'] == true) ...[
                        _buildInfoRow(theme, '原因', _summary?['fuse']?['reason'] ?? ''),
                        _buildInfoRow(theme, '严重度', '${_summary?['fuse']?['severity'] ?? 0}'),
                        _buildInfoRow(theme, '剩余分钟', '${_summary?['fuse']?['remaining_minutes'] ?? 0}'),
                      ],
                    ]),
                    _buildSection(theme, '成本统计', [
                      _buildInfoRow(theme, '今日成本', '¥${_summary?['cost']?['today']?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildInfoRow(theme, '本月成本', '¥${_summary?['cost']?['month']?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildInfoRow(theme, '预算', '¥${_summary?['cost']?['budget']?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildInfoRow(theme, '状态', _summary?['cost']?['status'] ?? 'normal'),
                    ]),
                    _buildSection(theme, '数据源健康', [
                      _buildInfoRow(theme, '当前数据源', _summary?['data_source']?['current'] ?? ''),
                      ...?(_summary?['data_source']?['health'] as Map?)?.entries.map((entry) {
                        return _buildInfoRow(
                          theme,
                          entry.key,
                          '健康分: ${entry.value['health_score']}, 连续失败: ${entry.value['consecutive_failures']}',
                        );
                      }).toList(),
                    ]),
                    _buildSection(theme, '选股池', [
                      Text('交易池 (前10)', style: theme.textTheme.titleSmall),
                      ...(_summary?['pools']?['trade_pool'] as List? ?? []).take(10).map((item) {
                        return _buildInfoRow(theme, item['code'], '得分: ${item['score']}');
                      }),
                      const Divider(),
                      Text('影子池 (前10)', style: theme.textTheme.titleSmall),
                      ...(_summary?['pools']?['shadow_pool'] as List? ?? []).take(10).map((code) {
                        return _buildInfoRow(theme, code, '');
                      }),
                    ]),
                    _buildSection(theme, '左右脑', [
                      _buildInfoRow(theme, '右脑模式', _summary?['right_brain']?['mode'] ?? ''),
                      _buildInfoRow(theme, '右脑模型', _summary?['right_brain']?['model'] ?? ''),
                      _buildInfoRow(theme, '左脑模式', _summary?['left_brain']?['mode'] ?? ''),
                      _buildInfoRow(theme, '左脑模型', _summary?['left_brain']?['model'] ?? ''),
                      _buildInfoRow(theme, '左脑熔断', _summary?['left_brain']?['fuse_triggered'] == true ? '是' : '否'),
                    ]),
                    _buildSection(theme, '最新报告摘要', [
                      Text(_summary?['latest_report']?['content'] ?? '无'),
                    ]),
                    _buildSection(theme, '待处理建议', [
                      _buildInfoRow(theme, '数量', '${_summary?['pending_advice_count'] ?? 0}'),
                    ]),
                  ],
                ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}