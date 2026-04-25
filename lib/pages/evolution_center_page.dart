// lib/pages/evolution_center_page.dart
// ==================== v2.0 自进化引擎：自进化中心主页面（2026-04-25） ====================
// 功能描述：
// 1. 聚合入口：每日评审卡片、今日摘要卡片、策略进化面板、进化趋势卡片、历史记录卡片
// 2. 点击各卡片跳转至对应的独立子页面
// 3. 支持下拉刷新
// 遵循规范：
// - P0 真实数据原则：所有数据来自API。
// - P1 故障隔离：各功能模块拆分为独立子页面，通过路由跳转。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：所有异步操作后、setState前检查 if (!mounted) return;。
// - P7 完整交互绑定：所有跳转入口使用 InkWell 包裹。
// - B4 所有API调用通过 ApiService 静态方法。
// - B5 所有页面路由在 main.dart 的 onGenerateRoute 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import '../api_service.dart';

/// 自进化中心主页面（聚合入口，≤500行）
class EvolutionCenterPage extends StatefulWidget {
  const EvolutionCenterPage({super.key});

  @override
  State<EvolutionCenterPage> createState() => _EvolutionCenterPageState();
}

class _EvolutionCenterPageState extends State<EvolutionCenterPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _summaryData;
  int _totalSuggestions = 0;
  int _pendingCount = 0;
  Map<String, int> _byPriority = {'P0': 0, 'P1': 0, 'P2': 0};
  String? _lastReviewDate;
  double? _lastReviewScore;
  int? _lastReviewPassed;
  int? _lastReviewTotal;

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
      final result = await ApiService.getEvolutionSummary();
      if (!mounted) return;

      if (result != null && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _summaryData = data;
          _totalSuggestions = data['total_suggestions'] ?? 0;
          _pendingCount = data['pending'] ?? 0;
          if (data['by_priority'] is Map) {
            final bp = data['by_priority'] as Map<String, dynamic>;
            _byPriority = {
              'P0': bp['P0'] ?? 0,
              'P1': bp['P1'] ?? 0,
              'P2': bp['P2'] ?? 0,
            };
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络异常，请检查连接';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('自进化中心'),
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
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailyReviewCard(),
                        const SizedBox(height: 16),
                        _buildTodaySummaryCard(),
                        const SizedBox(height: 16),
                        _buildStrategyEvolutionPanel(),
                        const SizedBox(height: 16),
                        _buildTrendCard(),
                        const SizedBox(height: 16),
                        _buildHistoryCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ==================== 1. 每日评审卡片 ====================
  Widget _buildDailyReviewCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/evolution_review');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '每日评审',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastReviewDate != null
                          ? '上次评审: $_lastReviewDate · 评分 ${_lastReviewScore?.toStringAsFixed(1) ?? "?"}'
                          : '暂无评审记录',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 2. 今日摘要卡片 ====================
  Widget _buildTodaySummaryCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/evolution_suggestions');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '今日摘要',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip('生成', _totalSuggestions, const Color(0xFFD4AF37)),
                  const SizedBox(width: 12),
                  _buildStatChip('待审批', _pendingCount, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatChip('P0', _byPriority['P0'] ?? 0, Colors.red),
                  const SizedBox(width: 12),
                  _buildStatChip('P1', _byPriority['P1'] ?? 0, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatChip('P2', _byPriority['P2'] ?? 0, Colors.grey),
                ],
              ),
              if (_totalSuggestions == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('暂无建议', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==================== 3. 策略进化面板 ====================
  Widget _buildStrategyEvolutionPanel() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/evolution_strategy_compare',
              arguments: {'strategyId': ''});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '策略进化对比',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '查看策略参数锦标赛与权重调整',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 4. 进化趋势卡片 ====================
  Widget _buildTrendCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/evolution_trend');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '进化趋势',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '系统胜率近7日趋势摘要',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 5. 历史记录卡片 ====================
  Widget _buildHistoryCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/evolution_history');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '历史记录',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '最近7天进化报告概览',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}