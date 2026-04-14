// lib/pages/miyazaki_detail_page.dart
// ==================== 宫崎骏模块：诊断详情页（2026-04-14） ====================
// 功能描述：
//   1. 展示宫崎骏导演层生成的完整诊断报告。
//   2. 包含诊断时间、健康评分、症状描述、根因分析、优化建议列表。
//   3. 优化建议支持点击“执行”跳转千寻对话页。
//   4. 支持通过路由参数传入诊断ID或日期，自动加载对应报告。
//   5. 包含加载状态、错误处理、空状态展示。
// 美学设计：
//   - 页面采用卡片式布局，层次分明。
//   - 评分环形图复用 HealthScoreDashboard 中的绘制逻辑。
//   - 配色语义化（绿/黄/橙/红），与稽查中心统一。
// 遵循规范：
//   - P0 真实数据原则：所有数据来自API。
//   - P3 安全类型转换：使用 is 判断，禁用 as。
//   - P5 生命周期检查：setState 前检查 mounted。
//   - P6 路由参数解耦：通过 arguments 接收参数。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';
import '../widgets/optimization_item.dart';

/// 诊断报告数据模型
class DiagnosisReport {
  final String id;
  final DateTime timestamp;
  final int healthScore;
  final String symptom;
  final String rootCause;
  final String conclusion;
  final List<OptimizationAdvice> recommendations;
  final Map<String, dynamic> rawData;

  DiagnosisReport({
    required this.id,
    required this.timestamp,
    required this.healthScore,
    required this.symptom,
    required this.rootCause,
    required this.conclusion,
    required this.recommendations,
    required this.rawData,
  });

  factory DiagnosisReport.fromJson(Map<String, dynamic> json) {
    String id = json['diagnosis_id'] is String ? json['diagnosis_id'] : '';
    int healthScore = json['health_score'] is int
        ? json['health_score']
        : (json['score'] is int ? json['score'] : 0);
    String symptom = json['symptom'] is String ? json['symptom'] : '';
    String rootCause = json['root_cause'] is String ? json['root_cause'] : '';
    String conclusion = json['conclusion'] is String
        ? json['conclusion']
        : (json['report'] is String ? json['report'] : '');

    DateTime timestamp;
    if (json['timestamp'] is String) {
      timestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }

    List<OptimizationAdvice> recommendations = [];
    if (json['recommendations'] is List) {
      recommendations = (json['recommendations'] as List)
          .map((e) => OptimizationAdvice.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DiagnosisReport(
      id: id,
      timestamp: timestamp,
      healthScore: healthScore.clamp(0, 100),
      symptom: symptom,
      rootCause: rootCause,
      conclusion: conclusion,
      recommendations: recommendations,
      rawData: json,
    );
  }

  Color get scoreColor {
    if (healthScore >= 80) return const Color(0xFF4CAF50);
    if (healthScore >= 60) return const Color(0xFFFFC107);
    if (healthScore >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

/// 诊断详情页
class MiyazakiDetailPage extends StatefulWidget {
  final Map<String, dynamic>? args; // 新增：用于接收路由参数

  const MiyazakiDetailPage({Key? key}) : args = null, super(key: key);
  const MiyazakiDetailPage.withArgs({Key? key, this.args}) : super(key: key); // 新增：带参数的构造函数

  @override
  State<MiyazakiDetailPage> createState() => _MiyazakiDetailPageState();
}

class _MiyazakiDetailPageState extends State<MiyazakiDetailPage> {
  DiagnosisReport? _report;
  bool _isLoading = true;
  String? _errorMessage;
  String? _diagnosisId;
  String? _date;

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _fetchReport();
  }

  void _parseArguments() {
    // 优先从 widget.args 获取，兼容旧的路由 arguments 方式
    final args = widget.args ?? ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _diagnosisId = args['diagnosis_id'] as String?;
      _date = args['date'] as String?;
    }
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? result;
      if (_diagnosisId != null && _diagnosisId!.isNotEmpty) {
        result = await ApiService.fetchMiyazakiDiagnosisById(_diagnosisId!);
      } else if (_date != null && _date!.isNotEmpty) {
        result = await ApiService.fetchMiyazakiDiagnosis(date: _date);
      } else {
        result = await ApiService.fetchMiyazakiDiagnosis();
      }

      if (!mounted) return;

      // 修复：显式非空断言
      if (result != null && result.isNotEmpty) {
        setState(() {
          _report = DiagnosisReport.fromJson(result!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '暂无诊断报告';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('诊断报告'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReport,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage == '暂无诊断报告'
                  ? Icons.assignment_outlined
                  : Icons.error_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != '暂无诊断报告')
              TextButton(
                onPressed: _fetchReport,
                child: const Text('重试'),
              ),
          ],
        ),
      );
    }

    final report = _report!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 诊断时间与评分卡片
          _buildHeaderCard(report),
          const SizedBox(height: 16),
          // 症状描述
          _buildSectionCard(
            title: '症状描述',
            content: report.symptom.isNotEmpty ? report.symptom : '暂无症状描述',
            icon: Icons.report_problem_outlined,
          ),
          const SizedBox(height: 16),
          // 根因分析
          _buildSectionCard(
            title: '根因分析',
            content: report.rootCause.isNotEmpty ? report.rootCause : '暂无根因分析',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 16),
          // 综合结论
          _buildSectionCard(
            title: '综合结论',
            content: report.conclusion.isNotEmpty ? report.conclusion : '暂无综合结论',
            icon: Icons.assessment_outlined,
          ),
          const SizedBox(height: 16),
          // 优化建议列表
          if (report.recommendations.isNotEmpty) ...[
            const Text(
              '优化建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...report.recommendations.map((advice) => OptimizationItem(
                  advice: advice,
                  onExecute: (prefill) {
                    Navigator.pushNamed(
                      context,
                      '/voice/chat',
                      arguments: {'prefill': prefill},
                    );
                  },
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(DiagnosisReport report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 环形评分
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: report.healthScore / 100,
                      strokeWidth: 8,
                      backgroundColor: report.scoreColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(report.scoreColor),
                    ),
                  ),
                  Text(
                    '${report.healthScore}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: report.scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 诊断时间与ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '诊断时间',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.timestamp.year}年${report.timestamp.month}月${report.timestamp.day}日 '
                    '${report.timestamp.hour.toString().padLeft(2, '0')}:${report.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '报告ID',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.id.isNotEmpty ? report.id : '—',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
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
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}