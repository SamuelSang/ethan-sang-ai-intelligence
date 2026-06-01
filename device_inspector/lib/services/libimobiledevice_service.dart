import 'dart:io';
import 'package:xml/xml.dart';
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

  /// 获取设备型号 (e.g. "iPhone 15 Pro")
  Future<String?> getProductName({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run('ideviceinfo', [...args, '-k', 'ProductName']);
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  /// 获取IMEI
  Future<String?> getIMEI({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run(
        'ideviceinfo',
        [...args, '-q', 'com.apple.mobile.battery', '-k', 'InternationalMobileEquipmentIdentity']
      );
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  /// 获取电池序列号
  Future<String?> getBatterySerialNumber({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run(
        'ideviceinfo',
        [...args, '-q', 'com.apple.mobile.battery', '-k', 'BatterySerialNumber']
      );
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  /// 获取设备颜色
  Future<String?> getDeviceColor({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run('ideviceinfo', [...args, '-k', 'DeviceColor']);
      if (result.exitCode != 0) return null;
      return result.stdout.toString().trim();
    } catch (e) {
      return null;
    }
  }

  /// 获取存储容量 (GB)
  Future<int?> getStorageCapacity({String? udid}) async {
    try {
      final args = udid != null ? ['-u', udid] : <String>[];
      final result = await Process.run('ideviceinfo', [...args, '-k', 'StorageCapacity']);
      if (result.exitCode != 0) return null;
      final output = result.stdout.toString().trim();
      final parsed = int.tryParse(output);
      if (parsed == null) return null;
      // If value is very large, it's likely bytes; convert to GB
      return parsed > 1000 ? (parsed / (1024 * 1024 * 1024)).round() : parsed;
    } catch (e) {
      return null;
    }
  }

  DeviceInfo _parseDeviceInfoFromXml(String xml) {
  // Expected XML keys from ideviceinfo -x output:
  // DeviceClass -> type
  // ProductName -> modelName
  // ModelNumber -> modelNumber
  // SerialNumber -> serialNumber
  // InternationalMobileEquipmentIdentity -> imei
  // BatterySerialNumber -> batterySerialNumber
  // BatteryCycleCount -> batteryCycleCount
  // DeviceColor -> color
  // StorageCapacity -> storageCapacity
  // FirmwareVersion -> firmwareVersion
  // FindMyPhoneEnabled -> activationLockEnabled

  final document = XmlDocument.parse(xml);
  final plist = document.rootElement;

  // Extract key-value pairs from plist dict element
  Map<String, String> parseDict(XmlElement dict) {
    final result = <String, String>{};
    final children = dict.childElements.toList();
    for (int i = 0; i < children.length; i += 2) {
      final key = children[i].innerText;
      final value = children[i + 1].innerText;
      result[key] = value;
    }
    return result;
  }

  final data = parseDict(plist.findElements('dict').first);

  // Parse DeviceClass to DeviceType
  DeviceType type = DeviceType.unknown;
  final deviceClass = data['DeviceClass'] ?? '';
  if (deviceClass.toLowerCase().contains('iphone')) {
    type = DeviceType.iphone;
  } else if (deviceClass.toLowerCase().contains('ipad')) {
    type = DeviceType.ipad;
  } else if (deviceClass.toLowerCase().contains('ipod')) {
    type = DeviceType.ipod;
  }

  // Parse storage capacity
  int storageCapacity = 0;
  final storageStr = data['StorageCapacity'] ?? '';
  if (storageStr.isNotEmpty) {
    // StorageCapacity may be in bytes or GB format
    final parsed = int.tryParse(storageStr);
    if (parsed != null) {
      // If value is very large, it's likely bytes; convert to GB
      storageCapacity = parsed > 1000 ? (parsed / (1024 * 1024 * 1024)).round() : parsed;
    }
  }

  // Parse battery cycle count
  int? batteryCycleCount;
  final cycleStr = data['BatteryCycleCount'] ?? '';
  if (cycleStr.isNotEmpty) {
    batteryCycleCount = int.tryParse(cycleStr);
  }

  // Parse activation lock
  final findMyStr = data['FindMyPhoneEnabled'] ?? '';
  final activationLockEnabled = findMyStr.toLowerCase() == 'true' || findMyStr == '1';

  return DeviceInfo(
    type: type,
    modelName: data['ProductName'] ?? '',
    modelNumber: data['ModelNumber'] ?? '',
    serialNumber: data['SerialNumber'] ?? '',
    imei: data['InternationalMobileEquipmentIdentity'],
    batterySerialNumber: data['BatterySerialNumber'],
    batteryCycleCount: batteryCycleCount,
    color: data['DeviceColor'] ?? '',
    storageCapacity: storageCapacity,
    firmwareVersion: data['FirmwareVersion'] ?? '',
    activationLockEnabled: activationLockEnabled,
    repairHistory: data.containsKey('CHRepairability')
        ? data['CHRepairability']
        : '无法获取（需iOS 17+设备且已连接维修服务）',
  );
}
}