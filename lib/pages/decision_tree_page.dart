// lib/pages/decision_tree_page.dart
import 'package:flutter/material.dart';

/// 决策树独立页面
/// 用于全屏展示策略的决策树，通过路由跳转访问，实现故障隔离
class DecisionTreePage extends StatelessWidget {
  final Map<String, dynamic> decisionTree;
  final String strategyName;

  const DecisionTreePage({
    super.key,
    required this.decisionTree,
    required this.strategyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('$strategyName - 决策树'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: decisionTree.isEmpty
          ? const Center(
              child: Text(
                '暂无决策树数据',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDecisionTreeNode(decisionTree, 0),
            ),
    );
  }

  /// 递归构建决策树节点，带深度限制保护
  Widget _buildDecisionTreeNode(Map<String, dynamic> node, int depth) {
    // 深度保护：最多递归10层，防止无限递归
    const maxDepth = 10;
    if (depth >= maxDepth) {
      return const SizedBox.shrink();
    }

    // 安全获取children字段
    final childrenData = node['children'];
    List<dynamic> children = [];
    if (childrenData is List) {
      children = childrenData;
    }

    final indent = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: node['is_critical_path'] == true
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: node['is_critical_path'] == true
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getNodeIcon(node['type']),
                      size: 16,
                      color: node['type'] == 'condition' &&
                              node['metadata']?['result'] == true
                          ? Colors.green
                          : (node['type'] == 'condition'
                              ? Colors.red
                              : Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node['name'] ?? '',
                        style: TextStyle(
                          color: node['is_critical_path'] == true
                              ? Colors.orange
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: node['is_critical_path'] == true
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                if (node['explanation'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      node['explanation'],
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          // 递归构建子节点
          ...children.map((child) {
            if (child is Map<String, dynamic>) {
              return _buildDecisionTreeNode(child, depth + 1);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// 根据节点类型返回对应图标
  IconData _getNodeIcon(dynamic type) {
    final typeStr = type?.toString() ?? '';
    switch (typeStr) {
      case 'decision':
        return Icons.play_arrow;
      case 'condition':
        return Icons.rule;
      case 'result':
        return Icons.check_circle;
      case 'data':
        return Icons.data_usage;
      default:
        return Icons.circle;
    }
  }
}