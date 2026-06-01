import 'package:uuid/uuid.dart';
import '../models/inspection_report.dart';
import '../models/new_device_info.dart';

/// 深度报告生成服务
/// 合并硬件数据 + 手动检测生成完整验机报告
class DeepReportService {
  static const _uuid = Uuid();

  /// 生成深度报告 (合并硬件数据 + 手动检测)
  Future<InspectionReport> generateDeepReport({
    required DeviceInfo deviceInfo,
    required Map<String, dynamic> hardwareData,
    required Map<String, bool> manualChecks,
    required List<String> photos,
  }) async {
    // 计算外观评分 (基于手动检测)
    final appearanceScore = _calculateAppearanceScore(manualChecks);

    // 计算功能评分 (基于硬件数据 + 功能检测)
    final functionScore = _calculateFunctionScore(hardwareData, manualChecks);

    // 生成报告编号: RPT-YYYYMMDD-XXXXXX
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = now.millisecondsSinceEpoch.toString().substring(8);
    final reportNumber = 'RPT-$dateStr-$timeStr';

    return InspectionReport(
      reportId: _uuid.v4(),
      reportNumber: reportNumber,
      deviceInfo: deviceInfo,
      hardwareData: hardwareData,
      manualChecks: manualChecks,
      appearanceScore: appearanceScore,
      functionScore: functionScore,
      photos: photos,
      generatedAt: now,
      watermarkUserId: 'pending', // 从通行证获取
      watermarkTimestamp: now,
    );
  }

  /// 基于外观检测项计算 1-10 分
  /// 检测项包括: 屏幕、机身、按键、摄像头、扬声器等
  int _calculateAppearanceScore(Map<String, bool> checks) {
    if (checks.isEmpty) return 5;

    // 定义外观检测项及其权重
    const appearanceKeys = {
      'screen_scratch': 2.0,
      'screen_bubble': 2.0,
      'screen_flicker': 3.0,
      'body_dent': 1.5,
      'body_scratch': 1.0,
      'body_bend': 3.0,
      'button_damage': 2.0,
      'camera_scratch': 1.5,
      'speaker_damage': 1.0,
    };

    double totalWeight = 0;
    double deduction = 0;

    for (final entry in checks.entries) {
      final key = entry.key;
      final isOk = entry.value;

      // 计算该项的总权重
      double weight = 1.0;
      for (final ak in appearanceKeys.entries) {
        if (key.contains(ak.key)) {
          weight = ak.value;
          break;
        }
      }
      totalWeight += weight;

      // 如果检测不通过,扣分
      if (!isOk) {
        deduction += weight;
      }
    }

    // 计算分数: 10 - (扣分/总权重) * 10
    if (totalWeight == 0) return 8;
    final score = 10 - (deduction / totalWeight) * 10;
    return score.round().clamp(1, 10);
  }

  /// 基于硬件数据和功能检测计算 1-10 分
  int _calculateFunctionScore(Map<String, dynamic> hardware, Map<String, bool> checks) {
    double score = 10;

    // 基于电池循环次数扣分
    final batteryCycle = hardware['batteryCycleCount'];
    if (batteryCycle != null && batteryCycle is int) {
      if (batteryCycle > 1000) {
        score -= 3;
      } else if (batteryCycle > 500) {
        score -= 2;
      } else if (batteryCycle > 300) {
        score -= 1;
      }
    }

    // 基于激活锁状态扣分
    final activationLock = hardware['activationLockEnabled'];
    if (activationLock == true) {
      score -= 2;
    }

    // 基于功能检测项扣分
    const functionKeys = {
      'wifi': 1.0,
      'bluetooth': 1.0,
      'cellular': 1.5,
      'gps': 1.0,
      'microphone': 1.5,
      'proximity': 1.0,
      'volume_button': 1.0,
      'home_button': 1.5,
      'touch_id': 2.0,
      'face_id': 2.0,
    };

    for (final entry in checks.entries) {
      final key = entry.key;
      final isOk = entry.value;

      if (!isOk) {
        for (final fk in functionKeys.entries) {
          if (key.contains(fk.key)) {
            score -= fk.value;
            break;
          }
        }
      }
    }

    return score.round().clamp(1, 10);
  }
}