// lib/providers/chat_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api_service.dart';
import '../models/chat_message.dart';
// ===== 新增：Drift 数据库相关导入 =====
import 'package:drift/drift.dart' as drift;
import '../database/database.dart' as db;
// ======================================

class ChatProvider extends ChangeNotifier {
  static const String _boxName = 'qianxun_chat_box';
  static const String _messagesKey = 'qianxun_chat_history';

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _deepThinking = false;
  bool _webSearch = false;

  Box<String>? _chatBox;

  // ===== 新增：数据库实例 =====
  final db.AppDatabase _db;
  // ===========================

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get deepThinking => _deepThinking;
  bool get webSearch => _webSearch;

  // ===== 修改：构造函数接收 AppDatabase =====
  ChatProvider({required db.AppDatabase db}) : _db = db {
    _initHive();
  }
  // =======================================

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    _chatBox = await Hive.openBox<String>(_boxName);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final conversationId = await _getOrCreateDefaultConversation();
    final driftMessages = await _loadMessagesFromDrift(conversationId);
    
    if (driftMessages.isNotEmpty) {
      _messages = driftMessages;
      await _saveHistory();
      notifyListeners();
      return;
    }
    
    final String? historyJson = _chatBox?.get(_messagesKey);
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _messages = decoded.map((item) => ChatMessage.fromJson(item)).toList();
        await _backfillMessagesToDrift(conversationId, _messages);
      } catch (e) {
        _addWelcomeMessage();
      }
    } else {
      _addWelcomeMessage();
    }
    notifyListeners();
  }

  Future<int> _getOrCreateDefaultConversation() async {
    final existing = await (_db.select(_db.chatConversations)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    
    if (existing != null) {
      return existing.id;
    }
    
    final now = DateTime.now();
    final id = await _db.into(_db.chatConversations).insert(
          db.ChatConversationsCompanion.insert(
            title: '默认对话',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<List<ChatMessage>> _loadMessagesFromDrift(int conversationId) async {
    final rows = await (_db.select(_db.chatMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
        .get();
    
    return rows.map((row) => ChatMessage(
      role: row.role,
      content: row.content,
    )).toList();
  }

  // ===== 修改：仅对 bool 和 enum 字段使用 Value 包装 =====
  Future<void> _backfillMessagesToDrift(int conversationId, List<ChatMessage> messages) async {
    await _db.transaction(() async {
      for (final msg in messages) {
        await _db.into(_db.chatMessages).insert(
          db.ChatMessagesCompanion.insert(
            conversationId: conversationId,
            role: msg.role,
            content: msg.content,
            createdAt: DateTime.now(),
            isQuality: const drift.Value(false),
            syncStatus: drift.Value(db.SyncStatus.pending),
          ),
        );
      }
    });
  }
  // ==========================================

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

  // ===== 修改：发送消息时同时写入 Drift（仅 bool 和 enum 字段用 Value 包装）=====
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();
    _saveHistory();

    final conversationId = await _getOrCreateDefaultConversation();
    await _db.into(_db.chatMessages).insert(
      db.ChatMessagesCompanion.insert(
        conversationId: conversationId,
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
        isQuality: const drift.Value(false),
        syncStatus: drift.Value(db.SyncStatus.pending),
      ),
    );
    await (_db.update(_db.chatConversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(db.ChatConversationsCompanion(
          updatedAt: drift.Value(DateTime.now()),
        ));

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
      content = '抱歉，千寻大脑暂时无法回应：${result.error}';
      _messages.add(ChatMessage(
        role: 'assistant',
        content: content,
      ));
    }

    await _db.into(_db.chatMessages).insert(
      db.ChatMessagesCompanion.insert(
        conversationId: conversationId,
        role: 'assistant',
        content: content,
        createdAt: DateTime.now(),
        isQuality: const drift.Value(false),
        syncStatus: drift.Value(db.SyncStatus.pending),
      ),
    );
    await (_db.update(_db.chatConversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(db.ChatConversationsCompanion(
          updatedAt: drift.Value(DateTime.now()),
        ));

    _isLoading = false;
    notifyListeners();
    _saveHistory();
  }
  // ==========================================

  Future<void> clearHistory() async {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
    await _saveHistory();
    
    final conversationId = await _getOrCreateDefaultConversation();
    await (_db.delete(_db.chatMessages)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
  }

  // ===== 修改：标记消息质量（update 中保留 Value 包装，因为 write 需要） =====
  Future<void> markMessageQuality(String messageId, bool isQuality) async {
    try {
      final success = await ApiService.markMessageQuality(
        messageId: messageId,
        isQuality: isQuality,
      );
      if (success) {
        final id = int.tryParse(messageId);
        if (id != null) {
          await (_db.update(_db.chatMessages)
                ..where((t) => t.id.equals(id)))
              .write(db.ChatMessagesCompanion(
                isQuality: drift.Value(isQuality),
                syncStatus: drift.Value(db.SyncStatus.pending),
              ));
        }
        debugPrint('消息 $messageId 质量标记成功: $isQuality');
      }
    } catch (e) {
      debugPrint('标记消息质量失败: $e');
    }
  }
  // ==========================================
}