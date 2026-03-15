// lib/pages/main_navigation_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart'; // 导入 API 服务
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('紧急控制', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('紧急停止', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmEmergencyStop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.orange),
              title: const Text('一键平仓'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmSellAll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off, color: Colors.blue),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('紧急停止'),
        content: const Text('确定要停止所有交易吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 调用后端紧急停止API
              final response = await ApiService.httpPost(
                '/emergency_stop',
                body: {'reason': '用户手动触发'},
                headers: {'X-Emergency-Token': _emergencyToken},
              );
              if (response != null && response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('紧急停止指令已发送'), backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('发送失败: ${response?['error'] ?? '未知错误'}'), backgroundColor: Colors.orange),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmSellAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('一键平仓'),
        content: const Text('确定要清仓所有股票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 一键平仓接口暂未实现，显示提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('一键平仓功能暂未实现')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSilentMode() async {
    // 先获取当前模式
    final currentMode = await ApiService.getMode();
    if (currentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取当前模式失败'), backgroundColor: Colors.orange),
      );
      return;
    }
    // 静默模式可对应 maintenance 或 sim，这里切换为 maintenance
    final newMode = currentMode['mode'] == 'maintenance' ? 'sim' : 'maintenance';
    final result = await ApiService.setMode(newMode);
    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换为 $newMode 模式')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('切换失败: ${result?['error'] ?? '未知错误'}'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white54,
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
        backgroundColor: Colors.red,
        child: const Icon(Icons.warning, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}