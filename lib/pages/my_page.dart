// lib/pages/my_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/version_card.dart';
import '../widgets/broker_card.dart';
import '../widgets/risk_base_fund_setting.dart';
import '../widgets/budget_setting.dart';
import '../widgets/command_history.dart';
import '../pages/security_center_page.dart';
import '../pages/audit_log_page.dart';
import '../pages/combat_target_page.dart';
import '../pages/experience_log_page.dart';
import '../pages/command_history_page.dart';
import '../pages/version_history_page.dart';
import '../pages/risk_settings_page.dart';

/// 我的页面
/// 管理层：报告、设置、告警、券商管理
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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getSystemVersion(),
        ApiService.getUnreadAlertCount(),
      ]);

      if (results[0] != null) {
        setState(() {
          _currentVersion = results[0]['current_version'] ?? 'v1.0.0';
        });
      }
      
      if (results[1] != null) {
        setState(() {
          _unreadAlerts = results[1]['count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('加载个人页面数据失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
      });
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
                        // AI系统版本
                        VersionCard(
                          onVersionChanged: _loadData,
                        ),
                        const SizedBox(height: 16),

                        // 券商管理
                        BrokerCard(
                          onRefresh: _loadData,
                        ),
                        const SizedBox(height: 16),

                        // 风控基准资金
                        RiskBaseFundSetting(
                          onChanged: _loadData,
                        ),
                        const SizedBox(height: 16),

                        // 成本预算
                        BudgetSetting(
                          onChanged: _loadData,
                        ),
                        const SizedBox(height: 16),

                        // 功能入口网格
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
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
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
                                      icon: Icons.target,
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
        width: (MediaQuery.of(context).size.width - 56) / 4,
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