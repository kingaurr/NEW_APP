// lib/widgets/event_timeline.dart
// ==================== 宫崎骏模块：事件时间线组件（2026-04-14） ====================
// 功能描述：
//   1. 按时间倒序展示宫崎骏编导层推送的异常事件。
//   2. 每条事件显示时间、类型、严重程度标签、摘要描述。
//   3. 支持下拉刷新、上拉加载更多（分页）。
//   4. 支持按严重程度过滤（P0/P1/P2）。
//   5. 点击事件可跳转详情页（预留接口）。
// 美学设计：
//   - 左侧时间轴线 + 圆点，右侧卡片内容，对称且富有节奏感。
//   - 严重程度标签配色（红/橙/蓝）语义清晰。
//   - 卡片圆角、柔和阴影、充足留白。
// 遵循规范：
//   - P0 真实数据原则：所有数据来自 API。
//   - P3 安全类型转换：使用 is 判断，禁用 as。
//   - P5 生命周期检查：setState 前检查 mounted。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';

/// 异常事件数据模型（安全解析）
class MiyazakiEvent {
  final String id;
  final String type;
  final String priority;
  final String summary;
  final DateTime timestamp;
  final int severity;
  final Map<String, dynamic> rawData;

  MiyazakiEvent({
    required this.id,
    required this.type,
    required this.priority,
    required this.summary,
    required this.timestamp,
    required this.severity,
    required this.rawData,
  });

  factory MiyazakiEvent.fromJson(Map<String, dynamic> json) {
    // 安全类型转换
    String id = json['id'] is String ? json['id'] : '';
    String type = json['type'] is String ? json['type'] : '未知类型';
    String priority = json['priority'] is String ? json['priority'] : 'P2';
    String summary = json['summary'] is String
        ? json['summary']
        : (json['recommendation'] is String ? json['recommendation'] : '暂无摘要');
    int severity = json['severity'] is int ? json['severity'] : 1;

    // 解析时间戳
    DateTime timestamp;
    if (json['timestamp'] is String) {
      timestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    } else if (json['timestamp'] is num) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num).toInt(),
      );
    } else {
      timestamp = DateTime.now();
    }

    return MiyazakiEvent(
      id: id,
      type: type,
      priority: priority,
      summary: summary,
      timestamp: timestamp,
      severity: severity,
      rawData: json,
    );
  }

  /// 获取严重程度对应的颜色
  Color get priorityColor {
    switch (priority) {
      case 'P0':
        return const Color(0xFFD32F2F); // 深红
      case 'P1':
        return const Color(0xFFFF9800); // 橙色
      default:
        return const Color(0xFF2196F3); // 蓝色
    }
  }

  /// 获取严重程度标签文本
  String get priorityLabel {
    switch (priority) {
      case 'P0':
        return '紧急';
      case 'P1':
        return '重要';
      default:
        return '普通';
    }
  }
}

/// 事件时间线组件
class EventTimeline extends StatefulWidget {
  final int? minSeverity;
  final Function(MiyazakiEvent)? onEventTap;

  const EventTimeline({Key? key, this.minSeverity, this.onEventTap})
      : super(key: key);

  @override
  State<EventTimeline> createState() => _EventTimelineState();
}

class _EventTimelineState extends State<EventTimeline> {
  final List<MiyazakiEvent> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchEvents({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
      });
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.fetchMiyazakiEvents(
        limit: 20,
        page: _currentPage,
        minSeverity: widget.minSeverity,
      );

      if (!mounted) return;

      if (result != null) {
        final List<dynamic> eventsJson = result['events'] is List
            ? result['events']
            : [];
        final List<MiyazakiEvent> newEvents = eventsJson
            .map((e) => MiyazakiEvent.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          if (refresh) {
            _events.clear();
          }
          _events.addAll(newEvents);
          _hasMore = newEvents.length >= 20;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = '加载失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchEvents();
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    await _fetchEvents(refresh: true);
  }

  void _handleEventTap(MiyazakiEvent event) {
    HapticFeedback.lightImpact();
    if (widget.onEventTap != null) {
      widget.onEventTap!(event);
    } else {
      // 默认跳转事件详情页（后续实现）
      // Navigator.pushNamed(context, '/miyazaki/event/${event.id}');
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _onRefresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              '暂无异常事件',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '系统运行正常',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _events.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildEventItem(_events[index]);
        },
      ),
    );
  }

  Widget _buildEventItem(MiyazakiEvent event) {
    return InkWell(
      onTap: () => _handleEventTap(event),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧时间轴
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    _formatTime(event.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.priorityColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧内容卡片
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.type,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: event.priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.priorityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: event.priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '查看详情',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
}