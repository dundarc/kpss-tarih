import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // Android'e özel

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

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Bu callback, satın alma başarılı olduğunda veya geri yüklendiğinde dışarıya bilgi verir
  final Function(PurchaseDetails) onPurchaseSuccess;
  final Function(String) onPurchaseError; // Hata durumunda bilgi vermek için

  PurchaseService({required this.onPurchaseSuccess, required this.onPurchaseError});

  Future<void> init() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      print('In-App Purchase Stream Error: $error');
      onPurchaseError('Satın alma akışında bir hata oluştu: $error');
    });

    // Mağaza kullanılabilirliğini kontrol et
    final bool available = await _iap.isAvailable();
    if (!available) {
      print('Mağaza erişilebilir değil.');
      onPurchaseError('Uygulama içi satın alma hizmeti şu anda kullanılamıyor.');
      return;
    }

    // Geçmiş satın almaları geri yükle (özellikle kalıcı ürünler ve abonelikler için)
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Satın alma işlemi beklemede
        print('Satın alma beklemede: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // Satın alma başarılı veya geri yüklendi
        print('Satın alma başarılı/geri yüklendi: ${purchaseDetails.productID}');
        onPurchaseSuccess(purchaseDetails);

        // Tüketilebilir ürünler için tamamla, kalıcı ürünler için de tamamla
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Hata yönetimi
        print('Satın alma hatası: ${purchaseDetails.productID} - ${purchaseDetails.error?.message}');
        onPurchaseError(purchaseDetails.error?.message ?? 'Bilinmeyen bir hata oluştu.');
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails); // Hatada da tamamla ki tekrar denenebilsin
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print('Satın alma iptal edildi: ${purchaseDetails.productID}');
        onPurchaseError('Satın alma işlemi iptal edildi.');
      }
    }
  }

  // Ürün detaylarını getir
  Future<List<ProductDetails>> getProductDetails() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
    if (response.error != null) {
      print('Ürün detayları çekilirken hata: ${response.error!.message}');
      onPurchaseError('Ürün bilgileri alınırken bir hata oluştu: ${response.error!.message}');
      return [];
    }
    return response.productDetails;
  }

  // Satın alma işlemini başlat
  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam;
    if (productDetails.id.contains('elmas')) { // Tüketilebilir ürünler
      purchaseParam = PurchaseParam(productDetails: productDetails);
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else { // Kalıcı ürünler (abonelikler)
      purchaseParam = PurchaseParam(productDetails: productDetails);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // Geçmiş satın almaları geri yükle
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      print('Geçmiş satın alımlar geri yükleniyor...');
    } catch (e) {
      print('Satın alımları geri yüklerken hata: $e');
      onPurchaseError('Satın alımları geri yüklerken bir hata oluştu: $e');
    }
  }
}
