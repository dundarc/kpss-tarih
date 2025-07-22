import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

// Google Play/App Store'da tanımladığınız ürün ID'leri
const String _aylikAbonelikId = 'aylik_reklamsiz';
const String _yillikAbonelikId = 'yillik_reklamsiz';
const String _omurBoyuId = 'omur_boyu_reklamsiz';
const String _elmas100Id = '100_elmas';

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Bu callback, satın alma başarılı olduğunda state'i güncellemeli
  final Function(PurchaseDetails) onPurchaseSuccess;

  PurchaseService({required this.onPurchaseSuccess});

  void init() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      // Handle error here.
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // Satın alma başarılı veya geri yüklendi
        onPurchaseSuccess(purchaseDetails);

        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Hata yönetimi
      }
    }
  }

  Future<void> buyProduct(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      // Mağaza erişilebilir değil
      return;
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      // Ürün bulunamadı
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    if (_isConsumable(productId)) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  bool _isConsumable(String id) {
    return id.contains('elmas');
  }
}