// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      modelName: json['modelName'] as String,
      modelNumber: json['modelNumber'] as String,
      serialNumber: json['serialNumber'] as String,
      imei: json['imei'] as String?,
      batterySerialNumber: json['batterySerialNumber'] as String?,
      batteryCycleCount: (json['batteryCycleCount'] as num?)?.toInt(),
      color: json['color'] as String,
      storageCapacity: (json['storageCapacity'] as num).toInt(),
      firmwareVersion: json['firmwareVersion'] as String,
      activationLockEnabled: json['activationLockEnabled'] as bool,
      repairHistory: json['repairHistory'] as String?,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'modelName': instance.modelName,
      'modelNumber': instance.modelNumber,
      'serialNumber': instance.serialNumber,
      'imei': instance.imei,
      'batterySerialNumber': instance.batterySerialNumber,
      'batteryCycleCount': instance.batteryCycleCount,
      'color': instance.color,
      'storageCapacity': instance.storageCapacity,
      'firmwareVersion': instance.firmwareVersion,
      'activationLockEnabled': instance.activationLockEnabled,
      'repairHistory': instance.repairHistory,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.iphone: 'iphone',
  DeviceType.ipad: 'ipad',
  DeviceType.mac: 'mac',
};
