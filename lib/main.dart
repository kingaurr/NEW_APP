// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
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
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 在 Release 模式下捕获错误并写入文件
  if (kReleaseMode) {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final File errorLogFile = File('${appDocDir.path}/flutter_error.log');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      errorLogFile.writeAsStringSync(
        '${DateTime.now()}: ${details.toString()}\n',
        mode: FileMode.append,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      errorLogFile.writeAsStringSync(
        '${DateTime.now()}: AsyncError: $error\n$stack\n',
        mode: FileMode.append,
      );
      return true;
    };
  }

  // 强制清除旧的 server_url，避免旧配置干扰（仅首次运行）
  final prefs = await SharedPreferences.getInstance();
  final oldUrl = prefs.getString('server_url');
  if (oldUrl != null && !oldUrl.contains('/api')) {
    await prefs.remove('server_url');
  }

  // 强制设置正确的 baseUrl（确保包含 /api）
  ApiService.setBaseUrl('http://47.108.206.221:8080/api');

  // 尝试从 SharedPreferences 获取 token 并验证
  final token = prefs.getString('auth_token');
  bool isAuthenticated = false;
  if (token != null && token.isNotEmpty) {
    try {
      final result = await ApiService.verifyToken();
      if (result != null && result['valid'] == true) {
        isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('token 验证失败: $e');
    }
  }

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatefulWidget {
  final bool isAuthenticated;
  const MyApp({super.key, required this.isAuthenticated});

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
      initialRoute: widget.isAuthenticated ? '/home' : '/',
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
    );
  }
}