// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/fund_card.dart';
import '../widgets/ai_status_bar.dart';
import '../widgets/alert_settings.dart';
import '../pages/guardian_suggestions_page.dart';
import '../pages/risk_settings_page.dart';

/// 首页
/// 全局状态总览：资金、AI状态、风控、待处理事项
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = {};
  int _pendingSuggestions = 0;
  String _marketStatus = '震荡';
  String _riskStatus = 'normal';
  String _alertLevel = 'none';
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
        ApiService.getDashboard(),
        ApiService.getPendingAdviceCount(),
        ApiService.getMarketStatus(),
        ApiService.getRiskStatus(),
        ApiService.getFuseStatus(),
      ]);

      // 1. 仪表盘数据
      if (results[0] != null && results[0] is Map<String, dynamic>) {
        _dashboard = results[0] as Map<String, dynamic>;
      }

      // 2. 守门员建议数量 - 增强类型安全
      if (results[1] != null) {
        if (results[1] is int) {
          _pendingSuggestions = results[1] as int;
        } else if (results[1] is Map) {
          final map = results[1] as Map;
          _pendingSuggestions = (map['count'] as int?) ?? 0;
        } else {
          _pendingSuggestions = 0;
        }
      }

      // 3. 市场状态
      if (results[2] != null && results[2] is Map<String, dynamic>) {
        final market = results[2] as Map<String, dynamic>;
        _marketStatus = market['status'] ?? '震荡';
      }

      // 4. 风控状态
      if (results[3] != null && results[3] is Map<String, dynamic>) {
        final risk = results[3] as Map<String, dynamic>;
        _riskStatus = risk['status'] ?? 'normal';
      }

      // 5. 熔断状态
      if (results[4] != null && results[4] is Map<String, dynamic>) {
        final fuse = results[4] as Map<String, dynamic>;
        _alertLevel = fuse['alert_level'] ?? 'none';
      }
    } catch (e) {
      debugPrint('加载首页数据失败: $e');
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

  String _getRiskStatusText(String status) {
    switch (status) {
      case 'normal':
        return '正常';
      case 'warning':
        return '警告';
      case 'fuse':
        return '熔断';
      default:
        return '正常';
    }
  }

  Color _getRiskStatusColor(String status) {
    switch (status) {
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'fuse':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getAlertLevelText(String level) {
    switch (level) {
      case 'yellow':
        return '黄色预警';
      case 'orange':
        return '橙色预警';
      case 'red':
        return '红色预警';
      default:
        return '';
    }
  }

  Color _getAlertLevelColor(String level) {
    switch (level) {
      case 'yellow':
        return Colors.orange;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.transparent;
    }
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
                        // 预警级别显示
                        if (_alertLevel != 'none')
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getAlertLevelColor(_alertLevel).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getAlertLevelColor(_alertLevel),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: _getAlertLevelColor(_alertLevel),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getAlertLevelText(_alertLevel),
                                  style: TextStyle(
                                    color: _getAlertLevelColor(_alertLevel),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/risk_settings');
                                  },
                                  child: const Text(
                                    '查看详情',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 资金双卡片
                        FundCard(
                          isReal: true,
                          onRefresh: _loadData,
                        ),
                        const SizedBox(height: 12),
                        FundCard(
                          isReal: false,
                          onRefresh: _loadData,
                        ),
                        const SizedBox(height: 16),

                        // AI状态栏
                        AIStatusBar(onRefresh: _loadData),
                        const SizedBox(height: 16),

                        // 市场与风控
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '市场状态',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _marketStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '风控状态',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRiskStatusColor(_riskStatus).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getRiskStatusText(_riskStatus),
                                          style: TextStyle(
                                            color: _getRiskStatusColor(_riskStatus),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 快捷入口
                        Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '快捷入口',
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
                                    _buildQuickAction(
                                      icon: Icons.security,
                                      label: '调整风控',
                                      onTap: () {
                                        Navigator.pushNamed(context, '/risk_settings');
                                      },
                                    ),
                                    _buildQuickAction(
                                      icon: Icons.rule,
                                      label: '批准规则',
                                      onTap: () {
                                        Navigator.pushNamed(context, '/ai_advice_center');
                                      },
                                    ),
                                    _buildQuickAction(
                                      icon: Icons.description,
                                      label: '今日报告',
                                      onTap: () {
                                        Navigator.pushNamed(context, '/report_list', arguments: {'type': 'daily'});
                                      },
                                    ),
                                    _buildQuickAction(
                                      icon: Icons.mic,
                                      label: '语音',
                                      onTap: () {
                                        // 语音功能由悬浮球处理
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 待处理事项
                        if (_pendingSuggestions > 0)
                          Card(
                            color: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GuardianSuggestionsPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                        Icons.notifications_active,
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
                                            '待处理事项',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '有$_pendingSuggestions条守门员建议待处理',
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

                        // 主动提醒设置
                        AlertSettings(
                          onSettingsChanged: () {
                            // 设置变更后的回调
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: (MediaQuery.of(context).size.width - 56) / 4,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}