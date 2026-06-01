import 'package:json_annotation/json_annotation.dart';

part 'new_device_info.g.dart';

enum DeviceType { iphone, ipad, mac }

@JsonSerializable()
class DeviceInfo {
  final DeviceType type;
  final String modelName;        // e.g. "iPhone 15 Pro"
  final String modelNumber;      // e.g. "A3094"
  final String serialNumber;
  final String? imei;
  final String? batterySerialNumber;
  final int? batteryCycleCount;
  final String color;
  final int storageCapacity;     // GB
  final String firmwareVersion;
  final bool activationLockEnabled;
  final String? repairHistory;   // CHRepairability (部分机型)

  DeviceInfo({
    required this.type,
    required this.modelName,
    required this.modelNumber,
    required this.serialNumber,
    this.imei,
    this.batterySerialNumber,
    this.batteryCycleCount,
    required this.color,
    required this.storageCapacity,
    required this.firmwareVersion,
    required this.activationLockEnabled,
    this.repairHistory,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);
}