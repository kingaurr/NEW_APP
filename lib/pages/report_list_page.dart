// lib/pages/report_list_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'report_detail_page.dart';

/// 报告列表页面
/// 显示系统生成的各类报告（日报/周报/月报）
class ReportListPage extends StatefulWidget {
  final String type; // daily, weekly, monthly

  const ReportListPage({super.key, required this.type});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getReportsList(type: widget.type);
      if (result != null) {
        setState(() {
          _reports = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取报告列表失败';
        });
      }
    } catch (e) {
      debugPrint('加载报告列表失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'daily':
        return '日报';
      case 'weekly':
        return '周报';
      case 'monthly':
        return '月报';
      default:
        return '报告';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      if (widget.type == 'daily') {
        return '${date.month}月${date.day}日';
      } else if (widget.type == 'weekly') {
        return '第${date.week}周 (${date.year})';
      } else {
        return '${date.year}年${date.month}月';
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _navigateToDetail(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailPage(
          filename: report['filename'],
          reportType: widget.type,
        ),
      ),
    ).then((_) {
      _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getTypeName(widget.type)}列表'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
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
                        onPressed: _loadReports,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无报告',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return _buildReportItem(report);
                      },
                    ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final filename = report['filename'] ?? '';
    final dateStr = _extractDateFromFilename(filename);
    final title = report['title'] ?? _getTypeName(widget.type);
    final summary = report['summary'] ?? '';
    final hasRead = report['read'] ?? false;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasRead ? Colors.grey.withOpacity(0.3) : const Color(0xFFD4AF37).withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(widget.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(widget.type),
                  color: _getTypeColor(widget.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(dateStr),
                      style: TextStyle(
                        color: hasRead ? Colors.grey : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (summary.isNotEmpty)
                      Text(
                        summary,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!hasRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.description;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'daily':
        return Colors.blue;
      case 'weekly':
        return Colors.green;
      case 'monthly':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _extractDateFromFilename(String filename) {
    // 文件名格式: daily_20260326.json 或 weekly_2026W13.json
    try {
      if (filename.contains('daily_')) {
        final dateStr = filename.replaceAll('daily_', '').replaceAll('.json', '');
        return dateStr;
      } else if (filename.contains('weekly_')) {
        final weekStr = filename.replaceAll('weekly_', '').replaceAll('.json', '');
        return weekStr;
      } else if (filename.contains('monthly_')) {
        final monthStr = filename.replaceAll('monthly_', '').replaceAll('.json', '');
        return monthStr;
      }
      return filename;
    } catch (e) {
      return filename;
    }
  }
}