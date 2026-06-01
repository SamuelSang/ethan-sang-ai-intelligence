import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_record.dart';
import '../models/iap_product.dart';

/// Repository for persisting purchase state locally via SharedPreferences
class PurchaseRepository {
  static const String _purchaseRecordsKey = 'purchase_records';
  static const String _isPurchasedKey = 'is_premium_purchased';
  static const String _productIdKey = 'premium_product_id';

  final SharedPreferences _prefs;

  PurchaseRepository(this._prefs);

  /// Check if user has an active purchase (non-consumable)
  bool hasActivePurchase() {
    return _prefs.getBool(_isPurchasedKey) ?? false;
  }

  /// Get the stored product ID for premium
  String? getProductId() {
    return _prefs.getString(_productIdKey);
  }

  /// Save purchase success locally after server verification
  Future<void> savePurchase(PurchaseRecord record) async {
    // Save premium status
    await _prefs.setBool(_isPurchasedKey, true);
    await _prefs.setString(_productIdKey, record.productId);

    // Save detailed record
    final records = await _getRecords();
    final index = records.indexWhere((r) => r.productId == record.productId);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _saveRecords(records);
  }

  /// Mark purchase as verified after server confirmation
  Future<void> markAsVerified(String productId) async {
    final records = await _getRecords();
    final index = records.indexWhere((r) => r.productId == productId);
    if (index >= 0) {
      records[index] = records[index].copyWith(verified: true);
      await _saveRecords(records);
    }
  }

  /// Get all stored purchase records
  Future<List<PurchaseRecord>> getPurchaseRecords() async {
    return _getRecords();
  }

  /// Get purchase record by product ID
  Future<PurchaseRecord?> getPurchaseRecord(String productId) async {
    final records = await _getRecords();
    try {
      return records.firstWhere((r) => r.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Clear all purchase data (for testing or restore)
  Future<void> clearPurchases() async {
    await _prefs.remove(_isPurchasedKey);
    await _prefs.remove(_productIdKey);
    await _prefs.remove(_purchaseRecordsKey);
  }

  /// Restore purchase from stored records
  Future<PurchaseRecord?> restorePurchase(String productId) async {
    final records = await _getRecords();
    try {
      return records.firstWhere((r) => r.productId == productId);
    } catch (_) {
      return null;
    }
  }

  Future<List<PurchaseRecord>> _getRecords() async {
    final jsonString = _prefs.getString(_purchaseRecordsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => PurchaseRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveRecords(List<PurchaseRecord> records) async {
    final jsonList = records.map((r) => r.toJson()).toList();
    await _prefs.setString(_purchaseRecordsKey, jsonEncode(jsonList));
  }
}