/// Record of a completed purchase stored locally
class PurchaseRecord {
  final String productId;
  final String orderId; // platform-specific order ID
  final DateTime purchaseDate;
  final DateTime? expirationDate;
  final String? purchaseToken;
  final bool verified; // server verification status

  const PurchaseRecord({
    required this.productId,
    required this.orderId,
    required this.purchaseDate,
    this.expirationDate,
    this.purchaseToken,
    this.verified = false,
  });

  bool get isActive {
    if (expirationDate == null) return true; // non-consumable has no expiry
    return DateTime.now().isBefore(expirationDate!);
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      productId: json['product_id'] as String,
      orderId: json['order_id'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      purchaseToken: json['purchase_token'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'order_id': orderId,
        'purchase_date': purchaseDate.toIso8601String(),
        'expiration_date': expirationDate?.toIso8601String(),
        'purchase_token': purchaseToken,
        'verified': verified,
      };

  PurchaseRecord copyWith({
    String? productId,
    String? orderId,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? purchaseToken,
    bool? verified,
  }) {
    return PurchaseRecord(
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      verified: verified ?? this.verified,
    );
  }

  @override
  String toString() =>
      'PurchaseRecord(productId: $productId, orderId: $orderId, verified: $verified)';
}