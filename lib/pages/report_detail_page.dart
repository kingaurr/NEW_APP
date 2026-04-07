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

  // 发送分析时的加载状态
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _markAsRead();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getReportContent(
        widget.filename,
        type: widget.reportType,
      );
      if (mounted) {
        if (result != null) {
          setState(() {
            _content = result;
          });
        } else {
          setState(() {
            _errorMessage = '获取报告内容失败';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
        });
      }
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

  // 新增：发送报告给千寻分析
  Future<void> _sendToQianxun() async {
    if (_content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('报告内容为空，无法分析'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final result = await ApiService.voiceAsk(_content);
      if (mounted) {
        if (result != null && result['answer'] != null) {
          // 显示分析结果对话框
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFFD4AF37)),
                  SizedBox(width: 8),
                  Text('千寻分析', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(
                  result['answer'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('未收到有效回复');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
          // 新增：发送给千寻分析按钮
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            tooltip: '发送给千寻分析',
            onPressed: _isSending ? null : _sendToQianxun,
          ),
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