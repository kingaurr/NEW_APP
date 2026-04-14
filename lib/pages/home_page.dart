// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/fund_card.dart';
import '../widgets/ai_status_bar.dart';
import '../widgets/alert_settings.dart';
import '../widgets/upgrade_status_card.dart';
import '../widgets/shadow_summary_card.dart'; // 新增：影子摘要卡片
import '../pages/guardian_suggestions_page.dart';
import '../pages/risk_settings_page.dart';
// ========== 新增导入 ==========
import 'trading_signals_page.dart';
import 'evolution_report_page.dart';
// ============================

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

  /// 安全解析 Map，确保类型安全
  Map<String, dynamic> _safeParseMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        debugPrint('Map 转换失败: $e');
        return {};
      }
    }
    return {};
  }

  /// 安全解析数字
  int _safeParseInt(dynamic data, {int defaultValue = 0}) {
    if (data == null) return defaultValue;
    if (data is int) return data;
    if (data is double) return data.toInt();
    if (data is String) return int.tryParse(data) ?? defaultValue;
    return defaultValue;
  }

  /// 安全解析字符串
  String _safeParseString(dynamic data, {String defaultValue = ''}) {
    if (data == null) return defaultValue;
    if (data is String) return data;
    return data.toString();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getDashboard().catchError((e) {
          debugPrint('getDashboard 错误: $e');
          return null;
        }),
        ApiService.getPendingAdviceCount().catchError((e) {
          debugPrint('getPendingAdviceCount 错误: $e');
          return 0;
        }),
        ApiService.getMarketStatus().catchError((e) {
          debugPrint('getMarketStatus 错误: $e');
          return {'status': '震荡'};
        }),
        ApiService.getRiskStatus().catchError((e) {
          debugPrint('getRiskStatus 错误: $e');
          return {'status': 'normal'};
        }),
        ApiService.getFuseStatus().catchError((e) {
          debugPrint('getFuseStatus 错误: $e');
          return {'alert_level': 'none'};
        }),
      ]);

      // 1. 仪表盘数据
      _dashboard = _safeParseMap(results[0]);

      // 2. 守门员建议数量（兼容多种格式）
      final pendingData = results[1];
      if (pendingData != null) {
        if (pendingData is int) {
          _pendingSuggestions = pendingData;
        } else if (pendingData is Map) {
          _pendingSuggestions = _safeParseInt(pendingData['count']);
        } else if (pendingData is List) {
          _pendingSuggestions = pendingData.length;
        } else {
          _pendingSuggestions = 0;
        }
      } else {
        _pendingSuggestions = 0;
      }

      // 3. 市场状态
      final marketData = _safeParseMap(results[2]);
      _marketStatus = _safeParseString(marketData['status'], defaultValue: '震荡');

      // 4. 风控状态
      final riskData = _safeParseMap(results[3]);
      _riskStatus = _safeParseString(riskData['status'], defaultValue: 'normal');

      // 5. 熔断状态
      final fuseData = _safeParseMap(results[4]);
      _alertLevel = _safeParseString(fuseData['alert_level'], defaultValue: 'none');

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

  // 语音快捷入口菜单
  void _showVoiceMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.mic, color: Color(0xFFD4AF37)),
            title: const Text('语音对话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请使用右下角语音悬浮球进行语音对话')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Color(0xFFD4AF37)),
            title: const Text('文字对话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showTextDialog();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showTextDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('千寻文字对话', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入您的问题...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx2) => const AlertDialog(
                  backgroundColor: Color(0xFF2A2A2A),
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('思考中...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
              try {
                final result = await ApiService.voiceAsk(text);
                Navigator.pop(context);
                if (result != null && result['answer'] != null) {
                  showDialog(
                    context: context,
                    builder: (ctx3) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A2A),
                      title: const Text('千寻回复', style: TextStyle(color: Colors.white)),
                      content: SingleChildScrollView(
                        child: Text(
                          result['answer'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx3),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                  );
                } else {
                  throw Exception('未收到回复');
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('请求失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );
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
  // =================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 新增：显式使用深色主题背景
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

                        // ========== 新增影子摘要卡片 ==========
                        const ShadowSummaryCard(),
                        const SizedBox(height: 16),
                        // =====================================

                        AIStatusBar(onRefresh: _loadData),
                        const SizedBox(height: 16),

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
                                GridView.count(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                      onTap: _showVoiceMenu,
                                    ),
                                    // ========== 新增两个快捷入口 ==========
                                    _buildQuickAction(
                                      icon: Icons.trending_up,
                                      label: '信号池',
                                      onTap: _openTradingSignals,
                                    ),
                                    _buildQuickAction(
                                      icon: Icons.auto_awesome,
                                      label: '外脑报告',
                                      onTap: _openEvolutionReport,
                                    ),
                                    // ====================================
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const UpgradeStatusCard(),
                        const SizedBox(height: 16),

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

                        AlertSettings(
                          onSettingsChanged: () {},
                        ),
                      ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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