// lib/pages/report_detail_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class ReportDetailPage extends StatefulWidget {
  final String filename;
  final String reportType;

  const ReportDetailPage({Key? key, required this.filename, required this.reportType}) : super(key: key);

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final content = await ApiService.getReportContent(widget.filename, type: widget.reportType);
      if (content == null) {
        setState(() {
          _error = '报告不存在或加载失败';
        });
      } else {
        setState(() {
          _content = content;
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
        title: Text(widget.filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _content!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
    );
  }
}