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

  late final List<Widget> _pages = [
    const HomePage(),
    const StrategiesPage(),
    const WarGamePage(),
    const KnowledgePage(),
    const LogsPage(),
  ];

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
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '策略库'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: '战报'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: '外脑'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '日志'),
        ],
      ),
    );
  }
}