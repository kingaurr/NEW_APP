// lib/pages/brain_chat_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';

/// 千寻大脑对话页面
/// 功能：文字对话、语音输入、深度思考/联网思考开关、可折叠思考卡片、高级功能菜单
/// 聊天历史自动持久化，退出页面后重新进入可恢复
class BrainChatPage extends StatefulWidget {
  const BrainChatPage({super.key});

  @override
  State<BrainChatPage> createState() => _BrainChatPageState();
}

class _BrainChatPageState extends State<BrainChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _deepThinking = false;
  bool _webSearch = false;
  bool _isVoiceMode = false; // 预留语音模式状态

  // 持久化存储的键
  static const String _historyKey = 'qianxun_chat_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 从本地加载聊天历史
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages.clear();
          _messages.addAll(decoded.map((item) => ChatMessage.fromJson(item)));
        });
      } else {
        // 无历史记录时添加欢迎消息
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: '我是千寻，服务于千里千寻量化交易系统的本地轻量AI智能内核。有什么可以帮您？',
          ));
        });
      }
    } catch (e) {
      debugPrint('加载聊天历史失败: $e');
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: '我是千寻，服务于千里千寻量化交易系统的本地轻量AI智能内核。有什么可以帮您？',
        ));
      });
    }
  }

  /// 保存聊天历史到本地
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('保存聊天历史失败: $e');
    }
  }

  /// 滚动到底部
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

  /// 发送消息
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });
    _scrollToBottom();
    _controller.clear();
    await _saveHistory(); // 立即保存用户消息

    // 调用API
    final result = await ApiService.qianxunChat(
      messages: _messages
          .where((m) => m.role != 'system')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
      deepThinking: _deepThinking,
      webSearch: _webSearch,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: result.content,
          thinkingSteps: result.thinkingSteps,
        ));
      });
    } else {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: '抱歉，千寻大脑暂时无法回应：${result.error}',
        ));
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
    await _saveHistory(); // 保存AI回复
    _scrollToBottom();
  }

  /// 指纹验证
  Future<bool> _authenticate(String operation) async {
    final token = await BiometricsHelper.authenticateForOperation(operation);
    if (token != null) {
      ApiService.setFingerprintToken(token, 300);
      return true;
    }
    return false;
  }

  /// 处理右上角菜单操作
  Future<void> _handleMenuAction(String value) async {
    switch (value) {
      case 'code_fix':
        final auth = await _authenticate('代码修复');
        if (!auth) {
          _showSnackBar('指纹验证失败');
          return;
        }
        final result = await ApiService.oneClickFix();
        _showSnackBar(result['message'] ?? '代码修复请求已提交');
        break;
      case 'strategy_generate':
        final auth = await _authenticate('策略生成');
        if (!auth) {
          _showSnackBar('指纹验证失败');
          return;
        }
        // 获取最后一条用户消息作为策略描述
        final lastUserMsg = _messages.lastWhere(
          (m) => m.role == 'user',
          orElse: () => ChatMessage(role: 'user', content: ''),
        );
        if (lastUserMsg.content.isEmpty) {
          _showSnackBar('请先输入策略描述');
          return;
        }
        final result = await ApiService.httpPost('/strategy/generate',
            body: {'description': lastUserMsg.content});
        _showSnackBar(result?['message'] ?? '策略生成请求已提交');
        break;
      case 'diagnosis':
        final auth = await _authenticate('触发全面诊断');
        if (!auth) {
          _showSnackBar('指纹验证失败');
          return;
        }
        final result = await ApiService.triggerMiyazakiDiagnosis();
        _showSnackBar(result ? '诊断已触发，稍后查看报告' : '诊断触发失败');
        break;
      case 'export':
        // 导出对话记录
        final buffer = StringBuffer();
        for (final msg in _messages) {
          buffer.writeln('${msg.role == 'user' ? '用户' : '千寻'}: ${msg.content}');
          buffer.writeln('---');
        }
        // 实际导出需使用文件保存，此处简化处理
        _showSnackBar('导出功能开发中');
        break;
      case 'clear':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('清空对话'),
            content: const Text('确定要清空所有对话历史吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('清空'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          setState(() {
            _messages.clear();
            _messages.add(ChatMessage(
              role: 'assistant',
              content: '我是千寻，服务于千里千寻量化交易系统的本地轻量AI智能内核。有什么可以帮您？',
            ));
          });
          await _saveHistory(); // 清空后立即保存
        }
        break;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// 构建可折叠思考卡片
  Widget _buildThinkingCard(Map<String, dynamic>? steps) {
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.grey.shade900,
      child: ExpansionTile(
        leading: const Icon(Icons.psychology, color: Colors.blue),
        title: const Text(
          '千寻思考中...',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text(
          '金融师提案，探索者质证',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          if (steps['financier'] != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.trending_up, size: 18, color: Colors.green),
              title: const Text('金融师提案',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['financier']['proposal'] ?? ''),
            ),
          if (steps['explorer'] != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.search, size: 18, color: Colors.orange),
              title: const Text('探索进化者质证',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['explorer']['critique'] ?? ''),
            ),
          if (steps['guardian'] != null)
            ListTile(
              dense: true,
              leading: Icon(
                steps['guardian']['verdict'] == '通过'
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 18,
                color: steps['guardian']['verdict'] == '通过'
                    ? Colors.green
                    : Colors.red,
              ),
              title: const Text('原则守护者裁决',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(steps['guardian']['reason'] ?? ''),
            ),
        ],
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser && message.thinkingSteps != null)
              _buildThinkingCard(message.thinkingSteps),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade700 : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('千寻大脑'),
        centerTitle: true,
        actions: [
          // 右上角功能菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.bolt, color: Color(0xFFD4AF37)),
            onSelected: _handleMenuAction,
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
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download, size: 20),
                  title: Text('导出对话'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, size: 20),
                  title: Text('清空对话'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 对话历史区域
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('千寻思考中...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),
          // 底部输入区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Column(
              children: [
                // 深度思考 / 联网思考 开关
                Row(
                  children: [
                    FilterChip(
                      label: const Text('深度思考'),
                      selected: _deepThinking,
                      onSelected: (v) => setState(() => _deepThinking = v),
                      avatar: Icon(
                        Icons.psychology,
                        size: 18,
                        color: _deepThinking ? Colors.blue : Colors.grey,
                      ),
                      backgroundColor: Colors.grey.shade900,
                      selectedColor: Colors.blue.shade900,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('联网思考'),
                      selected: _webSearch,
                      onSelected: (v) => setState(() => _webSearch = v),
                      avatar: Icon(
                        Icons.language,
                        size: 18,
                        color: _webSearch ? Colors.green : Colors.grey,
                      ),
                      backgroundColor: Colors.grey.shade900,
                      selectedColor: Colors.green.shade900,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 输入框 + 发送按钮
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => _sendMessage(_controller.text),
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

/// 聊天消息模型（支持JSON序列化）
class ChatMessage {
  final String role; // 'user' 或 'assistant'
  final String content;
  final Map<String, dynamic>? thinkingSteps;

  ChatMessage({
    required this.role,
    required this.content,
    this.thinkingSteps,
  });

  // 从JSON反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      thinkingSteps: json['thinkingSteps'] as Map<String, dynamic>?,
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (thinkingSteps != null) 'thinkingSteps': thinkingSteps,
    };
  }
}