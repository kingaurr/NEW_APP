// lib/pages/main_navigation_page.dart
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'real_trade_page.dart';
import 'virtual_trade_page.dart';
import 'ai_advice_center_page.dart';
import 'my_page.dart';
import '../api_service.dart';

class MainNavigationPage extends StatefulWidget {
  final bool biometricsEnabled;
  const MainNavigationPage({super.key, this.biometricsEnabled = false});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  int _pendingCodeFixCount = 0; // 待审批代码修改数量

  final GlobalKey<RealTradePageState> _realTradeKey = GlobalKey<RealTradePageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      RealTradePage(key: _realTradeKey),
      const VirtualTradePage(),
      const AiAdviceCenterPage(),
      MyPage(biometricsEnabled: widget.biometricsEnabled),
    ];
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await ApiService.getPendingCodeFixCount();
      if (mounted) {
        setState(() {
          _pendingCodeFixCount = count;
        });
      }
    } catch (e) {
      debugPrint('加载待审批数量失败: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // 切换到 AI 页面时刷新数量
    if (index == 3) {
      _loadPendingCount();
    }
    // 刷新实盘页面（可选）
    if (index == 1) {
      _realTradeKey.currentState?.refresh();
    }
  }

  // 构建带徽章的图标
  Widget _buildAIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.auto_awesome_outlined),
        if (_pendingCodeFixCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                '$_pendingCodeFixCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '首页',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: '实盘',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science),
              label: '虚拟',
            ),
            BottomNavigationBarItem(
              icon: _buildAIcon(),
              activeIcon: _buildAIcon(), // 选中时同样显示徽章
              label: 'AI',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}