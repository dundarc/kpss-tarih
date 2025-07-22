import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/main.dart'; // navigatorKey'e erişmek için eklendi
import 'dart:async'; // Timer için eklendi
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob için eklendi
import 'package:in_app_purchase/in_app_purchase.dart'; // ProductDetails için eklendi
// in_app_purchase_android artık doğrudan kullanılmadığı için kaldırılabilir
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart'; // Tüm provider'lar için eklendi
import 'package:kpss_tarih_app/data/services/purchase_service.dart'; // PurchaseStatusEnum için

// Bu ID'ler, Google Play Console ve App Store Connect'te oluşturduğunuz
// ürün ID'leri ile birebir aynı olmalıdır.
// Fiyatlar Türkiye'deki ekonomik şartlar göz önünde bulundurularak güncellenmiştir.
const String aylikAbonelikId = 'aylik_reklamsiz_39_99tl'; // Örnek: 20 TL yerine 39.99 TL
const String yillikAbonelikId = 'yillik_reklamsiz_299_99tl'; // Örnek: 200 TL yerine 299.99 TL
const String omurBoyuId = 'omur_boyu_reklamsiz_749_99tl'; // Örnek: 499 TL yerine 749.99 TL
const String elmas100Id = '100_elmas_49_99tl'; // Örnek: 150 TL yerine 49.99 TL
const String elmas250Id = '250_elmas_99_99tl'; // Örnek: 250 TL yerine 99.99 TL
const String elmas500Id = '500_elmas_179_99tl'; // Örnek: 400 TL yerine 179.99 TL

/// ProductDetails arayüzünü uygulayan basit bir yer tutucu sınıfı.
/// Gerçek ürün detayları yüklenemediğinde veya test ortamlarında kullanılır.
class _MockProductDetails implements ProductDetails {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String price;
  @override
  final double rawPrice;
  @override
  final String currencyCode;

  // ProductDetails soyut sınıfının tüm üyelerini implement etmeliyiz.
  // Çoğu durumda, yer tutucu için boş veya varsayılan değerler yeterlidir.
  @override
  final String currencySymbol;
  @override
  final String? subscriptionPeriod;
  @override
  final String? introductoryPrice;
  @override
  final int? introductoryPriceAmountMicros;
  @override
  final String? introductoryPriceCycles;
  @override
  final String? introductoryPricePeriod;
  @override
  final String? freeTrialPeriod;
  @override
  final double? originalPriceAmountMicros;
  @override
  final String? originalPrice;

  _MockProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.currencySymbol = '₺', // Varsayılan sembol
    this.subscriptionPeriod,
    this.introductoryPrice,
    this.introductoryPriceAmountMicros,
    this.introductoryPriceCycles,
    this.introductoryPricePeriod,
    this.freeTrialPeriod,
    this.originalPriceAmountMicros,
    this.originalPrice,
  });
}


class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  // Satın alma işlemini tetikleyecek fonksiyon
  void _buyProduct(BuildContext context, WidgetRef ref, ProductDetails productDetails) async {
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.buyProduct(productDetails);
  }

  // Satın alma onay pop-up'ını gösteren fonksiyon
  void _showPurchaseConfirmationPopup(BuildContext context, WidgetRef ref, ProductDetails productDetails, String title, String price, String description) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  '$title Satın Alma Onayı',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${description}\nFiyat: ${price}',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Popup'ı kapat
                      _buyProduct(context, ref, productDetails); // Satın alma işlemini başlat
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      'Şimdi Satın Al',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Popup'ı kapat
                  },
                  child: Text(
                    'İptal',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // PurchaseService'in durumunu ve ürünlerini dinle
    final purchaseService = ref.watch(purchaseServiceProvider);
    final products = purchaseService.products;
    final purchaseStatus = purchaseService.status;
    final errorMessage = purchaseService.errorMessage;

    // Ürünler yüklenirken veya hata durumunda gösterilecek UI
    if (purchaseStatus == PurchaseStatusEnum.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (purchaseStatus == PurchaseStatusEnum.error || purchaseStatus == PurchaseStatusEnum.unavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Mağaza Yüklenemedi',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Yeniden yüklemeyi tetikle
                  purchaseService.restorePurchases(); // Veya doğrudan _initialize() çağrılabilir
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    } else if (purchaseStatus == PurchaseStatusEnum.purchasing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Satın alma işlemi devam ediyor...'),
          ],
        ),
      );
    }

    // Ürünler başarıyla yüklendiğinde ve mağaza kullanılabilir olduğunda
    // Ürünleri bulmak için firstWhere kullanırken, orElse'e _MockProductDetails tipinde bir nesne döndürüyoruz.
    final aylikProduct = products.firstWhere((p) => p.id == aylikAbonelikId, orElse: () => _createPlaceholderProduct(aylikAbonelikId, 'Aylık Abonelik', '39.99 TL'));
    final yillikProduct = products.firstWhere((p) => p.id == yillikAbonelikId, orElse: () => _createPlaceholderProduct(yillikAbonelikId, 'Yıllık Abonelik', '299.99 TL'));
    final omurBoyuProduct = products.firstWhere((p) => p.id == omurBoyuId, orElse: () => _createPlaceholderProduct(omurBoyuId, 'Ömür Boyu Premium', '749.99 TL'));
    final elmas100Product = products.firstWhere((p) => p.id == elmas100Id, orElse: () => _createPlaceholderProduct(elmas100Id, '100 Elmas', '49.99 TL'));
    final elmas250Product = products.firstWhere((p) => p.id == elmas250Id, orElse: () => _createPlaceholderProduct(elmas250Id, '250 Elmas', '99.99 TL'));
    final elmas500Product = products.firstWhere((p) => p.id == elmas500Id, orElse: () => _createPlaceholderProduct(elmas500Id, '500 Elmas', '179.99 TL'));


    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Premium Abonelik Bölümü
          Text(
            'Reklamsız Deneyim',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium\'a geçerek reklamsız bir şekilde tüm konu anlatımlarına erişin ve gelişiminize odaklanın.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _SubscriptionCard(
                key: ValueKey(aylikProduct.id), // Benzersiz anahtar eklendi
                title: aylikProduct.title,
                price: aylikProduct.price,
                description: 'Her ay yenilenir.',
                color: Colors.teal,
                icon: Icons.calendar_month,
                onTap: () => _showPurchaseConfirmationPopup(context, ref, aylikProduct, aylikProduct.title, aylikProduct.price, 'Her ay otomatik olarak yenilenir. Reklamsız deneyim sunar.'),
              ),
              _SubscriptionCard(
                key: ValueKey(yillikProduct.id), // Benzersiz anahtar eklendi
                title: yillikProduct.title,
                price: yillikProduct.price,
                description: 'Yıllık öde, tasarruf et!',
                color: Colors.orange,
                isPopular: true,
                icon: Icons.star, // Güncellendi
                onTap: () => _showPurchaseConfirmationPopup(context, ref, yillikProduct, yillikProduct.title, yillikProduct.price, 'Yıllık ödeme ile daha uygun fiyata reklamsız deneyim.'),
              ),
              _SubscriptionCard(
                key: ValueKey(omurBoyuProduct.id), // Benzersiz anahtar eklendi
                title: omurBoyuProduct.title,
                price: omurBoyuProduct.price,
                description: 'Tek sefer öde, sonsuza dek kullan.',
                color: Colors.purple,
                icon: Icons.rocket_launch,
                onTap: () => _showPurchaseConfirmationPopup(context, ref, omurBoyuProduct, omurBoyuProduct.title, omurBoyuProduct.price, 'Tek seferlik ödeme ile sınırsız reklamsız erişim.'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Ödüllü Reklam Bölümü
          Text(
            'Ücretsiz Elmas Kazan',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Kısa bir reklam izleyerek günlük elmas hakkınızı kullanın.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _RewardedAdCard(key: const ValueKey('rewardedAdCard')), // Benzersiz anahtar eklendi
          const SizedBox(height: 32),

          // Elmas Satın Alma Bölümü
          Text(
            'Elmas Satın Al',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Testleri çözmek ve özel içeriklerin kilidini açmak için elmas kullanın.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _DiamondCard(
                key: ValueKey(elmas100Product.id), // Benzersiz anahtar eklendi
                diamondAmount: 100,
                price: elmas100Product.price,
                icon: Icons.diamond,
                onTap: () => _showPurchaseConfirmationPopup(context, ref, elmas100Product, elmas100Product.title, elmas100Product.price, '100 Elmas paketi.'),
              ),
              _DiamondCard(
                key: ValueKey(elmas250Product.id), // Benzersiz anahtar eklendi
                diamondAmount: 250,
                price: elmas250Product.price,
                icon: Icons.diamond,
                onTap: () => _showPurchaseConfirmationPopup(context, ref, elmas250Product, elmas250Product.title, elmas250Product.price, '250 Elmas paketi.'),
              ),
              _DiamondCard(
                key: ValueKey(elmas500Product.id), // Benzersiz anahtar eklendi
                diamondAmount: 500,
                price: elmas500Product.price,
                icon: Icons.diamond,
                onTap: () => _showPurchaseConfirmationPopup(context, ref, elmas500Product, elmas500Product.title, elmas500Product.price, '500 Elmas paketi.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ürün detayları yüklenemediğinde yer tutucu bir ProductDetails nesnesi oluşturur.
  // Bu fonksiyon sadece ürünler yüklenemediğinde bir fallback olarak kullanılır.
  ProductDetails _createPlaceholderProduct(String id, String title, String price) {
    // _MockProductDetails sınıfını kullanarak ProductDetails arayüzünü implement ediyoruz.
    return _MockProductDetails(
      id: id,
      title: title,
      description: 'Ürün bilgisi yüklenemedi.',
      price: price,
      rawPrice: 0.0,
      currencyCode: 'TL',
      currencySymbol: '₺',
      originalPrice: price,
      originalPriceAmountMicros: 0,
      subscriptionPeriod: null, // Nullable olduğu için null geçilebilir
      introductoryPrice: null,
      introductoryPriceAmountMicros: null,
      introductoryPriceCycles: null,
      introductoryPricePeriod: null,
      freeTrialPeriod: null,
    );
  }
}

// Abonelik seçeneklerini gösteren kart widget'ı (Aynı kalıyor, super.key eklendi)
class _SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final Color color;
  final IconData icon;
  final bool isPopular;
  final VoidCallback onTap;

  const _SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.color,
    required this.icon,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: theme.colorScheme.secondary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(price, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// Elmas paketlerini gösteren kart widget'ı (Aynı kalıyor, super.key eklendi)
class _DiamondCard extends StatelessWidget {
  final int diamondAmount;
  final String price;
  final VoidCallback onTap;
  final IconData icon;

  const _DiamondCard({
    super.key,
    required this.diamondAmount,
    required this.price,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.secondary),
              const SizedBox(height: 12),
              Text(
                '$diamondAmount Elmas',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                price,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ödüllü Reklam Kartı (Aynı kalıyor, super.key eklendi)
class _RewardedAdCard extends ConsumerStatefulWidget {
  const _RewardedAdCard({super.key});

  @override
  ConsumerState<_RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends ConsumerState<_RewardedAdCard> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  // `_isRewardedAdLoaded` artık burada tanımlı ve kullanılıyor.
  // Bu değişken sadece reklamın yüklenip yüklenmediğini takip eder.
  bool _isRewardedAdLoaded = false;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd(); // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.listen'ı artık burada çağırılıyor
      ref.listen<int>(userDataProvider.select((data) => data.storeAdCooldownEndTime), (previous, next) {
        _startTimerIfNeeded(); // Cooldown değiştiğinde sayacı yeniden başlat
        _loadRewardedAd(); // Cooldown değiştiğinde reklamı yeniden yüklemeye çalış
      });
      _startTimerIfNeeded(); // İlk sayaç başlatma
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Ödüllü reklamı yükleyen metot
  void _loadRewardedAd() {
    setState(() {
      _isRewardedAdLoading = true;
      _isRewardedAdLoaded = false; // Yükleme başladığında false olarak ayarla
      _rewardedAd = null; // Önceki reklamı temizle
    });
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
            _isRewardedAdLoaded = true; // Reklam yüklendiğinde true olarak ayarla
          });
          print('Rewarded reklam yüklendi.');
        },
        onAdFailedToLoad: (LoadAdError error) { // `ad` parametresi kaldırıldı, `error` tipi düzeltildi
          debugPrint('RewardedAd failed to load: $error');
          setState(() {
            _isRewardedAdLoaded = false; // Yükleme başarısız oldu
            _rewardedAd = null;
          });
          // `ad.dispose()` çağrısı kaldırıldı, çünkü `error` nesnesinde dispose metodu yoktur.
          // Yükleme başarısız olduğunda reklam nesnesi zaten oluşmamış veya geçersizdir.
        },
      ),
    );
  }

  void _startTimerIfNeeded() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.storeAdCooldownEndTime);

    if (cooldownEndTime.isAfter(DateTime.now())) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    } else {
      ref.read(userDataProvider.notifier).resetAdCount();
    }
  }

  void _updateRemainingTime() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.storeAdCooldownEndTime);
    final now = DateTime.now();

    if (cooldownEndTime.isAfter(now)) {
      if (mounted) setState(() => _remainingTime = cooldownEndTime.difference(now));
    } else {
      if (mounted) {
        setState(() => _remainingTime = Duration.zero);
        _timer?.cancel();
        ref.read(userDataProvider.notifier).resetAdCount();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider);
    final canWatchAd = userData.storeRewardedAdWatchCount == 0;

    String buttonText;
    VoidCallback? onPressed;

    if (_remainingTime > Duration.zero) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(_remainingTime.inHours);
      // `remainder` yerine `inMinutes.remainder` ve `inSeconds.remainder` kullanıldı
      final minutes = twoDigits(_remainingTime.inMinutes.remainder(60));
      final seconds = twoDigits(_remainingTime.inSeconds.remainder(60));
      buttonText = 'Sonraki Reklam: $hours:$minutes:$seconds';
      onPressed = null;
    } else if (_isRewardedAdLoading) {
      buttonText = 'Reklam Yükleniyor...';
      onPressed = null;
    } else if (_rewardedAd != null && canWatchAd && _isRewardedAdLoaded) { // `_isRewardedAdLoaded` kontrolü eklendi
      buttonText = 'Reklam İzle ve 5 Elmas Kazan';
      onPressed = () {
        _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
          final success = ref.read(userDataProvider.notifier).useStoreRewardedAd();
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ödüllü reklam izlendi ve ${reward.amount.toInt()} ${reward.type} kazandın!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bugün zaten ödüllü reklam izlediniz veya bir sorun oluştu.')),
            );
          }
          _loadRewardedAd();
        });
        _rewardedAd = null;
      };
    } else {
      buttonText = 'Bugünlük hakkın doldu';
      onPressed = null;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_collection_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Günlük Ödüllü Reklam',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Günde 1 kez izleyerek 5 elmas kazının.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    buttonText,
                    style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
