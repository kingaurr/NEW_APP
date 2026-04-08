// lib/pages/log_analysis_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

class LogAnalysisPage extends StatefulWidget {
  const LogAnalysisPage({super.key});

  @override
  State<LogAnalysisPage> createState() => _LogAnalysisPageState();
}

class _LogAnalysisPageState extends State<LogAnalysisPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _logs = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = 20;

  String? _selectedModule;
  String? _selectedLevel;
  String _keyword = '';
  int _days = 7;

  final List<String> _modules = ['系统', '交易', '外脑', '语音', 'API', '数据源'];
  final List<String> _levels = ['INFO', 'WARNING', 'ERROR'];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool reset = true}) async {
    if (_isLoading) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    if (reset) {
      _page = 1;
      _logs.clear();
    }
    try {
      final result = await ApiService.searchLogs(
        module: _selectedModule,
        level: _selectedLevel,
        keyword: _keyword.isEmpty ? null : _keyword,
        days: _days,
        page: _page,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          final newLogs = result['logs'] as List? ?? [];
          if (reset) {
            _logs = List<Map<String, dynamic>>.from(newLogs);
          } else {
            _logs.addAll(List<Map<String, dynamic>>.from(newLogs));
          }
          _total = result['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日志失败: $e')),
        );
      }
    }
  }

  void _loadMore() {
    if (_isLoading) return;
    if (_logs.length >= _total) return;
    _page++;
    _loadLogs(reset: false);
  }

  Future<void> _exportLogs() async {
    try {
      final result = await ApiService.exportLogs(
        module: _selectedModule,
        level: _selectedLevel,
        keyword: _keyword.isEmpty ? null : _keyword,
        days: _days,
      );
      if (mounted) {
        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志导出成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败: ${result?['error'] ?? '未知错误'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出异常: $e')),
        );
      }
    }
  }

  Future<void> _uploadLogs() async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
      }
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final uploadResult = await ApiService.uploadLogs(result.files.single.path!);
        if (mounted) {
          if (uploadResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('日志上传成功，开发者将收到通知')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('上传失败: ${uploadResult['error'] ?? '未知错误'}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传异常: $e')),
        );
      }
    }
  }

  Future<void> _aiDiagnose(String logContent) async {
    final authenticated = await BiometricsHelper.authenticateAndGetToken();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指纹验证失败，操作取消')),
        );
      }
      return;
    }
    final result = await ApiService.voiceAsk('分析以下日志并给出修复建议：\n$logContent');
    if (mounted) {
      if (result != null && result['answer'] != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('千寻诊断结果', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Text(result['answer'], style: const TextStyle(color: Colors.white70)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('诊断失败，请稍后重试'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 新增：查看日志详情
  void _showLogDetail(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? '';
    final level = log['level'] ?? '';
    final module = log['module'] ?? '';
    final content = log['content'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('日志详情', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间: $timestamp', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('级别: $level', style: TextStyle(color: _getLevelColor(level))),
            const SizedBox(height: 8),
            Text('模块: $module', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('内容:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _aiDiagnose(content);
            },
            icon: const Icon(Icons.psychology, size: 16),
            label: const Text('千寻诊断'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('筛选条件', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedModule,
              hint: const Text('模块', style: TextStyle(color: Colors.grey)),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: [const DropdownMenuItem(value: null, child: Text('全部')), ..._modules.map((e) => DropdownMenuItem(value: e, child: Text(e)))],
              onChanged: (v) => setState(() => _selectedModule = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              hint: const Text('级别', style: TextStyle(color: Colors.grey)),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: [const DropdownMenuItem(value: null, child: Text('全部')), ..._levels.map((e) => DropdownMenuItem(value: e, child: Text(e)))],
              onChanged: (v) => setState(() => _selectedLevel = v),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: '关键词', labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _keyword = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('时间范围:', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _days.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_days 天',
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (v) => setState(() => _days = v.toInt()),
                  ),
                ),
                Text('$_days 天', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadLogs();
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志分析'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _uploadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '搜索关键词',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) {
                      setState(() => _keyword = v);
                      _loadLogs();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _loadLogs(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length + 1,
                        itemBuilder: (ctx, index) {
                          if (index == _logs.length) {
                            if (_logs.length >= _total) return const SizedBox.shrink();
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final log = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            color: const Color(0xFF2A2A2A),
                            child: ListTile(
                              onTap: () => _showLogDetail(log), // 新增：点击查看详情
                              title: Text(
                                '${log['timestamp']} [${log['level']}] ${log['module']}',
                                style: TextStyle(
                                  color: _getLevelColor(log['level']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                log['content'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.psychology, color: Color(0xFFD4AF37)),
                                onPressed: () => _aiDiagnose(log['content'] ?? ''),
                                tooltip: '千寻诊断',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }
}