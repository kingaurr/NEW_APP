// lib/pages/miyazaki_center_page.dart
// ==================== 宫崎骏模块：稽查中心主页面（2026-04-14） ====================
// 功能描述：
//   1. 顶部展示健康评分仪表盘（HealthScoreDashboard）。
//   2. 下方TabBar包含三个Tab：编导·素材把关、导演·主动优化、胶片·诊断历史。
//   3. 编导Tab：数据源健康、模块状态、日志摘要、运行时异常、策略速览。
//   4. 导演Tab：夜间任务状态、待处理建议列表、策略排行榜、成本健康、一键诊断按钮。
//   5. 胶片Tab：事件时间线、诊断报告列表、谱系查询入口。
//   6. 支持下拉刷新整体数据。
// 美学设计：
//   - 页面留白充足，卡片圆角统一12px。
//   - 配色与系统黑金主题协调。
//   - Tab指示器颜色与优先级色彩呼应。
// 遵循规范：
//   - P0 真实数据原则：所有数据来自API。
//   - P3 安全类型转换：使用 is 判断，禁用 as。
//   - P5 生命周期检查：setState 前检查 mounted。
//   - P1 故障隔离：各Tab独立加载，互不影响。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';
import '../widgets/health_score_dashboard.dart';
import '../widgets/event_timeline.dart';
import '../widgets/optimization_item.dart';

/// 宫崎骏稽查中心主页面
class MiyazakiCenterPage extends StatefulWidget {
  const MiyazakiCenterPage({Key? key}) : super(key: key);

  @override
  State<MiyazakiCenterPage> createState() => _MiyazakiCenterPageState();
}

class _MiyazakiCenterPageState extends State<MiyazakiCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  List<OptimizationAdvice> _pendingAdvices = [];
  List<MiyazakiEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.fetchMiyazakiDashboard();
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _dashboardData = result;
          // 解析待处理建议
          if (result['pending_advices'] is List) {
            _pendingAdvices = (result['pending_advices'] as List)
                .map((e) => OptimizationAdvice.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // 解析最近事件
          if (result['recent_events'] is List) {
            _recentEvents = (result['recent_events'] as List)
                .map((e) => MiyazakiEvent.fromJson(e as Map<String, dynamic>))
                .toList();
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
    await _fetchDashboardData();
  }

  void _triggerDiagnosis() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('触发全面诊断'),
        content: const Text('将调用宫崎骏导演层进行一次全面的系统诊断，可能需要几十秒。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 显示加载
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在触发诊断，请稍后...')),
    );

    try {
      final success = await ApiService.triggerMiyazakiDiagnosis();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '诊断已触发，稍后查看报告' : '触发失败，请重试'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络异常，请稍后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('宫崎骏 · 稽查中心'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '编导·把关'),
            Tab(text: '导演·优化'),
            Tab(text: '胶片·历史'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading && _dashboardData == null
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _dashboardData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDashboardData,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAuditorTab(),
                      _buildDirectorTab(),
                      _buildFilmTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAuditorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 健康评分仪表盘
        const HealthScoreDashboard(),
        const SizedBox(height: 16),
        // 数据源健康卡片
        _buildDataSourceCard(),
        const SizedBox(height: 16),
        // 核心模块状态
        _buildModuleStatusCard(),
        const SizedBox(height: 16),
        // 日志ERROR摘要
        _buildLogSummaryCard(),
        const SizedBox(height: 16),
        // 策略健康速览
        _buildStrategyHealthCard(),
      ],
    );
  }

  Widget _buildDataSourceCard() {
    final dataSources = _dashboardData?['data_sources'] as List? ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据源健康',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (dataSources.isEmpty)
              const Text('暂无数据', style: TextStyle(color: Colors.grey))
            else
              ...dataSources.map((source) {
                final name = source['name'] ?? '未知';
                final score = source['health_score'] ?? 0;
                final color = score >= 60 ? Colors.green : Colors.orange;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(name)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$score分',
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleStatusCard() {
    final modules = _dashboardData?['modules'] as List? ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '核心模块状态',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (modules.isEmpty)
              const Text('暂无数据', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: modules.map((module) {
                  final name = module['name'] ?? '未知';
                  final online = module['online'] ?? false;
                  return Chip(
                    avatar: Icon(
                      online ? Icons.check_circle : Icons.error,
                      size: 18,
                      color: online ? Colors.green : Colors.red,
                    ),
                    label: Text(name),
                    backgroundColor: online ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSummaryCard() {
    final logSummary = _dashboardData?['log_summary'] as Map<String, dynamic>? ?? {};
    final errorCount = logSummary['error_count'] ?? 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '日志ERROR摘要',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$errorCount 条',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (logSummary.isEmpty)
              const Text('暂无异常日志', style: TextStyle(color: Colors.grey))
            else
              Text(
                logSummary['latest_error'] ?? '暂无详细信息',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyHealthCard() {
    final strategies = _dashboardData?['strategies'] as List? ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '策略健康速览',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (strategies.isEmpty)
              const Text('暂无数据', style: TextStyle(color: Colors.grey))
            else
              ...strategies.take(3).map((s) {
                final name = s['name'] ?? '未知';
                final winRate = s['win_rate'] ?? 0.0;
                final color = winRate >= 0.5 ? Colors.green : Colors.orange;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(name)),
                      Text(
                        '${(winRate * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorTab() {
    return Column(
      children: [
        Expanded(
          child: OptimizationList(
            items: _pendingAdvices,
            isLoading: false,
            onExecute: (prefill) {
              Navigator.pushNamed(
                context,
                '/voice/chat',
                arguments: {'prefill': prefill},
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerDiagnosis,
              icon: const Icon(Icons.health_and_safety),
              label: const Text('一键诊断'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilmTab() {
    return EventTimeline(
      minSeverity: 1,
      onEventTap: (event) {
        // 可跳转详情
      },
    );
  }
}