// lib/pages/logs_page.dart
import 'package:flutter/material.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志与告警'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '告警中心'),
            Tab(text: '系统日志'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    // 模拟告警数据
    final alerts = [
      {'time': '09:32', 'level': 'ERROR', 'content': '数据源新浪财经连接超时', 'read': false},
      {'time': '10:15', 'level': 'WARNING', 'content': '内存使用率超过85%', 'read': false},
      {'time': '11:03', 'level': 'ERROR', 'content': '左脑规则冲突检测失败', 'read': true},
      {'time': '13:45', 'level': 'INFO', 'content': '每日进化任务完成', 'read': true},
      {'time': '14:20', 'level': 'WARNING', 'content': '策略连续3笔亏损', 'read': false},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        Color levelColor;
        IconData levelIcon;
        switch (alert['level']) {
          case 'ERROR':
            levelColor = Colors.red;
            levelIcon = Icons.error;
            break;
          case 'WARNING':
            levelColor = Colors.orange;
            levelIcon = Icons.warning;
            break;
          default:
            levelColor = Colors.blue;
            levelIcon = Icons.info;
        }
        return Card(
          color: alert['read'] == false ? levelColor.withOpacity(0.2) : null,
          child: ListTile(
            leading: Icon(levelIcon, color: levelColor),
            title: Text(alert['content']),
            subtitle: Text(alert['time']),
            trailing: alert['read'] == false
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            onTap: () {
              // 标记已读（可后续实现）
            },
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    // 模拟系统日志数据
    final logs = [
      '[INFO] 2025-03-14 09:30:01 - 系统启动完成',
      '[INFO] 2025-03-14 09:30:05 - 数据源连接成功',
      '[WARNING] 2025-03-14 09:32:18 - 数据源新浪财经超时，自动切换',
      '[ERROR] 2025-03-14 09:35:22 - 获取股票 000001 K线失败',
      '[INFO] 2025-03-14 09:40:15 - 右脑生成信号 000001',
      '[INFO] 2025-03-14 09:40:16 - 左脑审批通过',
      '[INFO] 2025-03-14 09:40:18 - 买入成交 000001 100股 @ 10.23',
      '[AUDIT] 2025-03-14 10:00:01 - 用户 admin 切换模式为 sim',
      '[AUDIT] 2025-03-14 10:05:23 - 用户 admin 修改资金为 20000.00',
    ];

    return Column(
      children: [
        // 日志过滤选项
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('过滤:'),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('全部'),
                selected: true,
                onSelected: (v) {},
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('ERROR'),
                selected: false,
                onSelected: (v) {},
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('WARNING'),
                selected: false,
                onSelected: (v) {},
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('INFO'),
                selected: false,
                onSelected: (v) {},
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('AUDIT'),
                selected: false,
                onSelected: (v) {},
              ),
            ],
          ),
        ),
        // 日志列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              Color color;
              if (log.startsWith('[ERROR]')) color = Colors.red;
              else if (log.startsWith('[WARNING]')) color = Colors.orange;
              else if (log.startsWith('[AUDIT]')) color = Colors.purple;
              else color = Colors.green;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  log,
                  style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}