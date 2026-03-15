// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'pages/main_navigation_page.dart';
import 'pages/ai_advice_center_page.dart';
import 'pages/strategy_detail_page.dart';
import 'pages/rule_detail_page.dart';
import 'pages/candidates_detail_page.dart';
import 'pages/position_detail_page.dart';
import 'pages/report_detail_page.dart';
import 'pages/alert_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI量化交易系统',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFB8860B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB8860B),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          error: Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB8860B),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w500),
        ),
        fontFamily: 'Georgia',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/home': (context) => const MainNavigationPage(),
        '/ai_advice_center': (context) => const AiAdviceCenterPage(),
        // 带参数的页面使用 onGenerateRoute 处理
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/strategy_detail') {
          final strategy = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => StrategyDetailPage(strategy: strategy),
          );
        } else if (settings.name == '/rule_detail') {
          final rule = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RuleDetailPage(rule: rule),
          );
        } else if (settings.name == '/candidates_detail') {
          final stock = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CandidatesDetailPage(stock: stock),
          );
        } else if (settings.name == '/position_detail') {
          final position = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PositionDetailPage(position: position),
          );
        } else if (settings.name == '/report_detail') {
          final reportType = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ReportDetailPage(
              reportType: reportType['type'],
              reportDate: reportType['date'],
            ),
          );
        } else if (settings.name == '/alert_detail') {
          final alert = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AlertDetailPage(alert: alert),
          );
        }
        // 如果没有匹配的路由，返回 null 会触发错误页面
        return null;
      },
    );
  }
}