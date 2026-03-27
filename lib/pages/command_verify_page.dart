// lib/pages/command_verify_page.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../api_service.dart';
import '../widgets/voice_drawer.dart';

/// 指令验证页
/// 用于敏感操作前的二次验证（指纹/声纹）
class CommandVerifyPage extends StatefulWidget {
  final String command;
  final String operation;

  const CommandVerifyPage({
    super.key,
    required this.command,
    required this.operation,
  });

  @override
  State<CommandVerifyPage> createState() => _CommandVerifyPageState();
}

class _CommandVerifyPageState extends State<CommandVerifyPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isVerifying = false;
  String _verifyMethod = 'fingerprint';
  String _statusMessage = '请选择验证方式';
  bool _verified = false;
  bool _fingerprintAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAvailability();
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      _fingerprintAvailable = await _localAuth.canCheckBiometrics;
      if (!_fingerprintAvailable) {
        setState(() {
          _statusMessage = '设备不支持指纹验证，请使用声纹验证';
        });
      }
    } catch (e) {
      debugPrint('检查指纹可用性失败: $e');
      setState(() {
        _fingerprintAvailable = false;
      });
    }
  }

  Future<void> _verifyWithFingerprint() async {
    if (!_fingerprintAvailable) {
      setState(() {
        _statusMessage = '设备不支持指纹验证';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = '请按压指纹识别器...';
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证指纹以执行操作: ${widget.command}',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        setState(() {
          _verified = true;
          _statusMessage = '指纹验证通过，正在执行指令...';
        });
        await _executeCommand();
      } else {
        setState(() {
          _isVerifying = false;
          _statusMessage = '指纹验证失败，请重试或选择其他验证方式';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _statusMessage = '指纹验证异常: $e';
      });
    }
  }

  void _verifyWithVoice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VoiceDrawer(
        command: '验证身份',
        onResult: (result) async {
          if (result['success'] == true) {
            setState(() {
              _verified = true;
              _statusMessage = '声纹验证通过，正在执行指令...';
            });
            await _executeCommand();
          } else {
            setState(() {
              _statusMessage = '声纹验证失败: ${result['message']}';
            });
          }
        },
      ),
    );
  }

  Future<void> _executeCommand() async {
    try {
      // 使用静态方法 commandExecute，userId 可设为当前登录用户（或固定值）
      final result = await ApiService.commandExecute(
        widget.command,
        'admin', // 实际应替换为真实的用户ID
        skipAuth: true, // 已通过外部验证，跳过额外认证
      );

      setState(() {
        _isVerifying = false;
        _statusMessage = result?['message'] ?? '指令执行成功';
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, result);
        }
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _statusMessage = '指令执行失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指令验证'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 指令信息卡片
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '待执行指令',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.command,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '操作类型: ${widget.operation}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 验证方式选择
                const Text(
                  '请选择验证方式',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildVerifyButton(
                        icon: Icons.fingerprint,
                        label: '指纹验证',
                        onTap: _verifyWithFingerprint,
                        isSelected: _verifyMethod == 'fingerprint',
                        enabled: !_isVerifying && !_verified && _fingerprintAvailable,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildVerifyButton(
                        icon: Icons.mic,
                        label: '声纹验证',
                        onTap: _verifyWithVoice,
                        isSelected: _verifyMethod == 'voice',
                        enabled: !_isVerifying && !_verified,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 状态信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (_isVerifying)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                          ),
                        )
                      else if (_verified)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      else
                        const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _verified ? Colors.green : (_isVerifying ? Colors.white70 : Colors.grey),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 取消按钮
                if (!_verified)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, {'success': false, 'message': '用户取消'});
                      },
                      child: const Text(
                        '取消',
                        style: TextStyle(color: Colors.grey),
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

  Widget _buildVerifyButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: enabled ? (isSelected ? const Color(0xFFD4AF37) : Colors.grey) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? (isSelected ? const Color(0xFFD4AF37) : Colors.grey) : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}