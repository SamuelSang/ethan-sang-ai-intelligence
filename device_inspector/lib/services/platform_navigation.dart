import 'package:flutter/services.dart';

/// iOS / Android 原生 Deep Link 跳转服务
class PlatformNavigationService {
  static const MethodChannel _iosChannel = MethodChannel('com.deviceinspector/ios');
  static const MethodChannel _androidChannel = MethodChannel('com.deviceinspector/android');

  /// 跳转 iOS 系统设置页
  /// [page] 可选值: "general" / "cellular" / "appleAccount"
  static Future<void> openIosSettings(String page) async {
    try {
      await _iosChannel.invokeMethod<void>('openSettings', {'page': page});
    } on PlatformException catch (e) {
      throw Exception('跳转设置失败: ${e.message}');
    } on MissingPluginException {
      // 非 iOS 平台时忽略
    }
  }

  /// 跳转 Android 系统设置页
  static Future<void> openAndroidSettings(String page) async {
    try {
      await _androidChannel.invokeMethod<void>('openSettings', {'page': page});
    } on PlatformException catch (e) {
      throw Exception('跳转设置失败: ${e.message}');
    } on MissingPluginException {
      // 非 Android 平台时忽略
    }
  }
}
