// lib/pages/ipo_list_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

/// IPO提醒列表页面
class IpoListPage extends StatefulWidget {
  const IpoListPage({super.key});

  @override
  State<IpoListPage> createState() => _IpoListPageState();
}

class _IpoListPageState extends State<IpoListPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _ipoList = [];

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
      final result = await ApiService.getUpcomingIpo();
      if (result != null) {
        final upcoming = result['upcoming'] as List<dynamic>? ?? [];
        setState(() {
          _ipoList = upcoming;
        });
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
        title: const Text('IPO提醒'),
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
    if (_ipoList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.white38, size: 64),
            SizedBox(height: 16),
            Text(
              '暂无即将上市的IPO',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ipoList.length,
      itemBuilder: (context, index) {
        return _buildIpoCard(_ipoList[index]);
      },
    );
  }

  Widget _buildIpoCard(dynamic ipo) {
    final stockCode = ipo['stock_code'] as String? ?? '';
    final stockName = ipo['stock_name'] as String? ?? stockCode;
    final issuePrice = ipo['issue_price'] as num? ?? 0.0;
    final listingDate = ipo['listing_date'] as String? ?? '待定';
    final status = ipo['status'] as String? ?? 'pending';
    final analysis = ipo['analysis'] as Map<String, dynamic>? ?? {};
    final score = (analysis['score'] ?? 0).toDouble();
    final suggestion = analysis['suggestion'] as String? ?? '暂无建议';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = '已批准';
        break;
      case 'submitted':
        statusColor = Colors.orange;
        statusText = '已申报';
        break;
      case 'pending':
        statusColor = Colors.grey;
        statusText = '待上市';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    Color scoreColor;
    if (score >= 70) {
      scoreColor = Colors.green;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 跳转到IPO详情页
          Navigator.pushNamed(
            context,
            '/ipo_analysis_detail',
            arguments: {'stock_code': stockCode},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        stockName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stockCode,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '发行价',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${issuePrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '上市日期',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listingDate,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '量化评分: ',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        '${score.toStringAsFixed(1)}分',
                        style: TextStyle(color: scoreColor, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      suggestion,
                      style: TextStyle(color: scoreColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}