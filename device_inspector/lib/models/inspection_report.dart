import 'package:json_annotation/json_annotation.dart';
import 'new_device_info.dart';

part 'inspection_report.g.dart';

@JsonSerializable()
class InspectionReport {
  final String reportId;
  final String reportNumber;     // RPT-YYYYMMDD-XXXX
  final DeviceInfo deviceInfo;
  final Map<String, dynamic> hardwareData;  // 来自libimobiledevice
  final Map<String, bool> manualChecks;    // 手动检测结果
  final int appearanceScore;    // 1-10
  final int functionScore;      // 1-10
  final List<String> photos;    // 外观照片路径
  final DateTime generatedAt;
  final String watermarkUserId;
  final DateTime watermarkTimestamp;

  InspectionReport({
    required this.reportId,
    required this.reportNumber,
    required this.deviceInfo,
    required this.hardwareData,
    required this.manualChecks,
    required this.appearanceScore,
    required this.functionScore,
    required this.photos,
    required this.generatedAt,
    required this.watermarkUserId,
    required this.watermarkTimestamp,
  });

  factory InspectionReport.fromJson(Map<String, dynamic> json) =>
      _$InspectionReportFromJson(json);
  Map<String, dynamic> toJson() => _$InspectionReportToJson(this);
}