// lib/widgets/health_score_dashboard.dart
// ==================== 宫崎骏模块：健康评分仪表盘（2026-04-19 深色适配版） ====================
// 功能描述：
// 1. 环形进度条展示系统健康评分（0-100分）。
// 2. 评分根据数值变化颜色（绿≥80、黄60-79、橙40-59、红<40）。
// 3. 中央显示大号评分数字，下方显示状态一句话。
// 4. 支持点击触发刷新或跳转诊断详情。
// 5. 数据完全来自后端真实 API：/api/miyazaki/dashboard。
// 6. 包含加载状态、错误处理、空状态展示。
// 美学设计：
// - 对称居中布局，环形图与文字比例协调。
// - 柔和的阴影与圆角，提升卡片质感。
// - 留白充分，呼吸感强。
// 遵循规范：
// - P0 真实数据原则：无硬编码假数据。
// - P3 安全类型转换：使用 is 判断，禁用 as。
// - P5 生命周期检查：setState 前检查 mounted。
// =====================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';

/// 健康评分数据模型（安全解析）
class HealthScoreData {
  final int score;
  final String statusText;
  final int activeGroups;
  final int pendingAdvice;
  final String latestDiagnosis;

  HealthScoreData({
    required this.score,
    required this.statusText,
    required this.activeGroups,
    required this.pendingAdvice,
    required this.latestDiagnosis,
  });

  factory HealthScoreData.fromJson(Map<String, dynamic> json) {
    int parseScore(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int score = parseScore(json['health_score'] ?? json['score'] ?? 0);
    int activeGroups = json['active_groups'] is int ? json['active_groups'] : 0;
    int pendingAdvice = json['pending_advice'] is int ? json['pending_advice'] : 0;
    String latestDiagnosis = json['latest_diagnosis'] is String
        ? json['latest_diagnosis']
        : '暂无诊断报告';

    // 根据分数生成状态文本
    String statusText;
    if (score >= 80) {
      statusText = '系统运行良好';
    } else if (score >= 60) {
      statusText = '系统基本稳定';
    } else if (score >= 40) {
      statusText = '系统存在异常，建议关注';
    } else {
      statusText = '系统健康度低，请立即检查';
    }

    return HealthScoreData(
      score: score.clamp(0, 100),
      statusText: statusText,
      activeGroups: activeGroups,
      pendingAdvice: pendingAdvice,
      latestDiagnosis: latestDiagnosis,
    );
  }
}

/// 健康评分仪表盘组件
class HealthScoreDashboard extends StatefulWidget {
  final VoidCallback? onTap;

  const HealthScoreDashboard({super.key, this.onTap});

  @override
  State<HealthScoreDashboard> createState() => _HealthScoreDashboardState();
}

class _HealthScoreDashboardState extends State<HealthScoreDashboard> {
  HealthScoreData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await ApiService.fetchMiyazakiDashboard();
      if (result != null) {
        if (mounted) {
          setState(() {
            _data = HealthScoreData.fromJson(result);
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = '暂无数据';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败';
          _isLoading = false;
        });
      }
    }
  }

  /// 根据分数获取颜色
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // 绿色
    if (score >= 60) return const Color(0xFFFFC107); // 黄色
    if (score >= 40) return const Color(0xFFFF9800); // 橙色
    return const Color(0xFFF44336); // 红色
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.pushNamed(context, '/miyazaki/detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A), // 深色卡片背景
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchData();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final scoreColor = _getScoreColor(data.score);

    return Column(
      children: [
        // 环形进度条 + 中央评分
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _RingPainter(
                  progress: data.score / 100,
                  color: scoreColor,
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
                  strokeWidth: 10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.score}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const Text(
                    '健康分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 状态一句话
        Text(
          data.statusText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: scoreColor,
          ),
        ),
        const SizedBox(height: 8),
        // 最新诊断摘要
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850], // 深色背景
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notes_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.latestDiagnosis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 统计信息行：活跃事件组 / 待处理建议
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.warning_amber_outlined,
              label: '活跃事件',
              value: data.activeGroups,
              color: data.activeGroups > 0 ? Colors.orange : Colors.grey,
            ),
            Container(
              width: 1,
              height: 30,
              color: Colors.grey[700], // 深色分割线
            ),
            _buildStatItem(
              icon: Icons.assignment_outlined,
              label: '待处理建议',
              value: data.pendingAdvice,
              color: data.pendingAdvice > 0 ? Colors.blue : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 底部提示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '点击查看完整诊断',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 环形进度条绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // 从顶部开始
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// === 右心房健康上报（自动注入占位） ===
import 'dart:async';
import 'package:flutter/foundation.dart';

void _reportDashboardHealth() {
  if (kReleaseMode) {
    Future.microtask(() {
      // 预留右心房上报接口
    });
  }
}