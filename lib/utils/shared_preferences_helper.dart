// lib/utils/shared_preferences_helper.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储工具类，统一管理 SharedPreferences 的读写操作
class SharedPreferencesHelper {
  static const String _chatHistoryKey = 'kq_chat_history';

  /// 保存聊天记录
  static Future<bool> saveChatHistory(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(messages);
      return await prefs.setString(_chatHistoryKey, jsonString);
    } catch (e) {
      debugPrint('保存聊天记录失败: $e');
      return false;
    }
  }

  /// 加载聊天记录
  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_chatHistoryKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<Map<String, dynamic>> messages = [];

      for (var item in decoded) {
        if (item is Map) {
          // 安全类型转换：使用类型判断，禁止 as 强制转换
          messages.add({
            'role': item['role']?.toString() ?? 'system',
            'content': item['content']?.toString() ?? '',
            'timestamp': item['timestamp'] != null
                ? DateTime.tryParse(item['timestamp'].toString()) ?? DateTime.now()
                : DateTime.now(),
            'mode': item['mode']?.toString(),
          });
        }
      }
      return messages;
    } catch (e) {
      debugPrint('加载聊天记录失败: $e');
      return [];
    }
  }

  /// 清空聊天记录（预留）
  static Future<bool> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_chatHistoryKey);
    } catch (e) {
      debugPrint('清空聊天记录失败: $e');
      return false;
    }
  }
}