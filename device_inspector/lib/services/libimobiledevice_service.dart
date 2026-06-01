import 'dart:io';
import '../models/new_device_info.dart';

/// libimobiledevice CLI封装服务
/// 通过Process.run调用ideviceinfo等命令行工具获取iOS设备信息
class LibimobiledeviceService {
  /// 检测是否有设备连接
  Future<bool> isDeviceConnected() async {
    try {
      final result = await Process.run('idevice_id', ['-l']);
      return result.exitCode == 0 &&
             result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取已连接设备UDID列表
  Future<List<String>> getConnectedDeviceIds() async {
    try {
      final result = await Process.run('idevice_id', ['-l']);
      if (result.exitCode != 0) return [];
      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];
      return output.split('\n').where((s) => s.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取设备完整信息
  Future<DeviceInfo?> getDeviceInfo({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run('ideviceinfo', [...args, '-x']);
      if (result.exitCode != 0) return null;

      // 解析XML plist输出
      final xml = result.stdout.toString();
      return _parseDeviceInfoFromXml(xml);
    } catch (e) {
      return null;
    }
  }

  /// 获取电池循环次数
  Future<int?> getBatteryCycleCount({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run(
        'ideviceinfo',
        [...args, '-q', 'com.apple.mobile.battery', '-k', 'BatteryCycleCount']
      );
      if (result.exitCode != 0) return null;
      return int.tryParse(result.stdout.toString().trim());
    } catch (e) {
      return null;
    }
  }

  /// 获取激活锁状态
  Future<bool> isActivationLockEnabled({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run(
        'ideviceinfo',
        [...args, '-k', 'FindMyPhoneEnabled']
      );
      final output = result.stdout.toString().trim().toLowerCase();
      return output == 'true' || output == '1';
    } catch (e) {
      return false;
    }
  }

  DeviceInfo _parseDeviceInfoFromXml(String xml) {
    // 使用xml package解析XML plist格式的设备信息
    // 遍历DeviceInfo所需字段并返回
    // 示例解析逻辑:
    // final parsed = XmlDocument.parse(xml);
    // 从parsed中提取各字段值
    return DeviceInfo(
      type: DeviceType.iphone,  // TODO: 从XML解析设备类型
      modelName: '',            // TODO: 从XML解析
      modelNumber: '',          // TODO: 从XML解析
      serialNumber: '',         // TODO: 从XML解析
      imei: null,
      batterySerialNumber: null,
      batteryCycleCount: null,
      color: '',
      storageCapacity: 0,
      firmwareVersion: '',
      activationLockEnabled: false,
      repairHistory: null,
    );
  }
}