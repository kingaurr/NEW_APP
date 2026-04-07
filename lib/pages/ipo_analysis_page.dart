// lib/pages/ipo_analysis_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'ipo_analysis_detail_page.dart';

class IpoAnalysisPage extends StatefulWidget {
  const IpoAnalysisPage({super.key});

  @override
  State<IpoAnalysisPage> createState() => _IpoAnalysisPageState();
}

class _IpoAnalysisPageState extends State<IpoAnalysisPage> {
  bool _isLoading = true;
  List<dynamic> _ipos = [];
  String _error = '';
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoading) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      if (mounted) setState(() => _ipos.clear());
    }
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await ApiService.getUpcomingIpo(page: _page, pageSize: _pageSize);
      if (mounted) {
        final List<dynamic> newList = result['list'] ?? [];
        if (refresh || _page == 1) {
          _ipos = newList;
        } else {
          _ipos.addAll(newList);
        }
        _hasMore = newList.length >= _pageSize;
        setState(() {});
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      _page++;
      await _loadData();
    }
  }

  Future<void> _refresh() async {
    _error = '';
    await _loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新股分析'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading && _ipos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty && _ipos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _ipos.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index == _ipos.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final ipo = _ipos[index];
                      return Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.trending_up, color: Color(0xFFD4AF37)),
                          title: Text(
                            ipo['stock_name'] ?? ipo['stock_code'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${ipo['status'] ?? ''}  ${ipo['date'] ?? ''}  评分: ${ipo['overall_score'] ?? '-'}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IpoAnalysisDetailPage(stockCode: ipo['stock_code']),
                              ),
                            ).then((_) => _refresh());
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}