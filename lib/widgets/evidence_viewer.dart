// lib/widgets/evidence_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // 添加此导入以使用 Clipboard
import 'dart:convert';

/// 证据查看器组件
/// 用于展示指令执行的证据链，支持展开/折叠、复制等功能
class EvidenceViewer extends StatefulWidget {
  final Map<String, dynamic> evidence;
  final bool initiallyExpanded;

  const EvidenceViewer({
    super.key,
    required this.evidence,
    this.initiallyExpanded = false,
  });

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<EvidenceViewer> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value ? '✅ 是' : '❌ 否';
    if (value is double) return value.toStringAsFixed(4);
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  Widget _buildEvidenceItem(String key, dynamic value, {bool isNested = false}) {
    final formattedValue = _formatValue(value);

    return Padding(
      padding: EdgeInsets.only(left: isNested ? 16 : 0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isNested ? 100 : 120,
            child: Text(
              key,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              formattedValue,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
            onPressed: () => _copyToClipboard(formattedValue),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(List<dynamic> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '执行步骤',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value as Map<String, dynamic>;
          final status = step['status'];
          final statusColor = status == 'success'
              ? Colors.green
              : (status == 'failed' ? Colors.red : Colors.orange);

          return Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            status == 'success'
                                ? Icons.check
                                : (status == 'failed' ? Icons.close : Icons.hourglass_empty),
                            size: 14,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '步骤 ${index + 1}: ${step['type'] ?? '未知'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        status ?? 'pending',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (step['result'] != null) ...[
                    const SizedBox(height: 8),
                    _buildEvidenceItem('结果', step['result'], isNested: true),
                  ],
                  if (step['verification'] != null) ...[
                    const SizedBox(height: 4),
                    _buildEvidenceItem('验证', step['verification']['message'] ?? '通过', isNested: true),
                  ],
                  if (step['error'] != null) ...[
                    const SizedBox(height: 4),
                    _buildEvidenceItem('错误', step['error'], isNested: true),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFileEvidence(Map<String, dynamic> files) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            '文件证据',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...files.entries.map((entry) {
          final fileInfo = entry.value;
          return Card(
            color: const Color(0xFF2A2A2A),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFFD4AF37)),
              title: Text(
                entry.key,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                '大小: ${fileInfo['size'] ?? 0} 字节 | 哈希: ${(fileInfo['hash'] ?? '').substring(0, 8)}...',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                onPressed: () => _copyToClipboard(entry.key),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: Row(
            children: [
              const Icon(Icons.receipt, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              const Text(
                '执行证据',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.evidence['status'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.evidence['status'] == 'success'
                        ? Colors.green.withOpacity(0.2)
                        : (widget.evidence['status'] == 'failed'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.evidence['status'] == 'success'
                        ? '成功'
                        : (widget.evidence['status'] == 'failed' ? '失败' : '进行中'),
                    style: TextStyle(
                      color: widget.evidence['status'] == 'success'
                          ? Colors.green
                          : (widget.evidence['status'] == 'failed' ? Colors.red : Colors.orange),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息
                  _buildEvidenceItem('事务ID', widget.evidence['transaction_id']),
                  _buildEvidenceItem('指令', widget.evidence['command']),
                  _buildEvidenceItem('时间', widget.evidence['timestamp']),

                  // 步骤详情
                  if (widget.evidence['steps'] != null && widget.evidence['steps'].isNotEmpty)
                    _buildStepsSection(widget.evidence['steps']),

                  // 文件证据
                  if (widget.evidence['files'] != null)
                    _buildFileEvidence(widget.evidence['files']),

                  // 复制全部按钮
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => _copyToClipboard(jsonEncode(widget.evidence)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                        side: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      child: const Text('复制全部证据'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}