/// 设备信息数据模型
class DeviceInfo {
  /// 设备基本信息
  final String deviceId;
  final String deviceName;
  final String model;
  final String brand;
  final String manufacturer;

  /// 系统信息
  final String osName;
  final String osVersion;
  final String sdkVersion;

  /// 硬件信息
  final String cpuArchitecture;
  final int cpuCores;
  final double totalRamMb;
  final double availableRamMb;
  final double totalStorageGb;
  final double availableStorageGb;
  final double screenWidthPx;
  final double screenHeightPx;
  final double screenDensity;
  final double screenInches;
  final String batteryLevel;
  final String batteryStatus;

  /// 网络信息
  final String networkType;
  final String wifiSsid;
  final String ipAddress;
  final String macAddress;

  /// 相机信息
  final List<CameraInfo> cameras;

  /// 传感器信息
  final List<String> sensors;

  /// 记录时间
  final DateTime recordedAt;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.model,
    required this.brand,
    required this.manufacturer,
    required this.osName,
    required this.osVersion,
    required this.sdkVersion,
    required this.cpuArchitecture,
    required this.cpuCores,
    required this.totalRamMb,
    required this.availableRamMb,
    required this.totalStorageGb,
    required this.availableStorageGb,
    required this.screenWidthPx,
    required this.screenHeightPx,
    required this.screenDensity,
    required this.screenInches,
    required this.batteryLevel,
    required this.batteryStatus,
    required this.networkType,
    required this.wifiSsid,
    required this.ipAddress,
    required this.macAddress,
    required this.cameras,
    required this.sensors,
    required this.recordedAt,
  });

  /// 从 JSON 反序列化
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      model: json['model'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      osName: json['osName'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
      sdkVersion: json['sdkVersion'] as String? ?? '',
      cpuArchitecture: json['cpuArchitecture'] as String? ?? '',
      cpuCores: json['cpuCores'] as int? ?? 0,
      totalRamMb: (json['totalRamMb'] as num?)?.toDouble() ?? 0.0,
      availableRamMb: (json['availableRamMb'] as num?)?.toDouble() ?? 0.0,
      totalStorageGb: (json['totalStorageGb'] as num?)?.toDouble() ?? 0.0,
      availableStorageGb:
          (json['availableStorageGb'] as num?)?.toDouble() ?? 0.0,
      screenWidthPx: (json['screenWidthPx'] as num?)?.toDouble() ?? 0.0,
      screenHeightPx: (json['screenHeightPx'] as num?)?.toDouble() ?? 0.0,
      screenDensity: (json['screenDensity'] as num?)?.toDouble() ?? 0.0,
      screenInches: (json['screenInches'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: json['batteryLevel'] as String? ?? '',
      batteryStatus: json['batteryStatus'] as String? ?? '',
      networkType: json['networkType'] as String? ?? '',
      wifiSsid: json['wifiSsid'] as String? ?? '',
      ipAddress: json['ipAddress'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      cameras: (json['cameras'] as List<dynamic>?)
              ?.map((e) => CameraInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'model': model,
      'brand': brand,
      'manufacturer': manufacturer,
      'osName': osName,
      'osVersion': osVersion,
      'sdkVersion': sdkVersion,
      'cpuArchitecture': cpuArchitecture,
      'cpuCores': cpuCores,
      'totalRamMb': totalRamMb,
      'availableRamMb': availableRamMb,
      'totalStorageGb': totalStorageGb,
      'availableStorageGb': availableStorageGb,
      'screenWidthPx': screenWidthPx,
      'screenHeightPx': screenHeightPx,
      'screenDensity': screenDensity,
      'screenInches': screenInches,
      'batteryLevel': batteryLevel,
      'batteryStatus': batteryStatus,
      'networkType': networkType,
      'wifiSsid': wifiSsid,
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'cameras': cameras.map((c) => c.toJson()).toList(),
      'sensors': sensors,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  /// 创建副本并修改部分字段
  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? model,
    String? brand,
    String? manufacturer,
    String? osName,
    String? osVersion,
    String? sdkVersion,
    String? cpuArchitecture,
    int? cpuCores,
    double? totalRamMb,
    double? availableRamMb,
    double? totalStorageGb,
    double? availableStorageGb,
    double? screenWidthPx,
    double? screenHeightPx,
    double? screenDensity,
    double? screenInches,
    String? batteryLevel,
    String? batteryStatus,
    String? networkType,
    String? wifiSsid,
    String? ipAddress,
    String? macAddress,
    List<CameraInfo>? cameras,
    List<String>? sensors,
    DateTime? recordedAt,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      osName: osName ?? this.osName,
      osVersion: osVersion ?? this.osVersion,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      cpuArchitecture: cpuArchitecture ?? this.cpuArchitecture,
      cpuCores: cpuCores ?? this.cpuCores,
      totalRamMb: totalRamMb ?? this.totalRamMb,
      availableRamMb: availableRamMb ?? this.availableRamMb,
      totalStorageGb: totalStorageGb ?? this.totalStorageGb,
      availableStorageGb: availableStorageGb ?? this.availableStorageGb,
      screenWidthPx: screenWidthPx ?? this.screenWidthPx,
      screenHeightPx: screenHeightPx ?? this.screenHeightPx,
      screenDensity: screenDensity ?? this.screenDensity,
      screenInches: screenInches ?? this.screenInches,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      networkType: networkType ?? this.networkType,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      cameras: cameras ?? this.cameras,
      sensors: sensors ?? this.sensors,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  String toString() =>
      'DeviceInfo(deviceId: $deviceId, model: $model, osVersion: $osVersion)';
}

/// 相机信息
class CameraInfo {
  final String id;
  final String name;
  final String facing; // 'front' | 'back' | 'external'
  final double megaPixels;
  final bool hasFlash;
  final bool hasOis;
  final List<String> supportedResolutions;

  const CameraInfo({
    required this.id,
    required this.name,
    required this.facing,
    required this.megaPixels,
    required this.hasFlash,
    required this.hasOis,
    required this.supportedResolutions,
  });

  factory CameraInfo.fromJson(Map<String, dynamic> json) {
    return CameraInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      facing: json['facing'] as String? ?? '',
      megaPixels: (json['megaPixels'] as num?)?.toDouble() ?? 0.0,
      hasFlash: json['hasFlash'] as bool? ?? false,
      hasOis: json['hasOis'] as bool? ?? false,
      supportedResolutions: (json['supportedResolutions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'facing': facing,
      'megaPixels': megaPixels,
      'hasFlash': hasFlash,
      'hasOis': hasOis,
      'supportedResolutions': supportedResolutions,
    };
  }
}
