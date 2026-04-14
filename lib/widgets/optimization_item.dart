// lib/widgets/optimization_item.dart
// ==================== 宫崎骏模块：优化建议卡片组件（2026-04-14） ====================
// 功能描述：
//   1. 展示单条优化建议，包含优先级、标题、摘要描述、建议详情。
//   2. 优先级标签配色（P0深红、P1橙色、P2蓝色），语义清晰。
//   3. 卡片底部提供“查看详情”和“执行此建议”两个操作按钮。
//   4. 点击“执行此建议”跳转千寻对话页面，并预填充指令文本。
//   5. 支持展开/收起详情（可选）。
// 美学设计：
//   - 卡片圆角12px，柔和阴影，内边距16px。
//   - 优先级标签圆角胶囊设计，与左侧彩色条带呼应。
//   - 按钮区对称分布，留白充足。
// 遵循规范：
//   - P0 真实数据原则：所有数据来自 API。
//   - P3 安全类型转换：使用 is 判断，禁用 as。
//   - P6 路由参数解耦：预填充通过 arguments 安全传递。
//   - B5 路由注册：千寻对话页已在 main.dart 中注册。
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 优化建议数据模型（安全解析）
class OptimizationAdvice {
  final String id;
  final String title;
  final String priority; // P0 / P1 / P2
  final String summary;
  final String recommendation;
  final String? strategyId;
  final Map<String, dynamic> rawData;

  OptimizationAdvice({
    required this.id,
    required this.title,
    required this.priority,
    required this.summary,
    required this.recommendation,
    this.strategyId,
    required this.rawData,
  });

  factory OptimizationAdvice.fromJson(Map<String, dynamic> json) {
    String id = json['id'] is String ? json['id'] : '';
    String title = json['title'] is String ? json['title'] : '优化建议';
    String priority = json['priority'] is String ? json['priority'] : 'P2';
    String summary = json['summary'] is String
        ? json['summary']
        : (json['description'] is String ? json['description'] : '暂无摘要');
    String recommendation = json['recommendation'] is String
        ? json['recommendation']
        : (json['content'] is String ? json['content'] : '暂无具体建议');
    String? strategyId = json['strategy_id'] is String
        ? json['strategy_id']
        : null;

    return OptimizationAdvice(
      id: id,
      title: title,
      priority: priority,
      summary: summary,
      recommendation: recommendation,
      strategyId: strategyId,
      rawData: json,
    );
  }

  /// 获取优先级对应的颜色
  Color get priorityColor {
    switch (priority) {
      case 'P0':
        return const Color(0xFFD32F2F);
      case 'P1':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2196F3);
    }
  }

  /// 获取优先级标签文本
  String get priorityLabel {
    switch (priority) {
      case 'P0':
        return '紧急';
      case 'P1':
        return '重要';
      default:
        return '建议';
    }
  }

  /// 生成预填充指令文本（用于跳转千寻）
  String buildPrefillCommand() {
    final buffer = StringBuffer();
    buffer.write('关于“$title”的诊断建议：$recommendation');
    if (strategyId != null && strategyId!.isNotEmpty) {
      buffer.write('（策略ID：$strategyId）');
    }
    buffer.write('。请帮我执行此调整。');
    return buffer.toString();
  }
}

/// 优化建议卡片组件
class OptimizationItem extends StatelessWidget {
  final OptimizationAdvice advice;
  final VoidCallback? onViewDetail;
  final Function(String prefillCommand)? onExecute;

  const OptimizationItem({
    Key? key,
    required this.advice,
    this.onViewDetail,
    this.onExecute,
  }) : super(key: key);

  void _handleExecute(BuildContext context) {
    HapticFeedback.mediumImpact();
    final prefill = advice.buildPrefillCommand();
    if (onExecute != null) {
      onExecute!(prefill);
    } else {
      // 默认跳转千寻对话页，传递预填充文本
      Navigator.pushNamed(
        context,
        '/voice/chat',
        arguments: {'prefill': prefill},
      );
    }
  }

  void _handleViewDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onViewDetail != null) {
      onViewDetail!();
    } else {
      // 默认跳转诊断详情页
      Navigator.pushNamed(
        context,
        '/miyazaki/detail',
        arguments: {'advice_id': advice.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: advice.priorityColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行 + 优先级标签
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      advice.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: advice.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      advice.priorityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: advice.priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 摘要描述
              Text(
                advice.summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 建议详情（可折叠，此处简化展示）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        advice.recommendation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 操作按钮区
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleViewDetail(context),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('查看详情'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _handleExecute(context),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('执行此建议'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: advice.priorityColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 1,
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

/// 优化建议列表组件（带加载状态、空状态）
class OptimizationList extends StatelessWidget {
  final List<OptimizationAdvice> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(String)? onExecute;

  const OptimizationList({
    Key? key,
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onExecute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无待处理建议',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '系统运行良好，无需优化',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return OptimizationItem(
          advice: items[index],
          onExecute: onExecute,
        );
      },
    );
  }
}