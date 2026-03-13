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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final status = await ApiService.getStatus();
      setState(() {
        _mode = status['mode'] ?? 'sim';
        _currentFund = status['current_fund'] ?? 0.0;
      });
    } catch (e) {
      print('加载设置失败: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    await prefs.remove('remember_me');
    // 跳转到登录页
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
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
      body: ListView(
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
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: '手势密码/指纹',
                    value: false,
                    onChanged: (v) {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.phone,
                    title: '绑定手机号',
                    subtitle: _phone.isEmpty ? '未绑定' : _phone,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.admin_panel_settings,
                    title: '白名单管理',
                    onTap: () {},
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
                    onTap: () => _showEditFundDialog(),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.history,
                    title: '调整历史',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 实盘参数配置
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

          // 报告配置
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
                    subtitle: '实盘数据 + 进化周报',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.schedule,
                    title: '接收时间',
                    subtitle: '每日 09:00',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.star,
                    title: '重点关注标的',
                    subtitle: '贵州茅台, 宁德时代',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 预警配置
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
                    subtitle: '胜率低于40%等',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.notifications_active,
                    title: '通知方式',
                    subtitle: 'APP推送',
                    onTap: () {},
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
                    onChanged: (v) {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.attach_money,
                    title: '成本预算上限',
                    subtitle: '200元/月',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.info,
                    title: '关于',
                    subtitle: '版本 1.0.0',
                    onTap: () {},
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
            onPressed: () {
              // 实际修改资金逻辑需调用后端接口
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('资金修改功能待实现')),
              );
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