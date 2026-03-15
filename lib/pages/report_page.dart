// lib/pages/report_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, Future<List<dynamic>?>?> _reportsFutures = {
    'daily': null,
    'weekly': null,
    'monthly': null,
  };
  String _currentType = 'daily';
  List<dynamic> _currentReports = [];
  bool _isLoading = false;
  String? _selectedReportContent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadReports('daily');
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final types = ['daily', 'weekly', 'monthly'];
      final newType = types[_tabController.index];
      setState(() {
        _currentType = newType;
        _selectedReportContent = null; // 返回列表视图
      });
      _loadReports(newType);
    }
  }

  Future<void> _loadReports(String type) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final reports = await ApiService.getReportsList(type: type);
      setState(() {
        _currentReports = reports ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载报告列表失败: $e')),
      );
    }
  }

  Future<void> _loadReportContent(String filename) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final content = await ApiService.getReportContent(filename, type: _currentType);
      setState(() {
        _selectedReportContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载报告内容失败: $e')),
      );
    }
  }

  void _backToList() {
    setState(() {
      _selectedReportContent = null;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日报'),
            Tab(text: '周报'),
            Tab(text: '月报'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedReportContent != null
              ? _buildReportDetail()
              : _buildReportList(),
    );
  }

  Widget _buildReportList() {
    if (_currentReports.isEmpty) {
      return const Center(child: Text('暂无报告'));
    }
    return RefreshIndicator(
      onRefresh: () => _loadReports(_currentType),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentReports.length,
        itemBuilder: (ctx, index) {
          final report = _currentReports[index];
          final name = report['name'] ?? report['filename'] ?? '未知';
          final date = report['date'] ?? name.replaceAll('.md', '');
          final size = report['size'] ?? 0;
          final mtime = report['mtime'] != null
              ? DateTime.fromMillisecondsSinceEpoch((report['mtime'] * 1000).toInt())
              : null;
          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text(
                '${mtime != null ? _formatDate(mtime) : date}  |  ${_formatSize(size)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _loadReportContent(name),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportDetail() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade900,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToList,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '报告详情',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(_selectedReportContent ?? ''),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}