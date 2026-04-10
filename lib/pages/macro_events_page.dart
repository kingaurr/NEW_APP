// lib/pages/macro_events_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// 宏观事件页面
class MacroEventsPage extends StatefulWidget {
  const MacroEventsPage({super.key});

  @override
  State<MacroEventsPage> createState() => _MacroEventsPageState();
}

class _MacroEventsPageState extends State<MacroEventsPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _events = [];

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
      // 从心脏获取宏观事件数据
      final result = await ApiService.httpGet('/macro/events');
      if (result != null && result is Map) {
        final events = result['events'] as List<dynamic>? ?? [];
        setState(() {
          _events = events;
        });
      } else {
        // 若接口未就绪，尝试从日报的市场环境中获取
        final report = await ApiService.getDailyReport();
        if (report != null) {
          final marketEnv = report['market_environment'] as Map<String, dynamic>? ?? {};
          final keyEvents = marketEnv['key_events'] as List<dynamic>? ?? [];
          setState(() {
            _events = keyEvents;
          });
        }
      }
      setState(() {
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
        title: const Text('宏观事件'),
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
    if (_events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.newspaper, color: Colors.white38, size: 64),
            SizedBox(height: 16),
            Text(
              '暂无宏观事件',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(_events[index]);
      },
    );
  }

  Widget _buildEventCard(dynamic event) {
    final title = event['title'] as String? ?? '未知事件';
    final description = event['description'] as String? ?? '';
    final timestamp = event['timestamp'] as String? ?? '';
    final importance = event['importance'] as String? ?? 'medium';
    final source = event['source'] as String? ?? '';
    final url = event['url'] as String?;

    Color importanceColor;
    IconData importanceIcon;
    switch (importance) {
      case 'high':
        importanceColor = Colors.red;
        importanceIcon = Icons.priority_high;
        break;
      case 'medium':
        importanceColor = Colors.orange;
        importanceIcon = Icons.warning;
        break;
      case 'low':
        importanceColor = Colors.green;
        importanceIcon = Icons.info;
        break;
      default:
        importanceColor = Colors.grey;
        importanceIcon = Icons.circle;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: importanceColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(importanceIcon, color: importanceColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: importanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    importance.toUpperCase(),
                    style: TextStyle(color: importanceColor, fontSize: 10),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      timestamp.isNotEmpty ? timestamp : '时间未知',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                if (source.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.source, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        source,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            if (url != null && url.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // 在浏览器中打开链接（需要添加 url_launcher 依赖）
                  // 这里仅作示意，实际可集成 url_launcher
                },
                child: Text(
                  url,
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}