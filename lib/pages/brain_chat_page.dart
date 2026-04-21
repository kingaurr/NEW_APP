import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';
// ===== 新增：Drift 数据库相关导入（供后续扩展，不影响当前真实数据流） =====
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
// ===========================================================================

class BrainChatPage extends StatelessWidget {
  const BrainChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 从父级 Provider 获取 AppDatabase 实例（main.dart 中已注入）
    final db = Provider.of<AppDatabase>(context, listen: false);
    // 注意：ChatProvider 内部已从 Drift 本地数据库加载真实消息数据
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(db: db),  // 修正：传递 db 参数
      child: const _BrainChatView(),
    );
  }
}

class _BrainChatView extends StatefulWidget {
  const _BrainChatView();

  @override
  State<_BrainChatView> createState() => _BrainChatViewState();
}

class _BrainChatViewState extends State<_BrainChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _authenticate(String operationDesc) async {
    return await BiometricsHelper.authenticateForOperation(
      operation: 'brain_chat',
      operationDesc: operationDesc,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String value, ChatProvider provider) async {
    switch (value) {
      case 'code_fix':
        if (!await _authenticate('代码修复')) {
          _showSnackBar(context, '指纹验证失败');
          return;
        }
        final result = await ApiService.oneClickFix();
        _showSnackBar(context, result['message'] ?? '代码修复请求已提交');
        break;
      case 'strategy_generate':
        if (!await _authenticate('策略生成')) {
          _showSnackBar(context, '指纹验证失败');
          return;
        }
        final lastUserMsg = provider.messages.lastWhere(
          (m) => m.role == 'user',
          orElse: () => ChatMessage(role: 'user', content: ''),
        );
        if (lastUserMsg.content.isEmpty) {
          _showSnackBar(context, '请先输入策略描述');
          return;
        }
        final result = await ApiService.httpPost('/strategy/generate', body: {'description': lastUserMsg.content});
        _showSnackBar(context, result?['message'] ?? '策略生成请求已提交');
        break;
      case 'diagnosis':
        if (!await _authenticate('触发全面诊断')) {
          _showSnackBar(context, '指纹验证失败');
          return;
        }
        final success = await ApiService.triggerMiyazakiDiagnosis();
        _showSnackBar(context, success ? '诊断已触发，稍后查看报告' : '诊断触发失败');
        break;
      case 'export':
        final buffer = StringBuffer();
        for (final msg in provider.messages) {
          buffer.writeln('${msg.role == 'user' ? '用户' : '千寻'}: ${msg.content}');
          buffer.writeln('---');
        }
        _showSnackBar(context, '导出功能开发中');
        break;
      case 'clear':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('清空对话'),
            content: const Text('确定要清空所有对话历史吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
            ],
          ),
        );
        if (confirm == true) {
          provider.clearHistory();
        }
        break;
    }
  }

  Widget _buildThinkingCard(Map<String, dynamic>? steps) {
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.grey.shade900,
      child: ExpansionTile(
        leading: const Icon(Icons.psychology, color: Colors.blue),
        title: const Text('千寻思考中...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: const Text('金融师提案，探索者质证', style: TextStyle(fontSize: 12, color: Colors.grey)),
        children: [
          if (steps['financier'] != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.trending_up, size: 18, color: Colors.green),
              title: const Text('金融师提案', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['financier']['proposal'] ?? ''),
            ),
          if (steps['explorer'] != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.search, size: 18, color: Colors.orange),
              title: const Text('探索进化者质证', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['explorer']['critique'] ?? ''),
            ),
          if (steps['guardian'] != null)
            ListTile(
              dense: true,
              leading: Icon(
                steps['guardian']['verdict'] == '通过' ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: steps['guardian']['verdict'] == '通过' ? Colors.green : Colors.red,
              ),
              title: const Text('原则守护者裁决', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['guardian']['reason'] ?? ''),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser && message.thinkingSteps != null) _buildThinkingCard(message.thinkingSteps),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade700 : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(message.content, style: const TextStyle(fontSize: 15, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final messages = provider.messages;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('千寻大脑'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.bolt, color: Color(0xFFD4AF37)),
            onSelected: (value) => _handleMenuAction(context, value, provider),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'code_fix',
                child: ListTile(
                  leading: Icon(Icons.build, size: 20),
                  title: Text('代码修复'),
                  subtitle: Text('分析对话中的错误并生成补丁'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'strategy_generate',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome, size: 20),
                  title: Text('策略生成'),
                  subtitle: Text('基于对话逻辑生成量化策略'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'diagnosis',
                child: ListTile(
                  leading: Icon(Icons.health_and_safety, size: 20),
                  title: Text('触发全面诊断'),
                  subtitle: Text('手动执行宫崎骏系统诊断'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.file_download, size: 20), title: Text('导出对话'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'clear', child: ListTile(leading: Icon(Icons.delete_outline, size: 20), title: Text('清空对话'), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('千寻思考中...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), border: Border(top: BorderSide(color: Colors.grey.shade800))),
            child: Column(
              children: [
                Row(
                  children: [
                    FilterChip(
                      label: const Text('深度思考'),
                      selected: provider.deepThinking,
                      onSelected: (v) => provider.setDeepThinking(v),
                      avatar: Icon(Icons.psychology, size: 18, color: provider.deepThinking ? Colors.blue : Colors.grey),
                      backgroundColor: Colors.grey.shade900,
                      selectedColor: Colors.blue.shade900,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('联网思考'),
                      selected: provider.webSearch,
                      onSelected: (v) => provider.setWebSearch(v),
                      avatar: Icon(Icons.language, size: 18, color: provider.webSearch ? Colors.green : Colors.grey),
                      backgroundColor: Colors.grey.shade900,
                      selectedColor: Colors.green.shade900,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '输入你想问的问题...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          provider.sendMessage(text);
                          _controller.clear();
                          _scrollToBottom();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isLoading ? null : () {
                        provider.sendMessage(_controller.text);
                        _controller.clear();
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}