import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/purchase_record.dart';

/// Result of server-side receipt verification
class VerifyResult {
  final bool success;
  final String message;
  final PurchaseRecord? record;

  const VerifyResult({
    required this.success,
    required this.message,
    this.record,
  });
}

/// Service for verifying purchase receipts with backend server
class ReceiptVerifier {
  // Use local backend URL as specified
  static const String _baseUrl = 'http://127.0.0.1:8000';

  late final Dio _dio;

  ReceiptVerifier() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  /// Verify purchase receipt with backend
  /// [purchaseData] contains the purchase details from InAppPurchase
  Future<VerifyResult> verifyReceipt({
    required String productId,
    required String orderId,
    required String purchaseToken,
    required DateTime purchaseDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/purchase/verify',
        data: {
          'product_id': productId,
          'order_id': orderId,
          'purchase_token': purchaseToken,
          'purchase_date': purchaseDate.toIso8601String(),
          'platform': _getPlatform(),
        },
      );

      final data = response.data;
      if (data == null) {
        return const VerifyResult(
          success: false,
          message: 'Server returned no data',
        );
      }

      if (data['success'] == true) {
        // Server verified the purchase, create record
        final record = PurchaseRecord(
          productId: productId,
          orderId: orderId,
          purchaseDate: purchaseDate,
          purchaseToken: purchaseToken,
          verified: true,
        );

        return VerifyResult(
          success: true,
          message: data['message'] as String? ?? 'Purchase verified',
          record: record,
        );
      } else {
        return VerifyResult(
          success: false,
          message: data['message'] as String? ?? 'Verification failed',
        );
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        message = '无法连接到验证服务器';
      } else {
        message = e.message ?? '验证请求失败';
      }
      return VerifyResult(success: false, message: message);
    } catch (e) {
      return VerifyResult(success: false, message: '验证异常: $e');
    }
  }

  /// Check if purchase is still valid on server (for subscriptions)
  Future<bool> checkSubscriptionStatus(String purchaseToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/purchase/status',
        queryParameters: {'token': purchaseToken},
      );

      return response.data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  String _getPlatform() {
    // Detected at build time via dart:io
    // Default to iOS, actual implementation would check Platform
    return 'ios';
  }
}