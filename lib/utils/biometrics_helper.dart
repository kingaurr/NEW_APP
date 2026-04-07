// lib/utils/biometrics_helper.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';  // 新增导入

/// 生物识别辅助类
/// 支持指纹/面容识别，集成本地存储保存用户偏好
class BiometricsHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  // 存储键
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyBiometricsType = 'biometrics_type';

  // 指纹 token 存储（内存）
  static String? _fingerprintToken;
  static int _tokenExpiry = 0;

  /// 检查设备是否支持生物识别（指纹/面容）
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// 获取已注册的生物识别类型列表（用于提示）
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 获取生物识别类型名称（用于UI显示）
  static Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.fingerprint)) {
      return '指纹';
    } else if (types.contains(BiometricType.face)) {
      return '面容';
    } else if (types.contains(BiometricType.iris)) {
      return '虹膜';
    }
    return '生物识别';
  }

  /// 检查生物识别是否已启用（用户设置）
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricsEnabled) ?? false;
  }

  /// 设置生物识别启用状态
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  /// 获取保存的生物识别类型
  static Future<String?> getSavedBiometricType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBiometricsType);
  }

  /// 保存生物识别类型
  static Future<void> setSavedBiometricType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBiometricsType, type);
  }

  /// 执行生物识别验证（仅本地，不获取后端 token）
  static Future<bool> authenticateOnly({
    String reason = '请验证指纹以继续操作',
    bool usePasscodeFallback = false,
  }) async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: !usePasscodeFallback,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('生物识别验证异常: $e');
      return false;
    }
  }

  /// 执行生物识别验证并获取后端指纹 token（用于敏感操作）
  static Future<bool> authenticateAndGetToken({
    String reason = '请验证指纹以继续操作',
    bool usePasscodeFallback = true,
  }) async {
    // 1. 本地验证
    final authenticated = await authenticateOnly(reason: reason, usePasscodeFallback: usePasscodeFallback);
    if (!authenticated) {
      return false;
    }

    // 2. 调用后端获取短期 token
    try {
      final result = await ApiService.fingerprintVerify('');
      if (result != null && result['token'] != null) {
        final token = result['token'];
        final expiresIn = result['expires_in'] ?? 300;
        ApiService.setFingerprintToken(token, expiresIn);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('获取指纹token异常: $e');
      return false;
    }
  }

  /// 获取存储的指纹 token（供 api_service 使用）
  static String? getStoredFingerprintToken() {
    return ApiService.getFingerprintToken();
  }

  /// 清除指纹 token
  static void clearFingerprintToken() {
    ApiService.clearFingerprintToken();
  }

  /// 执行带操作上下文的高风险操作验证（自动获取 token）
  static Future<bool> authenticateForOperation({
    required String operation,
    required String operationDesc,
    bool usePasscodeFallback = true,
  }) async {
    // 检查是否启用生物识别
    final enabled = await isEnabled();
    if (!enabled) {
      return false;
    }

    final biometricName = await getBiometricTypeName();
    final reason = '验证$biometricName以执行$operationDesc';

    return await authenticateAndGetToken(
      reason: reason,
      usePasscodeFallback: usePasscodeFallback,
    );
  }

  /// 检查是否支持且已启用（组合检查）
  static Future<bool> isAvailableAndEnabled() async {
    final available = await isAvailable();
    if (!available) return false;
    return await isEnabled();
  }

  /// 获取设备支持状态详情（用于设置页面）
  static Future<Map<String, dynamic>> getStatusDetail() async {
    final available = await isAvailable();
    final enabled = await isEnabled();
    final types = await getAvailableBiometrics();
    final typeNames = types.map((t) {
      if (t == BiometricType.fingerprint) return '指纹';
      if (t == BiometricType.face) return '面容';
      if (t == BiometricType.iris) return '虹膜';
      return '其他';
    }).toList();

    return {
      'available': available,
      'enabled': enabled,
      'supportedTypes': typeNames,
      'primaryType': typeNames.isNotEmpty ? typeNames.first : null,
    };
  }

  /// 请求注册生物识别（引导用户注册）
  static Future<bool> requestEnroll() async {
    try {
      final types = await getAvailableBiometrics();
      if (types.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}