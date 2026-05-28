import 'package:flutter/services.dart';
import '../models/device_info.dart';

/// 原生平台通道异常
class NativeBridgeException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const NativeBridgeException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'NativeBridgeException[$code]: $message';
}

/// 原生平台通道服务
///
/// 通过 Flutter MethodChannel 与原生 iOS/Android 代码通信，
/// 获取系统级设备信息（RAM、存储、传感器列表等）。
class NativeBridge {
  static const String _channelName = 'com.deviceinspector/device_info';
  static const MethodChannel _channel = MethodChannel(_channelName);

  // ——— 设备信息 ———

  /// 获取完整设备信息
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getDeviceInfo');
      if (result == null) {
        throw const NativeBridgeException(message: '设备信息返回为空');
      }
      final json = _castMap(result);
      return DeviceInfo.fromJson(json);
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取设备信息失败',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// 获取实时内存使用情况
  Future<Map<String, double>> getMemoryInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getMemoryInfo');
      if (result == null) return {};
      return _castMap(result).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取内存信息失败',
        code: e.code,
      );
    }
  }

  /// 获取实时存储信息
  Future<Map<String, double>> getStorageInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getStorageInfo');
      if (result == null) return {};
      return _castMap(result).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取存储信息失败',
        code: e.code,
      );
    }
  }

  // ——— 电池 ———

  /// 获取电池信息
  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getBatteryInfo');
      if (result == null) return {};
      return _castMap(result);
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取电池信息失败',
        code: e.code,
      );
    }
  }

  // ——— 网络 ———

  /// 获取网络信息
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getNetworkInfo');
      if (result == null) return {};
      return _castMap(result);
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取网络信息失败',
        code: e.code,
      );
    }
  }

  // ——— 传感器 ———

  /// 获取传感器列表
  Future<List<String>> getSensorList() async {
    try {
      final result =
          await _channel.invokeMethod<List<Object?>>('getSensorList');
      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取传感器列表失败',
        code: e.code,
      );
    }
  }

  // ——— 相机 ———

  /// 获取相机信息列表
  Future<List<CameraInfo>> getCameraList() async {
    try {
      final result =
          await _channel.invokeMethod<List<Object?>>('getCameraList');
      if (result == null) return [];
      return result
          .whereType<Map<Object?, Object?>>()
          .map((e) => CameraInfo.fromJson(_castMap(e)))
          .toList();
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '获取相机信息失败',
        code: e.code,
      );
    }
  }

  // ——— 性能测试 ———

  /// 运行 CPU 基准测试（异步，可能耗时较长）
  Future<Map<String, dynamic>> runCpuBenchmark() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('runCpuBenchmark');
      if (result == null) return {};
      return _castMap(result);
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? 'CPU 基准测试失败',
        code: e.code,
      );
    }
  }

  /// 运行存储速度测试
  Future<Map<String, dynamic>> runStorageBenchmark() async {
    try {
      final result = await _channel
          .invokeMethod<Map<Object?, Object?>>('runStorageBenchmark');
      if (result == null) return {};
      return _castMap(result);
    } on PlatformException catch (e) {
      throw NativeBridgeException(
        message: e.message ?? '存储速度测试失败',
        code: e.code,
      );
    }
  }

  // ——— 工具方法 ———

  /// 将平台返回的 Map<Object?, Object?> 转为 Map<String, dynamic>
  Map<String, dynamic> _castMap(Map<Object?, Object?> raw) {
    return raw.map((k, v) {
      final key = k?.toString() ?? '';
      dynamic value = v;
      if (v is Map<Object?, Object?>) {
        value = _castMap(v);
      } else if (v is List) {
        value = v.map((item) {
          if (item is Map<Object?, Object?>) return _castMap(item);
          return item;
        }).toList();
      }
      return MapEntry(key, value);
    });
  }
}
