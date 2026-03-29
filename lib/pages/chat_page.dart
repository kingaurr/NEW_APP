// lib/pages/chat_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedMode = 'llm'; // 'llm' 或 'local'
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addSystemMessage('你好，我是千寻。你可以输入文字、语音提问，或上传文本文件（.txt, .log, .md）。点击右上角切换回答模式。');
  }

  void _addSystemMessage(String content) {
    _messages.add({
      'role': 'system',
      'content': content,
      'timestamp': DateTime.now(),
      'mode': 'system',
    });
    _scrollToBottom();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) => debugPrint('语音状态: $status'),
      onError: (error) => debugPrint('语音错误: $error'),
    );
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

  void _addMessage({
    required String role,
    required String content,
    String? mode,
  }) {
    setState(() {
      _messages.add({
        'role': role,
        'content': content,
        'timestamp': DateTime.now(),
        'mode': mode,
      });
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage({required String text, String? mode}) async {
    final sendMode = mode ?? _selectedMode;
    if (text.trim().isEmpty) return;

    // 添加用户消息
    _addMessage(role: 'user', content: text, mode: sendMode);

    // 清空输入框
    _inputController.clear();
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.voiceAsk(text, mode: sendMode);
      final answer = result?['answer'] ?? '抱歉，我没有理解您的问题。';
      _addMessage(role: 'assistant', content: answer, mode: sendMode);
    } catch (e) {
      _addMessage(role: 'assistant', content: '请求失败: $e', mode: sendMode);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (!available) {
      _addSystemMessage('语音识别不可用');
      return;
    }
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _sendMessage(text: result.recognizedWords);
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      localeId: 'zh_CN',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'log', 'md', 'pdf', 'docx'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final extension = fileName.split('.').last.toLowerCase();

    // 只处理文本文件，其他类型提示暂不支持
    if (extension == 'txt' || extension == 'log' || extension == 'md') {
      try {
        String content = await file.readAsString();
        // 限制内容长度，避免超过大模型上下文
        if (content.length > 10000) {
          content = content.substring(0, 10000) + '\n...(内容过长已截断)';
        }
        final userMessage = '【上传文件: $fileName】\n```\n$content\n```\n请分析以上文件内容并回答相关问题。';
        _sendMessage(text: userMessage);
      } catch (e) {
        _addSystemMessage('读取文件失败: $e');
      }
    } else {
      _addSystemMessage('暂不支持 $extension 格式文件，请上传 .txt, .log 或 .md 文件');
    }
  }

  void _toggleMode() {
    setState(() {
      _selectedMode = _selectedMode == 'llm' ? 'local' : 'llm';
    });
    _addSystemMessage('已切换到${_selectedMode == 'llm' ? '大模型' : '本地'}回答模式');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('千寻助手'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: Icon(
              _selectedMode == 'llm' ? Icons.auto_awesome : Icons.computer,
              color: const Color(0xFFD4AF37),
            ),
            onPressed: _toggleMode,
            tooltip: _selectedMode == 'llm' ? '当前: 大模型模式' : '当前: 本地模式',
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final isSystem = msg['role'] == 'system';
                final mode = msg['mode'];
                return _buildMessageBubble(
                  content: msg['content'],
                  isUser: isUser,
                  isSystem: isSystem,
                  mode: mode,
                  timestamp: msg['timestamp'],
                );
              },
            ),
          ),
          // 加载指示器
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          // 输入栏
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isUser,
    required bool isSystem,
    String? mode,
    DateTime? timestamp,
  }) {
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser
        ? const Color(0xFFD4AF37).withOpacity(0.2)
        : (isSystem ? Colors.grey.withOpacity(0.2) : const Color(0xFF2A2A2A));
    final textColor = isUser ? Colors.white : (isSystem ? Colors.white70 : Colors.white);

    Widget modeTag = const SizedBox.shrink();
    if (!isSystem && mode != null) {
      modeTag = Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: mode == 'llm' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          mode == 'llm' ? '大模型回答' : '本地回答',
          style: TextStyle(
            color: mode == 'llm' ? Colors.green : Colors.orange,
            fontSize: 10,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isUser && !isSystem) modeTag,
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              content,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                _formatTime(timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // 附件按钮
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFFD4AF37)),
            onPressed: _pickAndUploadFile,
          ),
          // 语音按钮
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: const Color(0xFFD4AF37)),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          // 文本输入框
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '输入问题...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(text: _inputController.text),
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD4AF37),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: () => _sendMessage(text: _inputController.text),
            ),
          ),
        ],
      ),
    );
  }
}