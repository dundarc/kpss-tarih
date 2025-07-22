import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // Android'e özel
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'; // iOS'a özel

// Google Play/App Store'da tanımladığınız ürün ID'leri
const String aylikAbonelikId = 'aylik_reklamsiz_39_99tl';
const String yillikAbonelikId = 'yillik_reklamsiz_299_99tl';
const String omurBoyuId = 'omur_boyu_reklamsiz_749_99tl';
const String elmas100Id = '100_elmas_49_99tl';
const String elmas250Id = '250_elmas_99_99tl';
const String elmas500Id = '500_elmas_179_99tl';

// Tüm ürün ID'lerini içeren bir Set
final Set<String> _kProductIds = {
  aylikAbonelikId,
  yillikAbonelikId,
  omurBoyuId,
  elmas100Id,
  elmas250Id,
  elmas500Id,
};

enum PurchaseStatusEnum {
  loading,
  available,
  unavailable,
  purchasing,
  purchased,
  restored,
  error,
  canceled,
}

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  PurchaseStatusEnum _status = PurchaseStatusEnum.loading;
  PurchaseStatusEnum get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Satın alma başarılarını işlemek için bir callback
  final Function(PurchaseDetails) onPurchaseSuccessCallback;
  // Satın alma hatalarını işlemek için bir callback
  final Function(String) onPurchaseErrorCallback;

  PurchaseService({
    required this.onPurchaseSuccessCallback,
    required this.onPurchaseErrorCallback,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    _status = PurchaseStatusEnum.loading;
    notifyListeners();

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
        _status = PurchaseStatusEnum.unavailable;
        notifyListeners();
      },
      onError: (error) {
        _status = PurchaseStatusEnum.error;
        _errorMessage = 'Satın alma akışında bir hata oluştu: $error';
        onPurchaseErrorCallback(_errorMessage!);
        notifyListeners();
      },
    );

    await _checkStoreAvailability();
    await _loadProducts();
    await _iap.restorePurchases(); // Uygulama başlatıldığında geçmiş satın almaları geri yükle
  }

  Future<void> _checkStoreAvailability() async {
    final bool available = await _iap.isAvailable();
    if (available) {
      _status = PurchaseStatusEnum.available;
    } else {
      _status = PurchaseStatusEnum.unavailable;
      _errorMessage = 'Uygulama içi satın alma hizmeti şu anda kullanılamıyor.';
      onPurchaseErrorCallback(_errorMessage!);
    }
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    if (_status != PurchaseStatusEnum.available) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
    if (response.error != null) {
      _status = PurchaseStatusEnum.error;
      _errorMessage = 'Ürün detayları çekilirken hata: ${response.error!.message}';
      onPurchaseErrorCallback(_errorMessage!);
    } else {
      _products = response.productDetails;
      if (_products.isEmpty) {
        _status = PurchaseStatusEnum.unavailable;
        _errorMessage = 'Mağazada ürün bulunamadı.';
        onPurchaseErrorCallback(_errorMessage!);
      } else {
        _status = PurchaseStatusEnum.available; // Ürünler yüklendi, mağaza kullanılabilir
      }
    }
    notifyListeners();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _status = PurchaseStatusEnum.purchasing;
        notifyListeners();
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        _handlePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        _handleRestore(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _status = PurchaseStatusEnum.error;
        _errorMessage = purchaseDetails.error?.message ?? 'Bilinmeyen bir hata oluştu.';
        onPurchaseErrorCallback(_errorMessage!);
        notifyListeners();
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _status = PurchaseStatusEnum.canceled;
        _errorMessage = 'Satın alma işlemi iptal edildi.';
        onPurchaseErrorCallback(_errorMessage!);
        notifyListeners();
      }
    }
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
    _status = PurchaseStatusEnum.purchased;
    onPurchaseSuccessCallback(purchaseDetails); // Başarı callback'ini çağır
    notifyListeners();
  }

  void _handleRestore(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
    _status = PurchaseStatusEnum.restored;
    onPurchaseSuccessCallback(purchaseDetails); // Geri yükleme callback'ini çağır
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    if (_status != PurchaseStatusEnum.available) {
      onPurchaseErrorCallback('Mağaza şu anda satın alma için uygun değil.');
      return;
    }

    _status = PurchaseStatusEnum.purchasing;
    notifyListeners();

    final PurchaseParam purchaseParam;

    if (productDetails is GooglePlayProductDetails) {
      // Android için GooglePlayPurchaseParam kullanın
      purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails);
    } else if (productDetails is AppStoreProductDetails) {
      // iOS için AppStorePurchaseParam kullanın
      purchaseParam = AppStorePurchaseParam(productDetails: productDetails);
    } else {
      // Diğer platformlar veya bilinmeyen durumlar için varsayılan PurchaseParam
      purchaseParam = PurchaseParam(productDetails: productDetails);
    }

    if (productDetails.id.contains('elmas')) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    _status = PurchaseStatusEnum.loading; // Geri yükleme sırasında yükleniyor durumu
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // Restore işlemi _listenToPurchaseUpdated tarafından işlenecektir.
      // Burada sadece başarılı bir şekilde tetiklendiğini belirtiyoruz.
      print('Geçmiş satın alımlar geri yükleniyor...');
    } catch (e) {
      _status = PurchaseStatusEnum.error;
      _errorMessage = 'Satın alımları geri yüklerken hata: $e';
      onPurchaseErrorCallback(_errorMessage!);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
