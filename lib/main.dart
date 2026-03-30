// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'pages/auth_page.dart';
import 'pages/main_navigation_page.dart';
import 'pages/ai_advice_center_page.dart';
import 'pages/strategy_detail_page.dart';
import 'pages/rule_detail_page.dart';
import 'pages/candidates_detail_page.dart';
import 'pages/position_detail_page.dart';
import 'pages/report_detail_page.dart';
import 'pages/alert_detail_page.dart';
import 'pages/command_verify_page.dart';
import 'pages/security_center_page.dart';
import 'pages/audit_log_page.dart';
import 'pages/voice_settings_page.dart';
import 'pages/ip_whitelist_page.dart';
import 'pages/combat_target_page.dart';
import 'pages/experience_log_page.dart';
import 'pages/version_history_page.dart';
import 'pages/trade_pool_page.dart';
import 'pages/signal_history_page.dart';
import 'pages/war_game_history_page.dart';
import 'pages/command_history_page.dart';
import 'pages/brain_detail_page.dart';
import 'pages/risk_settings_page.dart';
import 'pages/guardian_suggestions_page.dart';
import 'pages/report_list_page.dart';
import 'pages/settings_page.dart';
import 'api_service.dart';  // ✅ 新增导入

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ 启动时自动登录（密码与后端 .env 中 APP_PASSWORD 一致）
  try {
    final success = await ApiService.login('080306');
    if (!success) {
      debugPrint('自动登录失败，请检查后端服务或密码配置');
    } else {
      debugPrint('自动登录成功');
    }
  } catch (e) {
    debugPrint('自动登录异常: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricsSetting();
  }

  Future<void> _loadBiometricsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI量化交易系统',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFB8860B),
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
            backgroundColor: const Color(0xFFD4AF37),
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
        '/home': (context) => MainNavigationPage(
          biometricsEnabled: _biometricsEnabled,
        ),
        '/ai_advice_center': (context) => const AiAdviceCenterPage(),
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
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ReportDetailPage(
              filename: args['filename'],
              reportType: args['type'],
            ),
          );
        } else if (settings.name == '/alert_detail') {
          final alert = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AlertDetailPage(alert: alert),
          );
        } else if (settings.name == '/command_verify') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CommandVerifyPage(
              command: args['command'] ?? '',
              operation: args['operation'] ?? '',
            ),
          );
        } else if (settings.name == '/security_center') {
          return MaterialPageRoute(
            builder: (context) => const SecurityCenterPage(),
          );
        } else if (settings.name == '/audit_log') {
          return MaterialPageRoute(
            builder: (context) => const AuditLogPage(),
          );
        } else if (settings.name == '/voice_settings') {
          return MaterialPageRoute(
            builder: (context) => const VoiceSettingsPage(),
          );
        } else if (settings.name == '/ip_whitelist') {
          return MaterialPageRoute(
            builder: (context) => const IPWhitelistPage(),
          );
        } else if (settings.name == '/combat_target') {
          return MaterialPageRoute(
            builder: (context) => const CombatTargetPage(),
          );
        } else if (settings.name == '/experience_log') {
          return MaterialPageRoute(
            builder: (context) => const ExperienceLogPage(),
          );
        } else if (settings.name == '/version_history') {
          return MaterialPageRoute(
            builder: (context) => const VersionHistoryPage(),
          );
        } else if (settings.name == '/trade_pool') {
          return MaterialPageRoute(
            builder: (context) => const TradePoolPage(),
          );
        } else if (settings.name == '/signal_history') {
          return MaterialPageRoute(
            builder: (context) => const SignalHistoryPage(),
          );
        } else if (settings.name == '/war_game_history') {
          return MaterialPageRoute(
            builder: (context) => const WarGameHistoryPage(),
          );
        } else if (settings.name == '/command_history') {
          return MaterialPageRoute(
            builder: (context) => const CommandHistoryPage(),
          );
        } else if (settings.name == '/brain_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BrainDetailPage(brainType: args['type']),
          );
        } else if (settings.name == '/risk_settings') {
          return MaterialPageRoute(
            builder: (context) => const RiskSettingsPage(),
          );
        } else if (settings.name == '/guardian_suggestions') {
          return MaterialPageRoute(
            builder: (context) => const GuardianSuggestionsPage(),
          );
        } else if (settings.name == '/report_list') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ReportListPage(type: args['type']),
          );
        } else if (settings.name == '/settings') {
          return MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          );
        }
        return null;
      },
      // ✅ 已移除全局语音悬浮球（VoiceFloatingButton）
    );
  }
}