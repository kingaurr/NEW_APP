// lib/widgets/shadow_summary_card.dart
// ==================== 宫崎骏模块：影子摘要卡片（2026-04-14） ====================
// 功能描述：
//   1. 在首页展示实盘与虚拟账户的总资产对比。
//   2. 显示差值及建议文案（实盘领先/影子领先/持平）。
//   3. 点击卡片跳转虚拟交易详情页。
//   4. 数据完全来自后端真实 API：/api/shadow/realtime_compare。
//   5. 包含加载状态、错误处理、空状态展示。
// 遵循规范：
//   - P0 真实数据原则：无硬编码假数据。
//   - P3 安全类型转换：使用 is 判断，禁用 as。
//   - P5 生命周期检查：setState 前检查 mounted。
//   - 命名规范：大驼峰类名，小写+下划线文件名。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';

/// 影子对比数据模型（安全解析）
class ShadowCompareData {
  final double shadowTotal;
  final double realTotal;
  final double diff;
  final double diffPct;
  final String conclusion;
  final String suggestion;

  ShadowCompareData({
    required this.shadowTotal,
    required this.realTotal,
    required this.diff,
    required this.diffPct,
    required this.conclusion,
    required this.suggestion,
  });

  /// 安全工厂方法：从 JSON 解析，缺失字段返回默认值
  factory ShadowCompareData.fromJson(Map<String, dynamic> json) {
    // 安全类型转换：使用 is 判断 + 默认值，绝不使用 as
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double shadowTotal = parseDouble(json['shadow_total']);
    double realTotal = parseDouble(json['real_total']);
    double diff = parseDouble(json['diff']);
    double diffPct = parseDouble(json['diff_pct'] ?? json['diff_pct']);

    String conclusion = json['conclusion'] is String
        ? json['conclusion'] as String
        : '持平';
    String suggestion = json['suggestion'] is String
        ? json['suggestion'] as String
        : '无需调整';

    return ShadowCompareData(
      shadowTotal: shadowTotal,
      realTotal: realTotal,
      diff: diff,
      diffPct: diffPct,
      conclusion: conclusion,
      suggestion: suggestion,
    );
  }
}

/// 影子摘要卡片组件
class ShadowSummaryCard extends StatefulWidget {
  final VoidCallback? onTap;

  const ShadowSummaryCard({Key? key, this.onTap}) : super(key: key);

  @override
  State<ShadowSummaryCard> createState() => _ShadowSummaryCardState();
}

class _ShadowSummaryCardState extends State<ShadowSummaryCard> {
  ShadowCompareData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await ApiService.fetchShadowRealtimeCompare();
      // 安全处理返回结果
      if (result != null) {
        if (mounted) {
          setState(() {
            _data = ShadowCompareData.fromJson(result);
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
          _errorMessage = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.pushNamed(context, '/virtual_trade');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A),                              // 深色卡片背景
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final bool isRealLeading = data.diff > 0;
    final bool isShadowLeading = data.diff < 0;
    final String diffText = data.diff > 0
        ? '+${data.diff.toStringAsFixed(2)}'
        : data.diff.toStringAsFixed(2);
    final Color diffColor = isRealLeading
        ? Colors.green
        : (isShadowLeading ? Colors.orange : Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            const Icon(Icons.compare_arrows, size: 20, color: Colors.lightBlueAccent),
            const SizedBox(width: 8),
            const Text(
              '实盘 vs 虚拟',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data.conclusion.contains('实盘')
                    ? Colors.green.withOpacity(0.2)
                    : (data.conclusion.contains('影子')
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                data.conclusion,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: data.conclusion.contains('实盘')
                      ? Colors.greenAccent
                      : (data.conclusion.contains('影子')
                          ? Colors.orangeAccent
                          : Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 实盘 vs 虚拟 对比
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAssetColumn('实盘', data.realTotal),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRealLeading ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: diffColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$diffText (${data.diffPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 13,                                 // 调小百分比字号
                      fontWeight: FontWeight.w600,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildAssetColumn('虚拟', data.shadowTotal),
          ],
        ),
        const SizedBox(height: 12),
        // 建议文案
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],                                // 深色建议背景
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.suggestion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 底部提示
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '点击查看详情',
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

  Widget _buildAssetColumn(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}