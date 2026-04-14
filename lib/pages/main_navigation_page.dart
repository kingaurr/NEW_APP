// lib/pages/main_navigation_page.dart
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart'; // 新增：凸起底部导航栏
import 'home_page.dart';
import 'real_trade_page.dart';
// import 'virtual_trade_page.dart'; // 虚拟页降级为“我的”页面内入口，不再作为独立Tab
import 'ai_advice_center_page.dart';
import 'my_page.dart';
import '../api_service.dart';

// ===== 新增宫崎骏页面导入 =====
import 'miyazaki_center_page.dart';
// ===============================

class MainNavigationPage extends StatefulWidget {
  final bool biometricsEnabled;
  const MainNavigationPage({super.key, this.biometricsEnabled = false});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 2; // 默认选中宫崎骏（中间凸起按钮索引为2）
  int _pendingCodeFixCount = 0;

  final GlobalKey<RealTradePageState> _realTradeKey = GlobalKey<RealTradePageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 页面列表：首页(0)、实盘(1)、宫崎骏(2)、AI(3)、我的(4)
    _pages = [
      const HomePage(),
      RealTradePage(key: _realTradeKey),
      const MiyazakiCenterPage(),   // 新增：宫崎骏稽查中心
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
    // 切换到 AI 页面时刷新待审批数量
    if (index == 3) {
      _loadPendingCount();
    }
    // 刷新实盘页面
    if (index == 1) {
      _realTradeKey.currentState?.refresh();
    }
  }

  // 构建AI页图标（带待审批徽章）
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
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,           // 中间凸起圆形样式
        backgroundColor: const Color(0xFF1E1E1E),
        activeColor: const Color(0xFFD4AF37),
        color: Colors.grey,
        iconSize: 22.0,                        // 新增：调小图标
        textStyle: const TextStyle(fontSize: 10), // 新增：调小文字
        items: [
          const TabItem(icon: Icons.dashboard_outlined, title: '首页'),
          const TabItem(icon: Icons.trending_up_outlined, title: '实盘'),
          const TabItem(icon: Icons.movie_outlined, title: '宫崎骏'),   // 凸起项
          TabItem(icon: _buildAIcon(), title: 'AI'),                  // 自定义图标
          const TabItem(icon: Icons.person_outline, title: '我的'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}