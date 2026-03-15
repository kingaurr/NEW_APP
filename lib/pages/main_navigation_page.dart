// lib/pages/main_navigation_page.dart
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'strategies_page.dart';
import 'wargame_page.dart';
import 'knowledge_page.dart';
import 'logs_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    StrategiesPage(),
    WarGamePage(),
    KnowledgePage(),
    LogsPage(),
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
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('静默模式已开启（模拟）')),
                );
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
            onPressed: () {
              Navigator.pop(ctx);
              // 调用后端紧急停止API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('紧急停止指令已发送')),
              );
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
              // 调用平仓API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('一键平仓指令已发送')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '策略库'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: '战报'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: '外脑'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '日志'),
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