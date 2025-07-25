import 'dart:async'; // Zamanlayıcı (Timer) ve Stream için
import 'package:flutter/material.dart'; // ChangeNotifier için
import 'package:in_app_purchase/in_app_purchase.dart'; // Uygulama içi satın alma ana paketi
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // Android'e özel satın alma detayları
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'; // iOS'a özel satın alma detayları

// Google Play/App Store'da tanımladığınız ürün ID'leri
// Bu ID'ler, mağazalardaki ürünlerinizle birebir aynı olmalıdır.
const String aylikAbonelikId = 'aylik_reklamsiz_39_99tl';
const String yillikAbonelikId = 'yillik_reklamsiz_299_99tl';
const String omurBoyuId = 'omur_boyu_reklamsiz_749_90tl'; // Fiyat güncellendi
const String elmas100Id = '100_elmas_49_99tl';
const String elmas250Id = '250_elmas_99_99tl';
const String elmas500Id = '500_elmas_179_99tl';

// Tüm ürün ID'lerini içeren bir Set (ürün detaylarını sorgulamak için kullanılır)
final Set<String> _kProductIds = {
  aylikAbonelikId,
  yillikAbonelikId,
  omurBoyuId,
  elmas100Id,
  elmas250Id,
  elmas500Id,
};

// Satın alma işleminin farklı durumlarını temsil eden enum
enum PurchaseStatusEnum {
  loading, // Yükleniyor
  available, // Mağaza kullanılabilir
  unavailable, // Mağaza kullanılamaz
  purchasing, // Satın alma işlemi devam ediyor
  purchased, // Başarıyla satın alındı
  restored, // Geri yüklendi (önceki satın alma)
  error, // Hata oluştu
  canceled, // İptal edildi
}

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance; // InAppPurchase örneği
  StreamSubscription<List<PurchaseDetails>>? _subscription; // Satın alma akışını dinlemek için

  List<ProductDetails> _products = []; // Mağazadan çekilen ürün detayları
  List<ProductDetails> get products => _products; // Ürünlere dışarıdan erişim

  PurchaseStatusEnum _status = PurchaseStatusEnum.loading; // Mevcut satın alma durumu
  PurchaseStatusEnum get status => _status; // Duruma dışarıdan erişim

  String? _errorMessage; // Hata mesajı
  String? get errorMessage => _errorMessage; // Hata mesajına dışarıdan erişim

  // Satın alma başarılarını işlemek için bir callback fonksiyonu
  final Function(PurchaseDetails) onPurchaseSuccessCallback;
  // Satın alma hatalarını işlemek için bir callback fonksiyonu
  final Function(String) onPurchaseErrorCallback;

  // Kurucu metot: Callback'leri alır ve başlatma işlemini tetikler
  PurchaseService({
    required this.onPurchaseSuccessCallback,
    required this.onPurchaseErrorCallback,
  }) {
    _initialize();
  }

  // Servisi başlatır: Satın alma akışını dinler, mağaza uygunluğunu kontrol eder ve ürünleri yükler.
  Future<void> _initialize() async {
    _status = PurchaseStatusEnum.loading; // Durumu yükleniyor olarak ayarla
    notifyListeners(); // Dinleyicilere bildir

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream; // Satın alma akışını al
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated, // Satın alma güncellemelerini dinleyen metot
      onDone: () {
        _subscription?.cancel(); // Akış bittiğinde aboneliği iptal et
        _status = PurchaseStatusEnum.unavailable; // Durumu kullanılamaz olarak ayarla
        notifyListeners();
      },
      onError: (error) {
        _status = PurchaseStatusEnum.error; // Hata durumunda durumu hata olarak ayarla
        _errorMessage = 'Satın alma akışında bir hata oluştu: $error';
        onPurchaseErrorCallback(_errorMessage!); // Hata callback'ini çağır
        notifyListeners();
      },
    );

    await _checkStoreAvailability(); // Mağaza uygunluğunu kontrol et
    await _loadProducts(); // Ürünleri yükle
    await _iap.restorePurchases(); // Uygulama başlatıldığında geçmiş satın almaları geri yükle
  }

  // Uygulama içi satın alma hizmetinin kullanılabilirliğini kontrol eder
  Future<void> _checkStoreAvailability() async {
    final bool available = await _iap.isAvailable();
    if (available) {
      _status = PurchaseStatusEnum.available; // Kullanılabilir
    } else {
      _status = PurchaseStatusEnum.unavailable; // Kullanılamaz
      _errorMessage = 'Uygulama içi satın alma hizmeti şu anda kullanılamıyor.';
      onPurchaseErrorCallback(_errorMessage!);
    }
    notifyListeners();
  }

  // Ürün detaylarını mağazadan sorgular ve yükler
  Future<void> _loadProducts() async {
    if (_status != PurchaseStatusEnum.available) return; // Mağaza uygun değilse işlem yapma

    final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds); // Ürün ID'leriyle sorgula
    if (response.error != null) {
      _status = PurchaseStatusEnum.error;
      _errorMessage = 'Ürün detayları çekilirken hata: ${response.error!.message}';
      onPurchaseErrorCallback(_errorMessage!);
    } else {
      _products = response.productDetails; // Ürün detaylarını kaydet
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

  // Satın alma akışındaki güncellemeleri dinler ve işler
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _status = PurchaseStatusEnum.purchasing; // Beklemede: satın alma devam ediyor
        notifyListeners();
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        _handlePurchase(purchaseDetails); // Başarıyla satın alındı
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        _handleRestore(purchaseDetails); // Geri yüklendi
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _status = PurchaseStatusEnum.error; // Hata oluştu
        // Hata mesajını daha detaylı logla
        String detailedErrorMessage = purchaseDetails.error?.message ?? 'Bilinmeyen bir hata oluştu.';
        // purchaseDetails.error bir PurchaseError nesnesi olduğu için
        // message ve code özelliklerine doğrudan erişebiliriz.
        if (purchaseDetails.error != null) {
          detailedErrorMessage = 'Hata Kodu: ${purchaseDetails.error!.code}, Mesaj: ${purchaseDetails.error!.message}';
          // Eğer hata detaylarında daha fazla bilgi varsa (örn: details alanı), onu ekleyebiliriz.
          if (purchaseDetails.error!.details != null && purchaseDetails.error!.details!.isNotEmpty) {
            detailedErrorMessage += ', Detaylar: ${purchaseDetails.error!.details}';
          }
        }
        _errorMessage = detailedErrorMessage;
        onPurchaseErrorCallback(_errorMessage!);
        notifyListeners();
        // Beklemedeki satın alma işlemini tamamla (hata olsa bile)
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _status = PurchaseStatusEnum.canceled; // İptal edildi
        // Kullanıcı iptal ettiğinde daha spesifik bir mesaj gönder
        _errorMessage = 'Satın alma işlemi kullanıcı tarafından iptal edildi.';
        onPurchaseErrorCallback(_errorMessage!);
        notifyListeners();
      }
    }
  }

  // Başarılı satın alma işlemlerini işler
  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    // Beklemedeki satın alma işlemini tamamla (genellikle tüketilebilir ürünler için)
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
    _status = PurchaseStatusEnum.purchased; // Durumu satın alındı olarak ayarla
    onPurchaseSuccessCallback(purchaseDetails); // Başarı callback'ini çağır
    notifyListeners();
  }

  // Geri yüklenen satın alma işlemlerini işler
  void _handleRestore(PurchaseDetails purchaseDetails) async {
    // Beklemedeki geri yükleme işlemini tamamla
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
    _status = PurchaseStatusEnum.restored; // Durumu geri yüklendi olarak ayarla
    onPurchaseSuccessCallback(purchaseDetails); // Geri yükleme callback'ini çağır
    notifyListeners();
  }

  // Bir ürünü satın alma işlemini başlatır
  Future<void> buyProduct(ProductDetails productDetails) async {
    if (_status != PurchaseStatusEnum.available) {
      onPurchaseErrorCallback('Mağaza şu anda satın alma için uygun değil.');
      return;
    }

    _status = PurchaseStatusEnum.purchasing; // Durumu satın alma olarak ayarla
    notifyListeners();

    final PurchaseParam purchaseParam;

    // Platforma özel satın alma parametrelerini oluştur
    if (productDetails is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails);
    } else if (productDetails is AppStoreProductDetails) {
      purchaseParam = AppStorePurchaseParam(productDetails: productDetails);
    } else {
      purchaseParam = PurchaseParam(productDetails: productDetails);
    }

    // Ürünün tüketilebilir (elmas gibi) veya tüketilemez (abonelik gibi) olup olmadığına göre farklı metot çağır
    if (productDetails.id.contains('elmas')) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // Geçmiş satın almaları geri yüklemeyi tetikler
  Future<void> restorePurchases() async {
    _status = PurchaseStatusEnum.loading; // Geri yükleme sırasında yükleniyor durumu
    _errorMessage = null; // Hata mesajını temizle
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

  // Yeni metot: Mağazayı tamamen yeniden başlatır
  Future<void> reinitializeStore() async {
    _status = PurchaseStatusEnum.loading;
    _errorMessage = null; // Hata mesajını temizle
    notifyListeners();
    await _initialize(); // _initialize metodu zaten tüm başlatma adımlarını içeriyor
  }


  @override
  void dispose() {
    _subscription?.cancel(); // Aboneliği iptal et
    super.dispose();
  }
}
