// lib/database/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'; // 新增：Android 旧版本兼容
import 'package:sqlite3/sqlite3.dart'; // 新增：解决 sqlite3 未定义错误

part 'database.g.dart';

// ===== 枚举定义 =====

/// 同步状态枚举
enum SyncStatus {
  pending, // 0: 待同步
  synced,  // 1: 已同步
  failed   // 2: 同步失败
}

// ===== 表定义 =====

/// 对话会话表
@DataClassName('ChatConversation')
class ChatConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// 对话消息表
@DataClassName('ChatMessageDrift')  // 修改：避免与 models/chat_message.dart 冲突
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(ChatConversations, #id)();
  TextColumn get role => text().withLength(min: 1, max: 20)(); // 'user' 或 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isQuality => boolean().withDefault(const Constant(false))();
  // 修改：使用 intEnum 提升代码可读性
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();
  TextColumn get serverId => text().nullable()();
}

/// 交易信号表
@DataClassName('TradingSignal')
class TradingSignals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get symbol => text().withLength(min: 1, max: 20)();
  TextColumn get signalType => text().withLength(min: 1, max: 20)(); // 'buy' 或 'sell'
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  DateTimeColumn get signalTime => dateTime()();
  TextColumn get strategyId => text().nullable()();
  RealColumn get confidence => real().nullable()();
  BoolColumn get isExecuted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 股票缓存表
@DataClassName('StockCache')
class StockCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get symbol => text().withLength(min: 1, max: 20)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get latestPrice => real().nullable()();
  RealColumn get changePercent => real().nullable()();
  RealColumn get volume => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get dataJson => text().nullable()(); // 完整数据JSON，用于扩展字段
}

// ===== 数据库类 =====

@DriftDatabase(
  tables: [
    ChatConversations,
    ChatMessages,
    TradingSignals,
    StockCaches,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ===== 迁移策略（预留） =====
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本迁移逻辑在此添加
      },
    );
  }
}

// ===== 数据库连接工厂 =====

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'trading_system.db'));

    // Android 旧版本兼容处理
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // 设置 SQLite 临时目录
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}