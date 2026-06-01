import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

/// 配对状态
enum PairingState {
  waiting,      // 等待小程序扫码
  scanning,     // 小程序正在扫描二维码
  confirmed,    // 配对成功
  failed,       // 配对失败
}

/// 配对结果
class PairingResult {
  final bool success;
  final String? miniprogramUserId;  // 小程序UnionID
  final String? errorMessage;

  PairingResult({required this.success, this.miniprogramUserId, this.errorMessage});
}

/// 与小程序配对服务
/// 电脑端生成二维码，小程序扫码授权
class PairingService {
  static const int _tokenLength = 32;
  static const Duration _pairingTimeout = Duration(minutes: 5);

  String? _currentToken;
  DateTime? _tokenExpiry;
  PairingState _state = PairingState.waiting;

  /// 生成配对二维码
  /// 返回二维码内容（URL或字符串）
  Future<String> generatePairingQRCode() async {
    _currentToken = _generateToken();
    _tokenExpiry = DateTime.now().add(_pairingTimeout);
    _state = PairingState.waiting;

    // 二维码内容包含token，用于小程序扫码
    final qrContent = jsonEncode({
      'action': 'pair',
      'token': _currentToken,
      'desktopId': Platform.localHostname,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    return qrContent;
  }

  /// 检查配对状态
  PairingState get state => _state;

  /// 处理小程序扫码回调
  Future<PairingResult> handleScanCallback(String token, String unionId) async {
    if (token != _currentToken) {
      return PairingResult(success: false, errorMessage: 'Token不匹配');
    }

    if (DateTime.now().isAfter(_tokenExpiry!)) {
      return PairingResult(success: false, errorMessage: '配对已过期');
    }

    // 调用后端验证token并绑定
    try {
      final response = await http.post(
        Uri.parse('https://api.example.com/pairing/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'unionId': unionId}),
      );

      if (response.statusCode == 200) {
        _state = PairingState.confirmed;
        return PairingResult(success: true, miniprogramUserId: unionId);
      } else {
        _state = PairingState.failed;
        return PairingResult(success: false, errorMessage: '配对失败');
      }
    } catch (e) {
      _state = PairingState.failed;
      return PairingResult(success: false, errorMessage: e.toString());
    }
  }

  /// 发送设备数据到小程序
  Future<bool> sendDeviceDataToMiniprogram(String unionId, Map<String, dynamic> deviceData) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.example.com/pairing/device-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'unionId': unionId,
          'deviceData': deviceData,
          'desktopId': Platform.localHostname,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(_tokenLength, (_) => chars[random.nextInt(chars.length)]).join();
  }
}