import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/iap_product.dart';
import '../models/purchase_record.dart';

/// Service wrapping InAppPurchase plugin with purchase stream listening
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Stream of purchase updates (for listening to new purchases/ restored purchases)
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  /// Available product ID for 1元买断制
  static const String _buyoutProductId = 'device_inspector_buyout';

  /// All product IDs (for backwards compatibility)
  static const List<String> _productIds = [
    _buyoutProductId,
  ];

  /// Check if in-app purchases are available on this device
  Future<bool> isAvailable() async {
    return _iap.isAvailable();
  }

  /// Start listening to purchase updates from native layer
  void startListening({
    required Function(PurchaseDetails) onPurchaseComplete,
    required Function(String) onPurchaseError,
  }) {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseUpdatedStream.listen(
      (List<PurchaseDetails> purchases) {
        _purchaseController.add(purchases);

        for (final purchase in purchases) {
          if (purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased) {
            onPurchaseComplete(purchase);
          } else if (purchase.status == PurchaseStatus.error) {
            onPurchaseError(purchase.error?.message ?? 'Unknown purchase error');
          }
        }
      },
      onError: (error) {
        onPurchaseError('Stream error: $error');
      },
    );
  }

  /// Stop listening to purchase updates
  void stopListening() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  /// Query available products from store
  Future<List<IAPProduct>> queryProducts() async {
    final isAvailable = await this.isAvailable();
    if (!isAvailable) return [];

    final response = await _iap.queryProductDetails(_productIds.toSet());
    final products = <IAPProduct>[];

    for (final details in response.productDetails) {
      // Determine product type based on ID prefix/ suffix convention
      final type = _inferProductType(details.id);
      products.add(IAPProduct.fromProductDetails(details, type));
    }

    return products;
  }

  /// Initiate purchase flow for a product
  Future<bool> buyProduct(IAPProduct product) async {
    final isAvailable = await this.isAvailable();
    if (!isAvailable) return false;

    final productDetails = await _iap.queryProductDetails({product.id});
    if (productDetails.productDetails.isEmpty) return false;

    final purchaseParam = PurchaseParam(
      productDetails: productDetails.productDetails.first,
      applicationUserName: null,
    );

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore previous purchases (for non-consumables)
  Future<List<PurchaseDetails>> restorePurchases() async {
    final isAvailable = await this.isAvailable();
    if (!isAvailable) return [];

    try {
      final result = await _iap.restorePurchases();
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Complete a purchase after server verification succeeds
  Future<void> completePurchase(PurchaseDetails purchase) async {
    // Only complete purchased or restored purchases that aren't already completed
    final isCompleted = isPurchaseCompleted(purchase);
    if (!isCompleted &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored)) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Check if purchase was already completed
  bool isPurchaseCompleted(PurchaseDetails purchase) {
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored ||
        purchase.status == PurchaseStatus.canceled;
  }

  ProductType _inferProductType(String productId) {
    // Convention: subscription products have 'sub' or 'subscription' in ID
    if (productId.contains('sub') || productId.contains('subscription')) {
      return ProductType.subscription;
    }
    // Convention: consumable products have 'consumable' in ID
    if (productId.contains('consumable')) {
      return ProductType.consumable;
    }
    // Default to non-consumable
    return ProductType.nonConsumable;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _purchaseController.close();
  }
}

