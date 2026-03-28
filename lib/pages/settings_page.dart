// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';
import '../widgets/alert_settings.dart';
import '../pages/security_center_page.dart';
import '../pages/voice_settings_page.dart';

/// 系统设置页面
/// 包含账户安全、资金管理、实盘参数、报告配置、预警配置、系统设置等
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _biometricsEnabled = false;
  bool _voiceEnabled = true;
  String _wakeWord = '千寻';
  String _voiceProvider = 'mock';
  double _stopLossRatio = 0.03;
  double _takeProfitRatio = 0.05;
  double _maxPositionRatio = 0.2;
  double _dailyBudget = 5.0;
  double _monthlyBudget = 200.0;
  String _reportType = 'daily';
  String _securityLevel = 'normal';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final config = await ApiService.getPublicConfig();
     
      setState(() {
        _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
        _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
        _wakeWord = prefs.getString('wake_word') ?? '千寻';
        _voiceProvider = prefs.getString('voice_provider') ?? 'mock';
      });
     
      if (config != null) {
        final risk = config['risk'] ?? {};
        final cost = config['cost_control'] ?? {};
        final report = config['report'] ?? {};
        final security = config['security'] ?? {};
       
        setState(() {
          _stopLossRatio = risk['stop_loss_ratio'] ?? 0.03;
          _takeProfitRatio = risk['take_profit_ratio'] ?? 0.05;
          _maxPositionRatio = risk['max_position_ratio'] ?? 0.2;
          _dailyBudget = cost['daily_budget'] ?? 5.0;
          _monthlyBudget = cost['monthly_budget'] ?? 200.0;
          _reportType = report['default_type'] ?? 'daily';
          _securityLevel = security['level'] ?? 'normal';
        });
      }
    } catch (e) {
      debugPrint('加载设置失败: $e');
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

  Future<void> _saveRiskParams() async {
    try {
      final success = await ApiService.updateRiskParams(
        _stopLossRatio,
        _takeProfitRatio,
        _maxPositionRatio,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('风控参数已保存'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveBudget() async {
    try {
      final success = await ApiService.updateBudgetConfig({
        'daily_budget': _dailyBudget,
        'monthly_budget': _monthlyBudget,
      });
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('预算已保存'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', _voiceEnabled);
    await prefs.setString('wake_word', _wakeWord);
    await prefs.setString('voice_provider', _voiceProvider);
   
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音设置已保存'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _toggleBiometrics() async {
    if (!_biometricsEnabled) {
      final available = await BiometricsHelper.isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设备不支持生物识别'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }
   
    setState(() {
      _biometricsEnabled = !_biometricsEnabled;
    });
    await BiometricsHelper.setEnabled(_biometricsEnabled);
  }

  void _showWakeWordDialog() {
    final controller = TextEditingController(text: _wakeWord);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('修改唤醒词', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '唤醒词',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            hintText: '例如: 千寻',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _wakeWord = controller.text;
                });
                _saveVoiceSettings();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
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
                        onPressed: _loadSettings,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 账户安全
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '账户安全',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text('指纹验证'),
                                subtitle: const Text('开启后敏感操作需验证指纹'),
                                value: _biometricsEnabled,
                                activeColor: const Color(0xFFD4AF37),
                                onChanged: (value) => _toggleBiometrics(),
                              ),
                              ListTile(
                                leading: const Icon(Icons.security, color: Color(0xFFD4AF37)),
                                title: const Text('安全中心'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SecurityCenterPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 语音助手
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '语音助手',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text('启用语音助手'),
                                value: _voiceEnabled,
                                activeColor: const Color(0xFFD4AF37),
                                onChanged: (value) {
                                  setState(() {
                                    _voiceEnabled = value;
                                  });
                                  _saveVoiceSettings();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.mic, color: Color(0xFFD4AF37)),
                                title: const Text('唤醒词'),
                                subtitle: Text(_wakeWord),
                                trailing: const Icon(Icons.edit),
                                onTap: _showWakeWordDialog,
                              ),
                              ListTile(
                                leading: const Icon(Icons.settings_voice, color: Color(0xFFD4AF37)),
                                title: const Text('语音服务商'),
                                subtitle: Text(_voiceProvider == 'aliyun' ? '阿里云' : (_voiceProvider == 'iflytek' ? '讯飞' : '模拟')),
                                trailing: DropdownButton<String>(
                                  value: _voiceProvider,
                                  dropdownColor: const Color(0xFF2A2A2A),
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  items: const [
                                    DropdownMenuItem(value: 'mock', child: Text('模拟')),
                                    DropdownMenuItem(value: 'aliyun', child: Text('阿里云')),
                                    DropdownMenuItem(value: 'iflytek', child: Text('讯飞')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _voiceProvider = value;
                                      });
                                      _saveVoiceSettings();
                                    }
                                  },
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.record_voice_over, color: Color(0xFFD4AF37)),
                                title: const Text('声纹设置'),
                                subtitle: const Text('注册声纹、管理声纹库'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const VoiceSettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 风控参数
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '风控参数',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSliderRow(
                                label: '止损比例',
                                value: _stopLossRatio,
                                min: 0.01,
                                max: 0.1,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _stopLossRatio = v;
                                  });
                                  _saveRiskParams();
                                },
                              ),
                              _buildSliderRow(
                                label: '止盈比例',
                                value: _takeProfitRatio,
                                min: 0.01,
                                max: 0.2,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _takeProfitRatio = v;
                                  });
                                  _saveRiskParams();
                                },
                              ),
                              _buildSliderRow(
                                label: '最大仓位',
                                value: _maxPositionRatio,
                                min: 0.05,
                                max: 0.5,
                                formatter: (v) => '${(v * 100).toInt()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _maxPositionRatio = v;
                                  });
                                  _saveRiskParams();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 成本控制
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '成本控制',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSliderRow(
                                label: '日预算',
                                value: _dailyBudget,
                                min: 1,
                                max: 50,
                                formatter: (v) => '¥${v.toStringAsFixed(2)}',
                                onChanged: (v) {
                                  setState(() {
                                    _dailyBudget = v;
                                  });
                                  _saveBudget();
                                },
                              ),
                              _buildSliderRow(
                                label: '月预算',
                                value: _monthlyBudget,
                                min: 10,
                                max: 500,
                                formatter: (v) => '¥${v.toStringAsFixed(2)}',
                                onChanged: (v) {
                                  setState(() {
                                    _monthlyBudget = v;
                                  });
                                  _saveBudget();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 主动提醒设置
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '主动提醒',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AlertSettings(
                                onSettingsChanged: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) formatter,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text(
                formatter(value),
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFFD4AF37),
            inactiveColor: Colors.grey[700],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}