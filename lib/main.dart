// lib/main.dart
import 'dart:async';
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

// ===== 新增页面导入 =====
import 'pages/outer_brain_center_page.dart';
import 'pages/log_analysis_page.dart';
import 'pages/arbitration_detail_page.dart';
import 'pages/alert_list_page.dart';
import 'pages/system_upgrade_page.dart';
import 'pages/community_strategies_page.dart';
import 'pages/community_strategy_detail_page.dart';
import 'pages/ipo_analysis_page.dart';
import 'pages/ipo_analysis_detail_page.dart';
import 'pages/strategy_library_page.dart';
// ===== 新增交易信号池和外脑进化报告页面 =====
import 'pages/trading_signals_page.dart';
import 'pages/evolution_report_page.dart';
// ===== 新增9个骨架页面（日报下钻及功能扩展） =====
import 'pages/fund_curve_page.dart';
import 'pages/data_source_health_page.dart';
import 'pages/arbitration_history_page.dart';
import 'pages/cost_detail_page.dart';
import 'pages/sector_detail_page.dart';
import 'pages/ipo_list_page.dart';
import 'pages/macro_events_page.dart';
import 'pages/action_history_page.dart';
import 'pages/backtest_report_page.dart';
// ===== 新增交易监控页面 =====
import 'pages/trade_monitor_page.dart';
// ===== 新增战略规划与战略执行页面 =====
import 'pages/strategy_planning_page.dart';
import 'pages/strategy_execution_page.dart';
// ===== 新增决策树独立页面 =====
import 'pages/decision_tree_page.dart';
// ============================================

void main() {
  // 全局错误捕获，确保 Release 模式下错误可见
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 原有错误日志写入（保留）
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

    // 强制清除旧的 server_url
    final prefs = await SharedPreferences.getInstance();
    final oldUrl = prefs.getString('server_url');
    if (oldUrl != null && !oldUrl.contains('/api')) {
      await prefs.remove('server_url');
    }

    ApiService.setBaseUrl('http://47.108.206.221:8080/api');

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
  }, (error, stack) {
    // 捕获未处理的异步错误，显示错误屏幕
    print("未捕获的异常: $error\n$stack");
    runApp(ErrorScreen("未捕获异常: $error\n$stack"));
  });
}

/// 错误显示屏幕，用于 Release 模式定位问题
class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorScreen(this.errorMessage);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  '应用发生错误，请将以下信息反馈给开发者',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
       
        // ===== 新增路由 =====
        else if (settings.name == '/outer_brain_center') {
          return MaterialPageRoute(
            builder: (context) => const OuterBrainCenterPage(),
          );
        } else if (settings.name == '/log_analysis') {
          return MaterialPageRoute(
            builder: (context) => const LogAnalysisPage(),
          );
        } else if (settings.name == '/arbitration_detail') {
          return MaterialPageRoute(
            builder: (context) => const ArbitrationDetailPage(),
          );
        } else if (settings.name == '/alert_list') {
          return MaterialPageRoute(
            builder: (context) => const AlertListPage(),
          );
        } else if (settings.name == '/system_upgrade') {
          return MaterialPageRoute(
            builder: (context) => const SystemUpgradePage(),
          );
        } else if (settings.name == '/community_strategies') {
          return MaterialPageRoute(
            builder: (context) => const CommunityStrategiesPage(),
          );
        } else if (settings.name == '/community_strategy_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CommunityStrategyDetailPage(ruleId: args['id']),
          );
        } else if (settings.name == '/ipo_analysis') {
          return MaterialPageRoute(
            builder: (context) => const IpoAnalysisPage(),
          );
        } else if (settings.name == '/ipo_analysis_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => IpoAnalysisDetailPage(stockCode: args['stock_code']),
          );
        }
        // ===== 策略库路由 =====
        else if (settings.name == '/strategy_library') {
          return MaterialPageRoute(
            builder: (context) => const StrategyLibraryPage(),
          );
        }
        // ===== 交易信号池和外脑进化报告路由 =====
        else if (settings.name == '/trading_signals') {
          return MaterialPageRoute(
            builder: (context) => const TradingSignalsPage(),
          );
        } else if (settings.name == '/evolution_report') {
          return MaterialPageRoute(
            builder: (context) => const EvolutionReportPage(),
          );
        }
        // ===== 报告中心路由（现在指向战略规划） =====
        else if (settings.name == '/report_center') {
          return MaterialPageRoute(
            builder: (context) => const StrategyPlanningPage(),
          );
        }
        // ===== 战略执行路由 =====
        else if (settings.name == '/strategy_execution') {
          return MaterialPageRoute(
            builder: (context) => const StrategyExecutionPage(),
          );
        }
        // ===== 新增9个骨架页面路由（日报下钻及功能扩展） =====
        else if (settings.name == '/fund_curve') {
          return MaterialPageRoute(
            builder: (context) => const FundCurvePage(),
          );
        } else if (settings.name == '/data_source_health') {
          return MaterialPageRoute(
            builder: (context) => const DataSourceHealthPage(),
          );
        } else if (settings.name == '/arbitration_history') {
          return MaterialPageRoute(
            builder: (context) => const ArbitrationHistoryPage(),
          );
        } else if (settings.name == '/cost_detail') {
          return MaterialPageRoute(
            builder: (context) => const CostDetailPage(),
          );
        } else if (settings.name == '/sector_detail') {
          final args = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => SectorDetailPage(sectorName: args),
          );
        } else if (settings.name == '/ipo_list') {
          return MaterialPageRoute(
            builder: (context) => const IpoListPage(),
          );
        } else if (settings.name == '/macro_events') {
          return MaterialPageRoute(
            builder: (context) => const MacroEventsPage(),
          );
        } else if (settings.name == '/action_history') {
          return MaterialPageRoute(
            builder: (context) => const ActionHistoryPage(),
          );
        } else if (settings.name == '/backtest_report') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final strategyId = args['strategyId'] as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => BacktestReportPage(strategyId: strategyId),
          );
        }
        // ===== 交易监控路由 =====
        else if (settings.name == '/trade_monitor') {
          return MaterialPageRoute(
            builder: (context) => const TradeMonitorPage(),
          );
        }
        // ===== 决策树独立页面路由（新增） =====
        else if (settings.name == '/decision_tree') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final decisionTree = args['decisionTree'] as Map<String, dynamic>? ?? {};
          final strategyName = args['strategyName'] as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => DecisionTreePage(
              decisionTree: decisionTree,
              strategyName: strategyName,
            ),
          );
        }
        // ==================================================
       
        return null;
      },
    );
  }
}