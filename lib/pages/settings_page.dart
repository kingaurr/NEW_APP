// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _smsEnabled = false;
  String _phone = '';
  double _currentFund = 0.0;
  String _mode = 'sim';
  bool _isLoading = false;

  // 本地存储的配置项
  String _reportContent = '实盘数据 + 进化周报';
  String _reportTime = '每日 09:00';
  String _focusStocks = '贵州茅台, 宁德时代';
  String _alertRules = '胜率低于40%';
  String _notificationMethod = 'APP推送';
  String _costBudget = '200元/月';
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadLocalConfig();
  }

  // 从后端加载系统设置（资金、模式等）
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final status = await ApiService.getStatus();
      if (status != null) {
        setState(() {
          _mode = status['mode'] ?? 'sim';
          _currentFund = (status['fund'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      _showSnackBar('加载设置失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 从本地存储加载用户配置
  Future<void> _loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reportContent = prefs.getString('reportContent') ?? '实盘数据 + 进化周报';
      _reportTime = prefs.getString('reportTime') ?? '每日 09:00';
      _focusStocks = prefs.getString('focusStocks') ?? '贵州茅台, 宁德时代';
      _alertRules = prefs.getString('alertRules') ?? '胜率低于40%';
      _notificationMethod = prefs.getString('notificationMethod') ?? 'APP推送';
      _costBudget = prefs.getString('costBudget') ?? '200元/月';
    });
  }

  // 保存字符串到本地存储
  Future<void> _saveLocalConfig(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _logout() async {
    await ApiService.authLogout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    await prefs.remove('remember_me');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _modifyFund(double newAmount) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.modifyFund(newAmount, reason: '用户手动修改');
      if (result != null && result['success'] == true) {
        _showSnackBar('资金修改成功');
        await _loadSettings();
      } else {
        _showSnackBar('资金修改失败: ${result?['error'] ?? '未知错误'}', isError: true);
      }
    } catch (e) {
      _showSnackBar('资金修改异常: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMode(bool wantReal) async {
    final newMode = wantReal ? 'real' : 'sim';
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.setMode(newMode);
      if (result != null && result['success'] == true) {
        setState(() => _mode = newMode);
        _showSnackBar('已切换为 ${newMode.toUpperCase()} 模式');
      } else {
        _showSnackBar('模式切换失败: ${result?['error'] ?? '未知错误'}', isError: true);
      }
    } catch (e) {
      _showSnackBar('模式切换异常: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 通用编辑对话框
  Future<void> _editConfigDialog({
    required String title,
    required String currentValue,
    required String prefKey,
    List<String>? options,
  }) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    String? selectedOption = currentValue;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(title, style: const TextStyle(color: Color(0xFFD4AF37))),
        content: options == null
            ? TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : DropdownButtonFormField<String>(
                value: selectedOption,
                items: options.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (val) => selectedOption = val,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = options == null ? controller.text : selectedOption;
              if (newValue == null || newValue.isEmpty) return;
              await _saveLocalConfig(prefKey, newValue);
              setState(() {
                switch (prefKey) {
                  case 'reportContent': _reportContent = newValue; break;
                  case 'reportTime': _reportTime = newValue; break;
                  case 'focusStocks': _focusStocks = newValue; break;
                  case 'alertRules': _alertRules = newValue; break;
                  case 'notificationMethod': _notificationMethod = newValue; break;
                  case 'costBudget': _costBudget = newValue; break;
                }
              });
              Navigator.pop(ctx);
              _showSnackBar('设置已保存');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8860B),
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
        title: const Text('设置'),
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 账户安全
                _buildSectionTitle('账户安全'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.lock,
                          title: '修改密码',
                          onTap: () => _showSnackBar('修改密码功能待实现'),
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          icon: Icons.fingerprint,
                          title: '手势密码/指纹',
                          value: false,
                          onChanged: (v) => _showSnackBar('手势密码功能待实现'),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.phone,
                          title: '绑定手机号',
                          subtitle: _phone.isEmpty ? '未绑定' : _phone,
                          onTap: () => _showSnackBar('绑定手机号功能待实现'),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.admin_panel_settings,
                          title: '白名单管理',
                          onTap: () => _showSnackBar('白名单管理功能待实现'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 资金管理
                _buildSectionTitle('资金管理'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.account_balance_wallet,
                          title: '当前资金',
                          value: '¥ ${_currentFund.toStringAsFixed(2)}',
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.edit,
                          title: '修改实盘金额',
                          onTap: _showEditFundDialog,
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.history,
                          title: '调整历史',
                          onTap: () => _showSnackBar('调整历史功能待实现'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 实盘参数配置（静态）
                _buildSectionTitle('实盘参数'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.trending_up,
                          title: '单票最大仓位',
                          value: '20%',
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.warning,
                          title: '每日亏损熔断',
                          value: '5%',
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.swap_horiz,
                          title: '单日最大交易次数',
                          value: '10次',
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.stop,
                          title: '默认止损',
                          value: '3%',
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.flag,
                          title: '默认止盈',
                          value: '8%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 报告配置（已实现）
                _buildSectionTitle('报告配置'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.receipt,
                          title: '报告内容选择',
                          subtitle: _reportContent,
                          onTap: () => _editConfigDialog(
                            title: '报告内容选择',
                            currentValue: _reportContent,
                            prefKey: 'reportContent',
                            options: ['实盘数据 + 进化周报', '仅实盘数据', '仅进化周报'],
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.schedule,
                          title: '接收时间',
                          subtitle: _reportTime,
                          onTap: () => _editConfigDialog(
                            title: '接收时间',
                            currentValue: _reportTime,
                            prefKey: 'reportTime',
                            options: ['每日 09:00', '每日 18:00', '每日 21:00'],
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.star,
                          title: '重点关注标的',
                          subtitle: _focusStocks,
                          onTap: () => _editConfigDialog(
                            title: '重点关注标的',
                            currentValue: _focusStocks,
                            prefKey: 'focusStocks',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 预警配置（已实现）
                _buildSectionTitle('预警配置'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.notifications,
                          title: '预警规则',
                          subtitle: _alertRules,
                          onTap: () => _editConfigDialog(
                            title: '预警规则',
                            currentValue: _alertRules,
                            prefKey: 'alertRules',
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.notifications_active,
                          title: '通知方式',
                          subtitle: _notificationMethod,
                          onTap: () => _editConfigDialog(
                            title: '通知方式',
                            currentValue: _notificationMethod,
                            prefKey: 'notificationMethod',
                            options: ['APP推送', '短信', '邮件'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 系统设置
                _buildSectionTitle('系统设置'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.speed,
                          title: '当前模式',
                          value: _mode.toUpperCase(),
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          icon: Icons.money_off,
                          title: '实盘/模拟切换',
                          value: _mode == 'real',
                          onChanged: _toggleMode,
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.attach_money,
                          title: '成本预算上限',
                          subtitle: _costBudget,
                          onTap: () => _editConfigDialog(
                            title: '成本预算上限',
                            currentValue: _costBudget,
                            prefKey: 'costBudget',
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          icon: Icons.info,
                          title: '关于',
                          subtitle: '版本 $_appVersion',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF2C2C2C),
                                title: const Text('关于', style: TextStyle(color: Color(0xFFD4AF37))),
                                content: Text('AI量化交易系统\n版本 $_appVersion\n\n版权所有 © 2026'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('确定', style: TextStyle(color: Colors.white70)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 退出登录按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ---------- 辅助构建函数（只定义一次）----------
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFB8860B),
        activeTrackColor: const Color(0xFFB8860B).withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.white24,
    );
  }

  void _showEditFundDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('修改实盘金额', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '输入新金额',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('请输入有效的正数金额'), backgroundColor: Colors.orange),
                );
                return;
              }
              Navigator.pop(ctx);
              await _modifyFund(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8860B),
              foregroundColor: Colors.black,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}