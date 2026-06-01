/// Product type enum for different subscription/ purchase types
enum ProductType {
  /// Non-consumable: one-time purchase, persists forever
  nonConsumable,

  /// Consumable: can be purchased multiple times
  consumable,

  /// Auto-renewing subscription
  subscription,
}

/// IAP Product model representing an in-app purchase product
class IAPProduct {
  final String id;
  final String title;
  final String description;
  final double price; // in local currency
  final String priceString; // formatted price like "¥1.00"
  final ProductType type;
  final bool isAvailable;

  const IAPProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceString,
    required this.type,
    this.isAvailable = true,
  });

  factory IAPProduct.fromProductDetails(
    ProductDetails details,
    ProductType type,
  ) {
    return IAPProduct(
      id: details.id,
      title: details.title,
      description: details.description,
      price: details.priceAmount,
      priceString: details.priceCurrencyCode,
      type: type,
      isAvailable: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'priceString': priceString,
        'type': type.name,
        'isAvailable': isAvailable,
      };

  @override
  String toString() => 'IAPProduct(id: $id, title: $title, price: $priceString)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IAPProduct && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}