import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api_service.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  static const String _boxName = 'qianxun_chat_box';
  static const String _messagesKey = 'qianxun_chat_history';

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _deepThinking = false;
  bool _webSearch = false;

  Box<String>? _chatBox;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get deepThinking => _deepThinking;
  bool get webSearch => _webSearch;

  ChatProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    // 注册适配器（需先执行 build_runner）
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    _chatBox = await Hive.openBox<String>(_boxName);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final String? historyJson = _chatBox?.get(_messagesKey);
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _messages = decoded.map((item) => ChatMessage.fromJson(item)).toList();
      } catch (e) {
        _addWelcomeMessage();
      }
    } else {
      _addWelcomeMessage();
    }
    notifyListeners();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      role: 'assistant',
      content: '我是千寻，服务于千里千寻量化交易系统的本地轻量AI智能内核。有什么可以帮您？',
    ));
  }

  Future<void> _saveHistory() async {
    final String historyJson = jsonEncode(
      _messages.map((msg) => msg.toJson()).toList(),
    );
    await _chatBox?.put(_messagesKey, historyJson);
  }

  void setDeepThinking(bool value) {
    _deepThinking = value;
    notifyListeners();
  }

  void setWebSearch(bool value) {
    _webSearch = value;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();
    _saveHistory(); // 异步保存，不等待

    final result = await ApiService.qianxunChat(
      messages: _messages
          .where((m) => m.role != 'system')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
      deepThinking: _deepThinking,
      webSearch: _webSearch,
    );

    String content;
    if (result.success) {
      content = result.content;
      if (content.trim().isEmpty) {
        content = '千寻已处理，但未返回有效内容，请稍后重试。';
      }
      _messages.add(ChatMessage(
        role: 'assistant',
        content: content,
        thinkingSteps: result.thinkingSteps,
      ));
    } else {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: '抱歉，千寻大脑暂时无法回应：${result.error}',
      ));
    }

    _isLoading = false;
    notifyListeners();
    _saveHistory();
  }

  Future<void> clearHistory() async {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
    await _saveHistory();
  }
}