// lib/pages/report_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../api_service.dart';

/// 报告详情页面
/// 显示报告的完整内容（Markdown格式）
class ReportDetailPage extends StatefulWidget {
  final String filename;
  final String reportType;

  const ReportDetailPage({
    super.key,
    required this.filename,
    required this.reportType,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  bool _isLoading = true;
  String _content = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
    _markAsRead();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getReportContent(
        widget.filename,
        type: widget.reportType,
      );
      if (result != null) {
        setState(() {
          _content = result;
        });
      } else {
        setState(() {
          _errorMessage = '获取报告内容失败';
        });
      }
    } catch (e) {
      debugPrint('加载报告失败: $e');
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

  Future<void> _markAsRead() async {
    try {
      await ApiService.markReportRead(widget.filename, widget.reportType);
    } catch (e) {
      debugPrint('标记已读失败: $e');
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

  String _formatTitle(String filename) {
    try {
      if (widget.reportType == 'daily') {
        final dateStr = filename.replaceAll('daily_', '').replaceAll('.json', '');
        return '${_getTypeName(widget.reportType)} - $dateStr';
      } else if (widget.reportType == 'weekly') {
        final weekStr = filename.replaceAll('weekly_', '').replaceAll('.json', '');
        return '${_getTypeName(widget.reportType)} - $weekStr';
      } else if (widget.reportType == 'monthly') {
        final monthStr = filename.replaceAll('monthly_', '').replaceAll('.json', '');
        return '${_getTypeName(widget.reportType)} - $monthStr';
      }
      return filename;
    } catch (e) {
      return filename;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatTitle(widget.filename)),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
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
                        onPressed: _loadReport,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Markdown(
                    data: _content,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      h3: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      p: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      listBullet: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                      ),
                      code: TextStyle(
                        color: Colors.green[300],
                        backgroundColor: Colors.grey[900],
                        fontFamily: 'monospace',
                      ),
                      blockquote: TextStyle(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                        background: Paint()..color = Colors.grey[800]!,
                      ),
                      tableHead: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                      tableBody: const TextStyle(color: Colors.white70),
                    ),
                    selectable: true,
                  ),
                ),
    );
  }
}