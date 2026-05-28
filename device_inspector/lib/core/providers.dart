import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_info.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../services/native_bridge.dart';

// ———— 单例服务 Provider ————

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final nativeBridgeProvider = Provider<NativeBridge>((ref) => NativeBridge());

// ———— SharedPreferences Provider ————

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ———— 已购买状态 Provider ————

final isPurchasedProvider = StateProvider<bool>((ref) => false);

// ———— 扫描结果 Provider ————

final scannedSerialProvider = StateProvider<String?>((ref) => null);

// ———— 设备信息查询状态 ————

@immutable
class DeviceQueryState {
  final bool isLoading;
  final String? serialNumber;
  final Map<String, dynamic>? activationLockResult;
  final String? error;

  const DeviceQueryState({
    this.isLoading = false,
    this.serialNumber,
    this.activationLockResult,
    this.error,
  });

  DeviceQueryState copyWith({
    bool? isLoading,
    String? serialNumber,
    Map<String, dynamic>? activationLockResult,
    String? error,
  }) {
    return DeviceQueryState(
      isLoading: isLoading ?? this.isLoading,
      serialNumber: serialNumber ?? this.serialNumber,
      activationLockResult: activationLockResult ?? this.activationLockResult,
      error: error ?? this.error,
    );
  }
}

class DeviceQueryNotifier extends StateNotifier<DeviceQueryState> {
  final ApiService _api;

  DeviceQueryNotifier(this._api) : super(const DeviceQueryState());

  Future<void> queryBySerial(String serial) async {
    state = state.copyWith(isLoading: true, serialNumber: serial, error: null);
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/device/activation-lock',
        data: {'serial': serial},
        fromData: (d) => d as Map<String, dynamic>,
      );
      state = state.copyWith(
        isLoading: false,
        activationLockResult: response.data,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '查询失败，请稍后重试');
    }
  }

  void reset() {
    state = const DeviceQueryState();
  }
}

final deviceQueryProvider =
    StateNotifierProvider<DeviceQueryNotifier, DeviceQueryState>((ref) {
  return DeviceQueryNotifier(ref.read(apiServiceProvider));
});

// ———— 报告生成状态 ————

@immutable
class ReportState {
  final bool isGenerating;
  final Report? report;
  final String? error;

  const ReportState({
    this.isGenerating = false,
    this.report,
    this.error,
  });

  ReportState copyWith({
    bool? isGenerating,
    Report? report,
    String? error,
  }) {
    return ReportState(
      isGenerating: isGenerating ?? this.isGenerating,
      report: report ?? this.report,
      error: error ?? this.error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ApiService _api;

  ReportNotifier(this._api) : super(const ReportState());

  Future<void> generateReport(String serialNumber) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/report/generate',
        data: {'serial': serialNumber},
        fromData: (d) => d as Map<String, dynamic>,
      );
      if (response.data != null) {
        final report = Report.fromJson(response.data!);
        state = state.copyWith(isGenerating: false, report: report);
      } else {
        state = state.copyWith(isGenerating: false, error: '报告数据为空');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isGenerating: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: '报告生成失败，请稍后重试');
    }
  }

  void clear() {
    state = const ReportState();
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref.read(apiServiceProvider));
});

// ———— 本机设备信息 Provider ————

final localDeviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  final bridge = ref.read(nativeBridgeProvider);
  return bridge.getDeviceInfo();
});
