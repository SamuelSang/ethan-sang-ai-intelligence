// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionReport _$InspectionReportFromJson(Map<String, dynamic> json) =>
    InspectionReport(
      reportId: json['reportId'] as String,
      reportNumber: json['reportNumber'] as String,
      deviceInfo:
          DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
      hardwareData: json['hardwareData'] as Map<String, dynamic>,
      manualChecks: Map<String, bool>.from(json['manualChecks'] as Map),
      appearanceScore: (json['appearanceScore'] as num).toInt(),
      functionScore: (json['functionScore'] as num).toInt(),
      photos:
          (json['photos'] as List<dynamic>).map((e) => e as String).toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      watermarkUserId: json['watermarkUserId'] as String,
      watermarkTimestamp: DateTime.parse(json['watermarkTimestamp'] as String),
    );

Map<String, dynamic> _$InspectionReportToJson(InspectionReport instance) =>
    <String, dynamic>{
      'reportId': instance.reportId,
      'reportNumber': instance.reportNumber,
      'deviceInfo': instance.deviceInfo,
      'hardwareData': instance.hardwareData,
      'manualChecks': instance.manualChecks,
      'appearanceScore': instance.appearanceScore,
      'functionScore': instance.functionScore,
      'photos': instance.photos,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'watermarkUserId': instance.watermarkUserId,
      'watermarkTimestamp': instance.watermarkTimestamp.toIso8601String(),
    };
