// lib/services/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';
import '../database/database.dart';

/// 同步服务类
/// 负责处理本地数据库与远程服务器之间的数据同步
/// 采用“云端为准”的冲突解决策略
class SyncService {
  final AppDatabase _db;
  // 修改：移除 ApiService 实例化，直接使用静态方法
  
  Timer? _syncTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _initialRetryDelay = Duration(seconds: 30);
  
  // 同步状态标志
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService({required AppDatabase db}) : _db = db;

  // ===== 公开方法 =====

  /// 启动后台定时同步
  /// 会先取消已存在的定时器，然后启动新的定时器
  void startBackgroundSync() {
    _cancelTimer();
    _syncTimer = Timer.periodic(_syncInterval, (_) => _executeSync());
    debugPrint('SyncService: 后台同步已启动，间隔: ${_syncInterval.inMinutes} 分钟');
  }

  /// 停止后台定时同步
  void stopBackgroundSync() {
    _cancelTimer();
    debugPrint('SyncService: 后台同步已停止');
  }

  /// 手动触发一次同步（公开方法，供 UI 层调用）
  Future<bool> syncNow() async {
    return await _executeSync();
  }

  // ===== 核心同步逻辑 =====

  /// 执行同步的实际逻辑
  Future<bool> _executeSync() async {
    // 防止并发同步
    if (_isSyncing) {
      debugPrint('SyncService: 同步正在进行中，跳过本次触发');
      return false;
    }

    _isSyncing = true;
    debugPrint('SyncService: 开始执行同步...');

    try {
      // 顺序同步各个实体，确保依赖关系（先同步会话，再同步消息）
      final results = await Future.wait([
        _syncEntity('chat_conversations'),
        _syncEntity('chat_messages'),
        _syncEntity('trading_signals'),
        _syncEntity('stock_caches'),
      ]);

      final allSuccess = results.every((r) => r);
      
      if (allSuccess) {
        _retryCount = 0;
        debugPrint('SyncService: 同步成功完成');
      } else {
        _handleSyncFailure();
      }
      
      return allSuccess;
    } catch (e, stack) {
      debugPrint('SyncService: 同步失败: $e\n$stack');
      _handleSyncFailure();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// 同步单个实体类型
  Future<bool> _syncEntity(String entityType) async {
    try {
      // 1. 获取上次同步 token
      final lastSyncKey = 'last_sync_$entityType';
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(lastSyncKey);
      
      // 2. 调用 API 获取增量数据（修正参数名，使用静态方法）
      final response = await ApiService.syncData(
        entityType: entityType,
        lastSync: lastSync,
      );
      
      if (response == null) {
        debugPrint('SyncService: $entityType API 返回 null');
        return false;
      }
      
      // 3. 解析响应数据（真实后端格式）
      final newEntries = response['new_entries'] as List<dynamic>?;
      final deletedIds = response['deleted_ids'] as List<dynamic>?;
      final nextSyncToken = response['next_sync_token'] as String?;
      
      // 处理删除（先删后增，避免冲突）
      if (deletedIds != null && deletedIds.isNotEmpty) {
        await _batchDeleteEntity(entityType, deletedIds.cast<int>());
      }
      
      // 处理新增/更新
      if (newEntries != null && newEntries.isNotEmpty) {
        await _batchUpsertEntity(entityType, newEntries);
      }
      
      // 更新同步 token
      if (nextSyncToken != null) {
        await prefs.setString(lastSyncKey, nextSyncToken);
      }
      
      debugPrint('SyncService: $entityType 同步成功，新增/更新 ${newEntries?.length ?? 0} 条，删除 ${deletedIds?.length ?? 0} 条');
      return true;
    } catch (e) {
      debugPrint('SyncService: $entityType 同步失败: $e');
      return false;
    }
  }

  /// 批量删除实体（按 ID）
  Future<void> _batchDeleteEntity(String entityType, List<int> ids) async {
    await _db.transaction(() async {
      for (final id in ids) {
        try {
          switch (entityType) {
            case 'chat_conversations':
              await (_db.delete(_db.chatConversations)..where((t) => t.id.equals(id))).go();
              break;
            case 'chat_messages':
              await (_db.delete(_db.chatMessages)..where((t) => t.id.equals(id))).go();
              break;
            case 'trading_signals':
              await (_db.delete(_db.tradingSignals)..where((t) => t.id.equals(id))).go();
              break;
            case 'stock_caches':
              await (_db.delete(_db.stockCaches)..where((t) => t.id.equals(id))).go();
              break;
            default:
              debugPrint('SyncService: 未知实体类型 $entityType，无法执行删除');
          }
        } catch (e) {
          debugPrint('SyncService: 删除单条数据失败: id=$id, 错误: $e');
        }
      }
    });
  }

  /// 批量插入或更新实体（云端为准）
  Future<void> _batchUpsertEntity(String entityType, List<dynamic> items) async {
    await _db.transaction(() async {
      for (final item in items) {
        try {
          switch (entityType) {
            case 'chat_conversations':
              await _upsertConversation(item);
              break;
            case 'chat_messages':
              await _upsertMessage(item);
              break;
            case 'trading_signals':
              await _upsertTradingSignal(item);
              break;
            case 'stock_caches':
              await _upsertStockCache(item);
              break;
            default:
              debugPrint('SyncService: 未知实体类型 $entityType');
          }
        } catch (e) {
          debugPrint('SyncService: 单条数据写入失败: $item, 错误: $e');
          // 继续处理下一条，不中断整个事务
        }
      }
    });
  }

  // ===== 实体 Upsert 方法（云端为准） =====

  Future<void> _upsertConversation(Map<String, dynamic> json) async {
    final conversation = ChatConversationsCompanion(
      id: Value(json['id'] as int),
      title: Value(json['title'] as String),
      createdAt: Value(DateTime.parse(json['created_at'] as String)),
      updatedAt: Value(DateTime.parse(json['updated_at'] as String)),
      isArchived: Value((json['is_archived'] as bool?) ?? false),
    );
    await _db.into(_db.chatConversations).insertOnConflictUpdate(conversation);
  }

  Future<void> _upsertMessage(Map<String, dynamic> json) async {
    // 解析 syncStatus 枚举
    final rawStatus = json['sync_status'] as int? ?? 0;
    final syncStatus = SyncStatus.values[rawStatus.clamp(0, SyncStatus.values.length - 1)];
    
    final message = ChatMessagesCompanion(
      id: Value(json['id'] as int),
      conversationId: Value(json['conversation_id'] as int),
      role: Value(json['role'] as String),
      content: Value(json['content'] as String),
      createdAt: Value(DateTime.parse(json['created_at'] as String)),
      isQuality: Value((json['is_quality'] as bool?) ?? false),
      syncStatus: Value(syncStatus),
      serverId: Value(json['server_id'] as String?),
    );
    await _db.into(_db.chatMessages).insertOnConflictUpdate(message);
  }

  Future<void> _upsertTradingSignal(Map<String, dynamic> json) async {
    final signal = TradingSignalsCompanion(
      id: Value(json['id'] as int),
      symbol: Value(json['symbol'] as String),
      signalType: Value(json['signal_type'] as String),
      price: Value((json['price'] as num).toDouble()),
      quantity: Value(json['quantity'] as int),
      signalTime: Value(DateTime.parse(json['signal_time'] as String)),
      strategyId: Value(json['strategy_id'] as String?),
      confidence: Value((json['confidence'] as num?)?.toDouble()),
      isExecuted: Value((json['is_executed'] as bool?) ?? false),
      createdAt: Value(DateTime.parse(json['created_at'] as String)),
    );
    await _db.into(_db.tradingSignals).insertOnConflictUpdate(signal);
  }

  Future<void> _upsertStockCache(Map<String, dynamic> json) async {
    final stock = StockCachesCompanion(
      id: Value(json['id'] as int),
      symbol: Value(json['symbol'] as String),
      name: Value(json['name'] as String),
      latestPrice: Value((json['latest_price'] as num?)?.toDouble()),
      changePercent: Value((json['change_percent'] as num?)?.toDouble()),
      volume: Value((json['volume'] as num?)?.toDouble()),
      updatedAt: Value(DateTime.parse(json['updated_at'] as String)),
      dataJson: Value(json['data_json'] as String?),
    );
    await _db.into(_db.stockCaches).insertOnConflictUpdate(stock);
  }

  // ===== 私有辅助方法 =====

  void _cancelTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _handleSyncFailure() {
    _retryCount++;
    if (_retryCount <= _maxRetries) {
      final delay = _initialRetryDelay * (1 << (_retryCount - 1)); // 指数退避: 30s, 60s, 120s
      debugPrint('SyncService: 同步失败，将在 ${delay.inSeconds} 秒后重试 (第 $_retryCount 次)');
      Future.delayed(delay, () {
        if (!_isSyncing) {
          _executeSync();
        }
      });
    } else {
      debugPrint('SyncService: 同步失败，已达最大重试次数 $_maxRetries，等待下一个周期');
      _retryCount = 0;
    }
  }

  /// 释放资源，在应用退出或不再需要同步服务时调用
  void dispose() {
    stopBackgroundSync();
  }
}