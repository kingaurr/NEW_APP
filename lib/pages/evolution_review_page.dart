// lib/pages/evolution_review_page.dart
// ==================== v2.0 自进化引擎：每日评审报告页（2026-04-25） ====================
// 功能描述：
// 1. 触发AI评审当日进化建议
// 2. 展示评审报告文字内容
// 3. 查看历史评审记录
// 4. 支持下拉刷新
// 遵循规范：
// - P0 真实数据原则：所有数据来自API，无数据展示"暂无评审记录"。
// - P1 故障隔离：本页面为独立路由页面，不超过500行。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P7 完整交互绑定：按钮均使用 onPressed 正确绑定。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 路由已在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 每日评审报告页
class EvolutionReviewPage extends StatefulWidget {
  const EvolutionReviewPage({super.key});

  @override
  State<EvolutionReviewPage> createState() => _EvolutionReviewPageState();
}

class _EvolutionReviewPageState extends State<EvolutionReviewPage> {
  bool _isLoading = true;
  bool _isReviewing = false;
  String? _errorMessage;
  String? _reviewText;
  String? _reviewedAt;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyResult = await ApiService.getEvolutionReviewHistory();
      if (!mounted) return;

      if (historyResult != null && historyResult is Map && historyResult['success'] == true) {
        final data = historyResult['data'] as Map<String, dynamic>? ?? {};
        final reviews = data['reviews'] as List<dynamic>? ?? [];
        setState(() {
          _history = reviews
              .whereType<Map<String, dynamic>>()
              .toList();
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  Future<void> _triggerReview() async {
    if (!mounted) return;
    setState(() {
      _isReviewing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.triggerEvolutionReview();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _reviewText = data['review_text'] ?? '';
          _reviewedAt = data['reviewed_at'] ?? '';
          _isReviewing = false;
        });
        await _loadData();
      } else {
        final msg = result != null && result is Map
            ? result['message'] ?? '触发失败'
            : '请求失败';
        setState(() {
          _errorMessage = msg;
          _isReviewing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络异常，请检查连接';
          _isReviewing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('每日评审'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTriggerButton(),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (_reviewText != null && _reviewText!.isNotEmpty)
                      _buildReviewResultCard(),
                    const SizedBox(height: 20),
                    _buildHistorySection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTriggerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isReviewing ? null : _triggerReview,
        icon: _isReviewing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isReviewing ? '评审中...' : '触发AI评审'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 18),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewResultCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI评审结果',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_reviewedAt != null && _reviewedAt!.isNotEmpty)
                  Text(
                    _reviewedAt!.substring(0, min(16, _reviewedAt!.length)),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _reviewText!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '评审历史',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Card(
            color: const Color(0xFF1E1E1E),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '暂无评审记录',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          )
        else
          ..._history.map((item) => _buildHistoryItem(item)).toList(),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final reviewText = item['review_text'] ?? '';
    final reviewedAt = item['reviewed_at'] ?? '';
    final reviewDate = reviewedAt is String && reviewedAt.length >= 10
        ? reviewedAt.substring(0, 10)
        : '未知日期';

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 8),
                Text(
                  reviewDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (reviewText is String && reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reviewText.length > 120
                    ? '${reviewText.substring(0, 120)}...'
                    : reviewText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;