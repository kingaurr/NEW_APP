// lib/pages/my_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/version_card.dart';
import '../widgets/broker_card.dart';
import '../widgets/risk_base_fund_setting.dart';
import '../widgets/budget_setting.dart';
import '../pages/security_center_page.dart';
import '../pages/audit_log_page.dart';
import '../pages/combat_target_page.dart';
import '../pages/experience_log_page.dart';
import '../pages/command_history_page.dart';
import '../pages/version_history_page.dart';
import '../pages/risk_settings_page.dart';
import '../pages/outer_brain_center_page.dart';
import 'chat_page.dart';
// ========== 新增导入 ==========
import 'trading_signals_page.dart';
import 'evolution_report_page.dart';
import 'strategy_planning_page.dart';
import 'strategy_execution_page.dart';
// ========== 新增虚拟交易页面导入 ==========
import 'virtual_trade_page.dart';
// ========== 新增千寻大脑页面导入 ==========
import 'brain_chat_page.dart';
// ========== v2.0 自进化中心导入（2026-04-25追加） ==========
import 'evolution_center_page.dart';
// =====================================

class MyPage extends StatefulWidget {
  final bool biometricsEnabled;

  const MyPage({super.key, required this.biometricsEnabled});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isLoading = true;
  bool _voiceEnabled = true;
  String _currentVersion = '';
  int _unreadAlerts = 0;
  int _pendingCodeFixCount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getSystemVersion(),
        ApiService.getUnreadAlertCount(),
        ApiService.getPendingCodeFixCount(),
      ]);

      if (mounted) {
        // 1. 系统版本
        if (results[0] != null && results[0] is Map<String, dynamic>) {
          final versionMap = results[0] as Map<String, dynamic>;
          setState(() {
            _currentVersion = versionMap['current_version'] ?? 'v1.0.0';
          });
        }

        // 2. 未读告警数
        if (results[1] != null) {
          if (results[1] is int) {
            setState(() {
              _unreadAlerts = results[1] as int;
            });
          } else if (results[1] is Map) {
            final alertMap = results[1] as Map<String, dynamic>;
            setState(() {
              _unreadAlerts = alertMap['count'] ?? 0;
            });
          }
        }

        // 3. 待审批代码修改数量
        if (results[2] != null && results[2] is int) {
          setState(() {
            _pendingCodeFixCount = results[2] as int;
          });
        } else if (results[2] != null && results[2] is Map) {
          final map = results[2] as Map<String, dynamic>;
          setState(() {
            _pendingCodeFixCount = map['count'] ?? 0;
          });
        } else {
          setState(() {
            _pendingCodeFixCount = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('加载个人页面数据失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSecurityCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityCenterPage()),
    );
  }

  void _showAuditLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuditLogPage()),
    );
  }

  void _showCombatTarget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CombatTargetPage()),
    );
  }

  void _showExperienceLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExperienceLogPage()),
    );
  }

  void _showCommandHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommandHistoryPage()),
    );
  }

  void _showVersionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VersionHistoryPage()),
    );
  }

  void _showAlerts() {
    Navigator.pushNamed(context, '/alert_list');
  }

  void _showReports() {
    Navigator.pushNamed(context, '/report_list', arguments: {'type': 'daily'});
  }

  void _showSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _showRiskSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RiskSettingsPage()),
    );
  }

  void _openQianxunChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  void _openOuterBrainCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OuterBrainCenterPage()),
    );
  }

  void _openCodeFixApproval() {
    Navigator.pushNamed(context, '/ai_advice_center', arguments: {'filter_type': 'code_fix'});
  }

  // ========== 新增跳转方法 ==========
  void _openTradingSignals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradingSignalsPage()),
    );
  }

  void _openEvolutionReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EvolutionReportPage()),
    );
  }

  void _openStrategyPlanning() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StrategyPlanningPage()),
    );
  }

  void _openStrategyExecution() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StrategyExecutionPage()),
    );
  }

  // ========== 新增虚拟交易跳转方法 ==========
  void _openVirtualTrade() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VirtualTradePage()),
    );
  }

  // ========== 新增千寻大脑跳转方法 ==========
  void _openBrainChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BrainChatPage()),
    );
  }

  // ========== v2.0 自进化中心跳转方法（2026-04-25追加） ==========
  void _openEvolutionCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EvolutionCenterPage()),
    );
  }
  // =======================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VersionCard(
                          onVersionChanged: _loadData,
                        ),
                        const SizedBox(height: 16),
                        BrokerCard(
                          onRefresh: _loadData,
                        ),
                        const SizedBox(height: 16),
                        RiskBaseFundSetting(
                          onChanged: _loadData,
                        ),
                        const SizedBox(height: 16),
                        BudgetSetting(
                          onChanged: _loadData,
                        ),
                        const SizedBox(height: 16),

                        if (_pendingCodeFixCount > 0)
                          Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                            ),
                            child: InkWell(
                              onTap: _openCodeFixApproval,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.code,
                                        color: Color(0xFFD4AF37),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '代码修改待审批',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '有 $_pendingCodeFixCount 条修改请求等待处理',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '功能入口',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildGridItem(
                                      icon: Icons.security,
                                      label: '安全中心',
                                      onTap: _showSecurityCenter,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.history,
                                      label: '审计日志',
                                      onTap: _showAuditLog,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.flag,
                                      label: '实战目标',
                                      onTap: _showCombatTarget,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.psychology,
                                      label: '经验日志',
                                      onTap: _showExperienceLog,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.history_edu,
                                      label: '指令历史',
                                      onTap: _showCommandHistory,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.notifications,
                                      label: '告警中心',
                                      onTap: _showAlerts,
                                      badge: _unreadAlerts > 0 ? '$_unreadAlerts' : null,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.description,
                                      label: '报告中心',
                                      onTap: _showReports,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.history,
                                      label: '版本历史',
                                      onTap: _showVersionHistory,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.settings,
                                      label: '系统设置',
                                      onTap: _showSettings,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.warning_amber,
                                      label: '风控设置',
                                      onTap: _showRiskSettings,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.chat,
                                      label: '千寻助手',
                                      onTap: _openQianxunChat,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.auto_awesome,
                                      label: '外脑中心',
                                      onTap: _openOuterBrainCenter,
                                    ),
                                    // ========== 新增入口 ==========
                                    _buildGridItem(
                                      icon: Icons.trending_up,
                                      label: '交易信号池',
                                      onTap: _openTradingSignals,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.auto_awesome,
                                      label: '外脑进化报告',
                                      onTap: _openEvolutionReport,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.insights,
                                      label: '战略规划',
                                      onTap: _openStrategyPlanning,
                                    ),
                                    _buildGridItem(
                                      icon: Icons.assignment_turned_in,
                                      label: '战略执行',
                                      onTap: _openStrategyExecution,
                                    ),
                                    // ========== 新增虚拟交易入口 ==========
                                    _buildGridItem(
                                      icon: Icons.science_outlined,
                                      label: '虚拟交易',
                                      onTap: _openVirtualTrade,
                                    ),
                                    // ========== 新增千寻大脑入口 ==========
                                    _buildGridItem(
                                      icon: Icons.psychology_alt,
                                      label: '千寻大脑',
                                      onTap: _openBrainChat,
                                    ),
                                    // ========== v2.0 自进化中心入口（2026-04-25追加） ==========
                                    _buildGridItem(
                                      icon: Icons.auto_graph,
                                      label: '自进化中心',
                                      onTap: _openEvolutionCenter,
                                    ),
                                    // ===================================
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFD4AF37), size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}