// lib/pages/auth_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _loginMethod = 0;

  // 密码登录
  final _passwordController = TextEditingController();

  // 短信登录
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _codeSent = false;
  int _countdown = 60;
  Timer? _timer;

  // 通用
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showServerConfig = false;
  String _serverUrl = 'http://47.108.206.221:8080';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _loginMethod = _tabController.index;
        _errorMessage = '';
      });
    });
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password') ?? '';
    final savedRemember = prefs.getBool('remember_me') ?? false;
    final savedServer = prefs.getString('server_url') ?? _serverUrl;
    setState(() {
      _passwordController.text = savedPassword;
      _rememberMe = savedRemember;
      _serverUrl = savedServer;
    });
    ApiService.setBaseUrl(savedServer);
  }

  Future<void> _sendSmsCode() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = '请输入手机号');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    ApiService.setBaseUrl(_serverUrl);
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/sms/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phoneController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _codeSent = true;
          _countdown = 60;
          _isLoading = false;
        });
        _startCountdown();
      } else {
        setState(() {
          _errorMessage = data['error'] ?? '发送失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _codeSent = false;
          _countdown = 60;
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _loginWithSms() async {
    if (_phoneController.text.isEmpty || _smsCodeController.text.isEmpty) {
      setState(() => _errorMessage = '请填写手机号和验证码');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    ApiService.setBaseUrl(_serverUrl);
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/sms/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'code': _smsCodeController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? '验证失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    ApiService.setBaseUrl(_serverUrl);
    try {
      final result = await ApiService.login(_passwordController.text);
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('password', _passwordController.text);
        await prefs.setBool('remember_me', true);
        await prefs.setString('server_url', _serverUrl);
      } else {
        await prefs.remove('password');
        await prefs.setBool('remember_me', false);
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题
                  Text(
                    'AI 量化交易系统',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Georgia',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 版本号
                  Text(
                    '版本 1.0.0',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // 服务器配置折叠区
                  GestureDetector(
                    onTap: () => setState(() => _showServerConfig = !_showServerConfig),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showServerConfig ? Icons.expand_less : Icons.expand_more,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '服务器配置',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_showServerConfig) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: '服务器地址',
                              hintText: '例如 http://47.108.206.221:8080',
                              labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                            ),
                            style: theme.textTheme.bodyLarge,
                            onChanged: (value) => _serverUrl = value,
                            controller: TextEditingController(text: _serverUrl),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '可切换云端/本地地址',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 登录方式切换标签
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: theme.colorScheme.secondary,
                      ),
                      labelColor: theme.colorScheme.onSecondary,
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      unselectedLabelStyle: theme.textTheme.bodyMedium,
                      tabs: const [
                        Tab(text: '密码登录'),
                        Tab(text: '短信登录'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 登录表单
                  if (_loginMethod == 0) ...[
                    // 密码登录
                    Column(
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: '密码',
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              activeColor: theme.colorScheme.secondary,
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              '记住密码',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary, size: 22),
                              onPressed: () {
                                // 指纹预留
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                  )
                                : const Text('登录'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // 短信登录
                    Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: '手机号',
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _smsCodeController,
                                decoration: InputDecoration(
                                  labelText: '验证码',
                                  labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  prefixIcon: Icon(Icons.message, color: theme.colorScheme.primary, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                ),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _codeSent
                                ? Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_countdown}s',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  )
                                : SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _sendSmsCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.secondary,
                                        foregroundColor: theme.colorScheme.onSecondary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: const Text('获取验证码'),
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithSms,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                  )
                                : const Text('登录'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}