// lib/pages/main_navigation_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'home_page.dart';
import 'trade_monitor_page.dart';
import 'ai_page.dart';
import 'report_page.dart';
import 'knowledge_page.dart';
import 'settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // 紧急令牌（应与后端 EMERGENCY_SECRET 一致，生产环境建议从配置读取）
  static const String _emergencyToken = 'change_me_in_prod';

  // 页面列表
  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const TradeMonitorPage(),
    const AiPage(),
    const ReportPage(),
    const KnowledgePage(),
    const SettingsPage(),
  ];

  void _showEmergencyMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '紧急控制',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.warning, color: theme.colorScheme.error),
              title: Text('紧急停止', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmEmergencyStop();
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on, color: theme.colorScheme.secondary),
              title: const Text('一键平仓'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmSellAll();
              },
            ),
            ListTile(
              leading: Icon(Icons.volume_off, color: theme.colorScheme.primary),
              title: const Text('静默模式'),
              onTap: () async {
                Navigator.pop(ctx);
                await _toggleSilentMode();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmEmergencyStop() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('紧急停止', style: theme.textTheme.titleMedium),
        content: const Text('确定要停止所有交易吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final response = await ApiService.httpPost(
                '/emergency_stop',
                body: {'reason': '用户手动触发'},
                headers: {'X-Emergency-Token': _emergencyToken},
              );
              if (response != null && response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('紧急停止指令已发送'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('发送失败: ${response?['error'] ?? '未知错误'}'),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmSellAll() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text('一键平仓', style: theme.textTheme.titleMedium),
        content: const Text('确定要清仓所有股票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('一键平仓功能暂未实现')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSilentMode() async {
    final theme = Theme.of(context);
    final currentMode = await ApiService.getMode();
    if (currentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('获取当前模式失败'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
      return;
    }
    final newMode = currentMode['mode'] == 'maintenance' ? 'sim' : 'maintenance';
    final result = await ApiService.setMode(newMode);
    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换为 $newMode 模式')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('切换失败: ${result?['error'] ?? '未知错误'}'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '主页'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '交易'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: '报告'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: '知识库'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '我的'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEmergencyMenu,
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        child: const Icon(Icons.warning),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}