// lib/utils/biometrics_helper.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricsHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

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

  /// 执行生物识别验证
  /// [reason] 验证原因，显示在弹窗中
  static Future<bool> authenticate({String reason = '请验证指纹以继续操作'}) async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,      // 仅使用生物识别，不提供备用密码
          stickyAuth: true,         // 保持验证状态，避免多次弹窗
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('指纹验证异常: $e');
      return false;
    }
  }

  /// 带备用密码选项的验证（如果允许密码）
  static Future<bool> authenticateWithPasscode({String reason = '请验证身份'}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,    // 允许使用设备密码作为备选
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('验证异常: $e');
      return false;
    }
  }
}