// lib/pages/data_source_health_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 数据源健康详情页面
class DataSourceHealthPage extends StatefulWidget {
  const DataSourceHealthPage({super.key});

  @override
  State<DataSourceHealthPage> createState() => _DataSourceHealthPageState();
}

class _DataSourceHealthPageState extends State<DataSourceHealthPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getDataSourceHealth();
      setState(() {
        _healthData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('数据源健康'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败: $_error', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final current = _healthData?['current'] ?? '未知';
    final health = _healthData?['health'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前主数据源
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, color: Color(0xFFD4AF37), size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前主数据源',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 各数据源健康分
          const Text(
            '数据源健康评分',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...health.entries.map((entry) => _buildHealthCard(entry.key, entry.value)).toList(),

          const SizedBox(height: 20),

          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '健康分说明',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '• 健康分 ≥ 80：正常',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                  '• 健康分 60-79：注意',
                  style: TextStyle(color: Colors.orange),
                ),
                Text(
                  '• 健康分 < 60：自动切换备用源',
                  style: TextStyle(color: Colors.red),
                ),
                Text(
                  '• 健康分 < 40：触发熔断，暂停使用',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String source, dynamic healthValue) {
    final score = healthValue is num
        ? healthValue.toDouble()
        : (healthValue is Map ? (healthValue['score'] ?? 0).toDouble() : 0.0);
    Color color;
    IconData icon;
    if (score >= 80) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (score >= 60) {
      color = Colors.orange;
      icon = Icons.warning;
    } else if (score >= 40) {
      color = Colors.red;
      icon = Icons.error;
    } else {
      color = Colors.deepOrange;
      icon = Icons.dangerous;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${score.toStringAsFixed(1)}分',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}