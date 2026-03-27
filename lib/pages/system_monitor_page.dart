// lib/pages/system_monitor_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../api_service.dart';

/// 系统实时监控页面
/// 显示CPU、内存、磁盘使用率，模块健康状态，事件流
class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key});

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  Timer? _timer;
  bool _isLoading = true;
  Map<String, dynamic> _monitorData = {};
  List<dynamic> _moduleHealth = [];
  List<dynamic> _recentEvents = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    // 每5秒刷新一次
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final result = await ApiService.getSystemMonitor();
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _monitorData = result;
          _moduleHealth = result['module_health'] ?? [];
          _recentEvents = result['recent_events'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = '获取监控数据失败';
        });
      }
    } catch (e) {
      debugPrint('加载系统监控失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  Color _getPercentColor(double value) {
    if (value >= 0.9) return Colors.red;
    if (value >= 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统监控'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
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
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 资源使用率卡片
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '资源使用率',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildResourceRow('CPU', _monitorData['cpu_usage'] ?? 0.0),
                              const SizedBox(height: 12),
                              _buildResourceRow('内存', _monitorData['memory_usage'] ?? 0.0),
                              const SizedBox(height: 12),
                              _buildResourceRow('磁盘', _monitorData['disk_usage'] ?? 0.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 模块健康状态
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '模块健康状态',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_moduleHealth.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      '暂无模块数据',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ..._moduleHealth.map((module) => _buildModuleItem(module)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 最近事件
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '最近事件',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_recentEvents.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      '暂无事件',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ..._recentEvents.take(10).map((event) => _buildEventItem(event)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResourceRow(String label, double usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              _formatPercent(usage),
              style: TextStyle(
                color: _getPercentColor(usage),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: usage,
          backgroundColor: Colors.grey[800],
          color: _getPercentColor(usage),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildModuleItem(Map<String, dynamic> module) {
    final name = module['name'] ?? '未知';
    final status = module['status'] ?? 'unknown';
    final color = status == 'healthy' ? Colors.green : (status == 'warning' ? Colors.orange : Colors.red);
    final statusText = status == 'healthy' ? '健康' : (status == 'warning' ? '预警' : '异常');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final level = event['level'] ?? 'info';
    final message = event['message'] ?? '';
    final timestamp = event['timestamp'] ?? '';
    Color levelColor;
    IconData icon;
    if (level == 'error') {
      levelColor = Colors.red;
      icon = Icons.error;
    } else if (level == 'warning') {
      levelColor = Colors.orange;
      icon = Icons.warning;
    } else {
      levelColor = Colors.green;
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: levelColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (timestamp.isNotEmpty)
                  Text(
                    _formatTime(timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}