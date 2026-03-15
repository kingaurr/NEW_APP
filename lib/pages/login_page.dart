// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _smsPhoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  bool _isPasswordLogin = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _smsSent = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRememberedPassword();
  }

  Future<void> _loadRememberedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password');
    if (savedPassword != null && savedPassword.isNotEmpty) {
      setState(() {
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _smsSent = true;
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        setState(() {
          _smsSent = false;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    _smsPhoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.authPassword(_passwordController.text);
      if (result != null && result['success'] == true) {
        // 保存密码（如果记住密码勾选）
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('password', _passwordController.text);
        } else {
          await prefs.remove('password');
        }
        // 跳转到主页
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        _showError('密码错误或登录失败');
      }
    } catch (e) {
      _showError('登录异常: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSmsCode() async {
    if (_smsPhoneController.text.isEmpty) {
      _showError('请输入手机号');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.smsSend(_smsPhoneController.text);
      if (result != null && result['success'] == true) {
        _startCountdown();
        _showSnackBar('验证码已发送');
      } else {
        _showError('发送失败: ${result?['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showError('发送异常: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithSms() async {
    if (_smsPhoneController.text.isEmpty || _smsCodeController.text.isEmpty) {
      _showError('请填写手机号和验证码');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.smsVerify(_smsCodeController.text);
      if (result != null && result['success'] == true) {
        // 跳转到主页
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        _showError('验证失败: ${result?['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showError('登录异常: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / 标题
                const Text(
                  'AI 量化交易',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '智能交易系统',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),

                // 登录方式切换
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPasswordLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPasswordLogin ? const Color(0xFFD4AF37) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '密码登录',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isPasswordLogin ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPasswordLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPasswordLogin ? const Color(0xFFD4AF37) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '短信登录',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isPasswordLogin ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 登录表单
                Form(
                  key: _formKey,
                  child: _isPasswordLogin
                      ? _buildPasswordForm()
                      : _buildSmsForm(),
                ),
                const SizedBox(height: 24),

                // 登录按钮
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _isPasswordLogin ? _loginWithPassword : _loginWithSms,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isPasswordLogin ? '登录' : '登录',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 16),

                // 其他选项
                if (_isPasswordLogin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: const Color(0xFFD4AF37),
                          ),
                          const Text('记住密码', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // 忘记密码功能（可跳转或提示）
                          _showSnackBar('请联系管理员重置密码');
                        },
                        child: const Text(
                          '忘记密码?',
                          style: TextStyle(color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入密码',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入密码';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSmsForm() {
    return Column(
      children: [
        TextFormField(
          controller: _smsPhoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '手机号',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.phone, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _smsCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '验证码',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.message, color: Color(0xFFD4AF37)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _smsSent ? null : _sendSmsCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _smsSent ? Colors.grey : const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _smsSent ? '$_countdown 秒' : '获取验证码',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}