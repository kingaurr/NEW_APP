// lib/utils/biometrics_helper.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 生物识别辅助类
/// 支持指纹/面容识别，集成本地存储保存用户偏好
class BiometricsHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  // 存储键
  static const String _keyBiometricsEnabled = 'biometrics_enabled';
  static const String _keyBiometricsType = 'biometrics_type';

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

  /// 执行生物识别验证
  /// [reason] 验证原因，显示在弹窗中
  /// [usePasscodeFallback] 是否允许使用设备密码作为备选
  static Future<bool> authenticate({
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

  /// 执行带操作上下文的高风险操作验证
  /// [operation] 操作类型（如 'clear_position', 'modify_config'）
  /// [operationDesc] 操作描述（用于提示）
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

    return await authenticate(
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
  /// 注意：此方法会触发系统生物识别注册流程（如果设备支持）
  static Future<bool> requestEnroll() async {
    try {
      // 检查是否有已注册的生物识别
      final types = await getAvailableBiometrics();
      if (types.isNotEmpty) {
        // 已有注册，直接返回成功
        return true;
      }

      // 设备支持但未注册，尝试触发系统注册
      // 注意：部分系统可能不支持直接触发注册，需要引导用户去设置
      return false;
    } catch (e) {
      return false;
    }
  }
}