// lib/pages/security_center_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../utils/biometrics_helper.dart';
import 'voice_settings_page.dart';
import 'audit_log_page.dart';
import 'ip_whitelist_page.dart';

class SecurityCenterPage extends StatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  State<SecurityCenterPage> createState() => _SecurityCenterPageState();
}

class _SecurityCenterPageState extends State<SecurityCenterPage> {
  bool _isLoading = true;
  bool _biometricsEnabled = false;
  String _biometricType = '指纹';
  Map<String, dynamic> _securityStatus = {};
  Map<String, dynamic> _emergencyStatus = {};
  List<dynamic> _recentAuditLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _biometricsEnabled = await BiometricsHelper.isEnabled();
      _biometricType = await BiometricsHelper.getBiometricTypeName();

      final status = await ApiService.securityStatus();
      if (status != null) {
        setState(() {
          _securityStatus = status;
        });
      }

      final esStatus = await ApiService.emergencyStatus();
      if (esStatus != null) {
        setState(() {
          _emergencyStatus = esStatus;
        });
      }

      // 修正：使用 getAuditLogs 方法，直接接收 List
      final audit = await ApiService.getAuditLogs(limit: 5);
      if (audit != null && audit is List) {
        setState(() {
          _recentAuditLogs = audit;
        });
      }
    } catch (e) {
      debugPrint('加载安全数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSecurityLevel(String level) async {
    final result = await ApiService.securityLevelSet(level);
    if (result?['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安全级别已切换为$level'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    }
  }

  Future<void> _triggerEmergencyStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认触发紧急停止', style: TextStyle(color: Colors.white)),
        content: const Text(
          '紧急停止将暂停所有交易，取消未成交订单。确定要继续吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认停止'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.emergencyStop('用户手动触发');
    if (result?['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('紧急停止已触发'), backgroundColor: Colors.red),
        );
        _loadData();
      }
    }
  }

  Future<void> _recoverSystem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认恢复系统', style: TextStyle(color: Colors.white)),
        content: const Text(
          '恢复系统将重新启用交易功能。确定要继续吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.emergencyRecover(reason: '用户手动恢复');
    if (result?['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('系统已恢复'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityLevelCard(),
                  const SizedBox(height: 16),
                  _buildEmergencyStopCard(),
                  const SizedBox(height: 16),
                  _buildBiometricsCard(),
                  const SizedBox(height: 16),
                  _buildVoiceAuthCard(),
                  const SizedBox(height: 16),
                  _buildIpWhitelistCard(),
                  const SizedBox(height: 16),
                  _buildAuditLogCard(),
                  const SizedBox(height: 16),
                  _buildRecentAuditLogs(),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityLevelCard() {
    final level = _securityStatus['security_level'] ?? 'normal';
    final levelName = level == 'strict' ? '严格' : (level == 'high' ? '高级' : '普通');

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFFD4AF37), size: 24),
                const SizedBox(width: 12),
                const Text(
                  '安全级别',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: level == 'strict'
                        ? Colors.red.withOpacity(0.2)
                        : (level == 'high' ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    levelName,
                    style: TextStyle(
                      color: level == 'strict' ? Colors.red : (level == 'high' ? Colors.orange : Colors.green),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildLevelButton('普通', 'normal', level == 'normal')),
                const SizedBox(width: 8),
                Expanded(child: _buildLevelButton('高级', 'high', level == 'high')),
                const SizedBox(width: 8),
                Expanded(child: _buildLevelButton('严格', 'strict', level == 'strict')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(String label, String level, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _updateSecurityLevel(level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFD4AF37) : Colors.grey[800],
        foregroundColor: isSelected ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(label),
    );
  }

  Widget _buildEmergencyStopCard() {
    final isActive = _emergencyStatus['is_active'] ?? false;
    final state = _emergencyStatus['state'] ?? 'normal';
    final recoverIn = _emergencyStatus['recover_in_seconds'] ?? 0;

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.warning : Icons.security,
                  color: isActive ? Colors.red : const Color(0xFFD4AF37),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '紧急停止',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? '系统已停止' : '系统运行正常',
              style: TextStyle(color: isActive ? Colors.red : Colors.green, fontSize: 14),
            ),
            if (isActive && _emergencyStatus['trigger_reason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '原因: ${_emergencyStatus['trigger_reason']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            if (isActive && recoverIn > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '预计恢复: ${recoverIn ~/ 60}分${recoverIn % 60}秒',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _triggerEmergencyStop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('触发紧急停止'),
                  ),
                ),
                if (isActive) const SizedBox(width: 12),
                if (isActive)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _recoverSystem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('恢复系统'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricsCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint, color: Color(0xFFD4AF37), size: 24),
                const SizedBox(width: 12),
                const Text(
                  '生物识别',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '启用$_biometricType验证',
                  style: const TextStyle(color: Colors.white70),
                ),
                Switch(
                  value: _biometricsEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) async {
                    await BiometricsHelper.setEnabled(value);
                    setState(() {
                      _biometricsEnabled = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? '已启用$_biometricType验证' : '已禁用生物识别')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '开启后，高风险操作需要验证生物信息',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAuthCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.mic, color: Color(0xFFD4AF37)),
        title: const Text('声纹设置', style: TextStyle(color: Colors.white)),
        subtitle: const Text('注册声纹、管理声纹库', style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VoiceSettingsPage()),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  Widget _buildIpWhitelistCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.public, color: Color(0xFFD4AF37)),
        title: const Text('IP白名单', style: TextStyle(color: Colors.white)),
        subtitle: const Text('管理允许访问的IP地址', style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IPWhitelistPage()),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  Widget _buildAuditLogCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Color(0xFFD4AF37)),
        title: const Text('审计日志', style: TextStyle(color: Colors.white)),
        subtitle: const Text('查看所有安全操作记录', style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuditLogPage()),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  Widget _buildRecentAuditLogs() {
    if (_recentAuditLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '最近操作记录',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Card(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentAuditLogs.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
            itemBuilder: (context, index) {
              final log = _recentAuditLogs[index];
              final operation = log['operation'] ?? '';
              final result = log['result'] ?? '';
              final timestamp = log['timestamp'] ?? '';

              return ListTile(
                dense: true,
                leading: Icon(
                  result == 'success' ? Icons.check_circle : Icons.error,
                  color: result == 'success' ? Colors.green : Colors.red,
                  size: 18,
                ),
                title: Text(
                  _getOperationName(operation),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                subtitle: Text(
                  timestamp.length > 19 ? timestamp.substring(0, 19) : timestamp,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                trailing: Text(
                  log['user_id'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getOperationName(String operation) {
    const names = {
      'login': '登录',
      'logout': '登出',
      'approve_rule': '批准规则',
      'reject_rule': '拒绝规则',
      'clear_position': '清仓',
      'modify_config': '修改配置',
      'rollback_version': '版本回滚',
      'fingerprint_verify': '指纹验证',
      'voice_verify': '声纹验证',
      'permission_change': '权限变更',
    };
    return names[operation] ?? operation;
  }
}