import 'device_info.dart';

/// 报告状态枚举
enum ReportStatus {
  draft,      // 草稿
  generating, // 生成中
  completed,  // 已完成
  failed,     // 失败
  shared,     // 已分享
}

/// 报告类型枚举
enum ReportType {
  full,       // 完整报告
  summary,    // 摘要报告
  hardware,   // 硬件专项
  software,   // 软件专项
  network,    // 网络专项
}

/// 检测项结果
class InspectionItem {
  final String category;
  final String name;
  final String value;
  final bool passed;
  final String? note;

  const InspectionItem({
    required this.category,
    required this.name,
    required this.value,
    required this.passed,
    this.note,
  });

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      passed: json['passed'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'value': value,
      'passed': passed,
      if (note != null) 'note': note,
    };
  }
}

/// 报告数据模型
class Report {
  final String id;
  final String title;
  final ReportType type;
  final ReportStatus status;
  final DeviceInfo deviceInfo;
  final List<InspectionItem> items;
  final String? pdfPath;
  final String? thumbnailPath;
  final String? notes;
  final String? scannedQrCode;
  final DateTime createdAt;
  final DateTime? completedAt;

  // 统计字段
  int get totalItems => items.length;
  int get passedItems => items.where((i) => i.passed).length;
  int get failedItems => items.where((i) => !i.passed).length;
  double get passRate =>
      totalItems > 0 ? passedItems / totalItems * 100 : 0.0;

  const Report({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.deviceInfo,
    required this.items,
    this.pdfPath,
    this.thumbnailPath,
    this.notes,
    this.scannedQrCode,
    required this.createdAt,
    this.completedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.full,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.draft,
      ),
      deviceInfo: DeviceInfo.fromJson(
          json['deviceInfo'] as Map<String, dynamic>? ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InspectionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pdfPath: json['pdfPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      notes: json['notes'] as String?,
      scannedQrCode: json['scannedQrCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'status': status.name,
      'deviceInfo': deviceInfo.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      if (pdfPath != null) 'pdfPath': pdfPath,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      if (notes != null) 'notes': notes,
      if (scannedQrCode != null) 'scannedQrCode': scannedQrCode,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    String? title,
    ReportType? type,
    ReportStatus? status,
    DeviceInfo? deviceInfo,
    List<InspectionItem>? items,
    String? pdfPath,
    String? thumbnailPath,
    String? notes,
    String? scannedQrCode,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      items: items ?? this.items,
      pdfPath: pdfPath ?? this.pdfPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      notes: notes ?? this.notes,
      scannedQrCode: scannedQrCode ?? this.scannedQrCode,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() =>
      'Report(id: $id, title: $title, status: ${status.name}, passRate: ${passRate.toStringAsFixed(1)}%)';
}
