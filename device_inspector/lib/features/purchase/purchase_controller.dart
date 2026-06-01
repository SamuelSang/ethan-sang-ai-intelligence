import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/iap_product.dart';
import '../../models/purchase_record.dart';
import '../../services/iap_service.dart';
import '../../services/purchase_repository.dart';
import '../../services/receipt_verifier.dart';

/// Purchase UI State
enum PurchaseStatus {
  initial,
  loading,
  productsLoaded,
  purchasing,
  verifying,
  success,
  error,
}

@immutable
class PurchaseState {
  final PurchaseStatus status;
  final List<IAPProduct> products;
  final IAPProduct? selectedProduct;
  final bool isPurchased;
  final String? errorMessage;
  final PurchaseRecord? purchaseRecord;

  const PurchaseState({
    this.status = PurchaseStatus.initial,
    this.products = const [],
    this.selectedProduct,
    this.isPurchased = false,
    this.errorMessage,
    this.purchaseRecord,
  });

  PurchaseState copyWith({
    PurchaseStatus? status,
    List<IAPProduct>? products,
    IAPProduct? selectedProduct,
    bool? isPurchased,
    String? errorMessage,
    PurchaseRecord? purchaseRecord,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isPurchased: isPurchased ?? this.isPurchased,
      errorMessage: errorMessage,
      purchaseRecord: purchaseRecord ?? this.purchaseRecord,
    );
  }
}

/// Riverpod StateNotifier for managing purchase state
class PurchaseController extends StateNotifier<PurchaseState> {
  final IAPService _iapService;
  final PurchaseRepository _repository;
  final ReceiptVerifier _verifier;

  PurchaseController({
    required IAPService iapService,
    required PurchaseRepository repository,
    required ReceiptVerifier verifier,
  })  : _iapService = iapService,
        _repository = repository,
        _verifier = verifier,
        super(const PurchaseState()) {
    _init();
  }

  void _init() {
    // Check local purchase status first
    _checkLocalPurchaseStatus();
    // Then start listening for purchases
    _startListening();
  }

  void _checkLocalPurchaseStatus() {
    final hasPurchase = _repository.hasActivePurchase();
    if (hasPurchase) {
      state = state.copyWith(
        status: PurchaseStatus.productsLoaded,
        isPurchased: true,
      );
    }
  }

  void _startListening() {
    _iapService.startListening(
      onPurchaseComplete: _handlePurchaseComplete,
      onPurchaseError: _handlePurchaseError,
    );
  }

  /// Load available products from store
  Future<void> loadProducts() async {
    state = state.copyWith(status: PurchaseStatus.loading);

    try {
      final available = await _iapService.isAvailable();
      if (!available) {
        state = state.copyWith(
          status: PurchaseStatus.error,
          errorMessage: '内购功能不可用，请检查设备设置',
        );
        return;
      }

      final products = await _iapService.queryProducts();
      state = state.copyWith(
        status: PurchaseStatus.productsLoaded,
        products: products,
        selectedProduct: products.isNotEmpty ? products.first : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '加载产品失败: $e',
      );
    }
  }

  /// Select a product for purchase
  void selectProduct(IAPProduct product) {
    state = state.copyWith(selectedProduct: product);
  }

  /// Initiate 1元买断制 purchase flow
  Future<void> purchaseBuyout() async {
    state = state.copyWith(status: PurchaseStatus.purchasing);

    try {
      final success = await _iapService.buyProduct(IAPProduct(
        id: 'device_inspector_buyout',
        title: 'DeviceInspector Pro 一元买断',
        description: '终身解锁全部高级功能',
        price: 1.0,
        priceString: '¥1.00',
        type: ProductType.nonConsumable,
      ));
      if (!success) {
        state = state.copyWith(
          status: PurchaseStatus.error,
          errorMessage: '购买发起失败',
        );
      }
      // Purchase result will come through the stream
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '购买异常: $e',
      );
    }
  }

  /// Initiate purchase for selected product (legacy method)
  Future<void> purchase() async {
    final product = state.selectedProduct;
    if (product == null) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '请先选择产品',
      );
      return;
    }

    state = state.copyWith(status: PurchaseStatus.purchasing);

    try {
      final success = await _iapService.buyProduct(product);
      if (!success) {
        state = state.copyWith(
          status: PurchaseStatus.error,
          errorMessage: '购买发起失败',
        );
      }
      // Purchase result will come through the stream
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '购买异常: $e',
      );
    }
  }

  /// Handle purchase completion from stream
  Future<void> _handlePurchaseComplete(PurchaseDetails purchase) async {
    if (_iapService.isPurchaseCompleted(purchase)) return;

    state = state.copyWith(status: PurchaseStatus.verifying);

    try {
      // Verify receipt with server
      final result = await _verifier.verifyReceipt(
        productId: purchase.productID,
        orderId: purchase.purchaseID ?? '',
        purchaseToken: purchase.verificationData.serverVerificationData,
        purchaseDate: purchase.purchaseDate,
      );

      if (result.success && result.record != null) {
        // Save to local storage
        await _repository.savePurchase(result.record!);
        await _iapService.completePurchase(purchase);

        state = state.copyWith(
          status: PurchaseStatus.success,
          isPurchased: true,
          purchaseRecord: result.record,
        );
      } else {
        state = state.copyWith(
          status: PurchaseStatus.error,
          errorMessage: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '验证失败: $e',
      );
    }
  }

  void _handlePurchaseError(String error) {
    state = state.copyWith(
      status: PurchaseStatus.error,
      errorMessage: error,
    );
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    state = state.copyWith(status: PurchaseStatus.loading);

    try {
      final purchases = await _iapService.restorePurchases();

      for (final purchase in purchases) {
        if (!_iapService.isPurchaseCompleted(purchase)) {
          await _handlePurchaseComplete(purchase);
        }
      }

      // If no purchases restored, show message
      if (state.status != PurchaseStatus.success) {
        state = state.copyWith(
          status: PurchaseStatus.productsLoaded,
          errorMessage: '没有找到可恢复的购买',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: '恢复购买失败: $e',
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(
      status: state.products.isEmpty
          ? PurchaseStatus.initial
          : PurchaseStatus.productsLoaded,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _iapService.stopListening();
    super.dispose();
  }
}