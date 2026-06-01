import 'dart:async';
import 'libimobiledevice_service.dart';
import '../models/new_device_info.dart';

/// USB设备扫描服务
/// 监听设备连接/断开事件
class DeviceScanner {
  static const _pollInterval = Duration(seconds: 2);

  final LibimobiledeviceService _libimobiledevice;
  StreamController<DeviceEvent>? _controller;
  Timer? _pollTimer;
  List<String> _lastDeviceIds = [];

  DeviceScanner({LibimobiledeviceService? libimobiledevice})
      : _libimobiledevice = libimobiledevice ?? LibimobiledeviceService();

  /// 设备连接/断开事件流
  Stream<DeviceEvent> get deviceEvents {
    _controller ??= StreamController<DeviceEvent>.broadcast();
    return _controller!.stream;
  }

  /// 开始监听设备变化
  void startListening() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _checkDeviceChanges();
    });
  }

  /// 停止监听
  void stopListening() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkDeviceChanges() async {
    final devices = await _libimobiledevice.getConnectedDeviceIds();

    for (final id in devices) {
      if (!_lastDeviceIds.contains(id)) {
        // 新设备连接
        _controller?.add(DeviceEvent(
          type: DeviceEventType.connected,
          udid: id,
        ));
      }
    }

    for (final id in _lastDeviceIds) {
      if (!devices.contains(id)) {
        // 设备断开
        _controller?.add(DeviceEvent(
          type: DeviceEventType.disconnected,
          udid: id,
        ));
      }
    }

    _lastDeviceIds = devices;
  }

  void dispose() {
    stopListening();
    _controller?.close();
    _controller = null;
  }
}

class DeviceEvent {
  final DeviceEventType type;
  final String? udid;
  final DeviceInfo? deviceInfo;

  DeviceEvent({required this.type, this.udid, this.deviceInfo});
}

enum DeviceEventType { connected, disconnected }