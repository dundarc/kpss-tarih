import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kpss_tarih_app/features/store/data/product_ids.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';
import 'package:kpss_tarih_app/features/store/providers/store_providers.dart';
import 'package:kpss_tarih_app/features/store/services/purchase_service.dart';

// StoreScreen, hem Riverpod state'ini dinlemek hem de widget'ın kendi iç state'ini
// (reklamlar gibi) yönetmek için ConsumerStatefulWidget olarak oluşturuldu.
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  // Satın alma işlemini başlatan metot
  void _buyProduct(ProductDetails productDetails) {
    // ref, ConsumerStatefulWidget içinde doğrudan erişilebilir durumdadır.
    ref.read(purchaseServiceProvider).buyProduct(productDetails);
  }

  // Satın alma onayı için modern bir dialog penceresi gösteren metot
  void _showPurchaseConfirmationPopup(ProductDetails productDetails) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${productDetails.title} Satın Al', textAlign: TextAlign.center),
          content: Text(
            '${productDetails.description}\n\nFiyat: ${productDetails.price}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _buyProduct(productDetails);
              },
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ref.watch, provider'daki değişiklikleri dinler ve UI'ın yeniden çizilmesini tetikler.
    final purchaseService = ref.watch(purchaseServiceProvider);
    final purchaseStatus = purchaseService.status;
    final products = purchaseService.products;

    // Duruma göre farklı UI'lar gösteren merkezi bir yapı
    Widget buildContent() {
      switch (purchaseStatus) {
        case PurchaseStatusEnum.loading:
          return const Center(child: CircularProgressIndicator());
        case PurchaseStatusEnum.error:
        case PurchaseStatusEnum.unavailable:
          return _buildErrorUI(context, theme, purchaseService.errorMessage, purchaseService);
        case PurchaseStatusEnum.purchasing:
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
        case PurchaseStatusEnum.available:
          final subscriptions = products.where((p) => subscriptionIds.contains(p.id)).toList();
          final consumables = products.where((p) => consumableIds.contains(p.id)).toList();
          return _buildStoreUI(context, theme, subscriptions, consumables);
      }
    }

    return Scaffold(
      body: buildContent(),
    );
  }

  // Mağaza arayüzünü oluşturan ana metot
  Widget _buildStoreUI(BuildContext context, ThemeData theme, List<ProductDetails> subscriptions, List<ProductDetails> consumables) {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Mağaza'),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              bottom: TabBar(
                tabs: const [
                  Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Premium'),
                  Tab(icon: Icon(Icons.diamond_outlined), text: 'Elmas Paketleri'),
                ],
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            _buildSubscriptionsPage(context, theme, subscriptions),
            _buildConsumablesPage(context, theme, consumables),
          ],
        ),
      ),
    );
  }

  // Abonelikler sekmesinin içeriğini oluşturan metot
  Widget _buildSubscriptionsPage(BuildContext context, ThemeData theme, List<ProductDetails> subscriptions) {
    final userPlan = ref.watch(userPlanProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (userPlan != UserPlan.free)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userPlan == UserPlan.fullPremium
                            ? 'Ömür boyu Premium üyesisiniz!'
                            : 'Aktif bir Premium aboneliğiniz var.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...subscriptions.map((product) {
            return _SubscriptionCard(
              product: product,
              onTap: () => _showPurchaseConfirmationPopup(product),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Elmaslar sekmesinin içeriğini oluşturan metot
  Widget _buildConsumablesPage(BuildContext context, ThemeData theme, List<ProductDetails> consumables) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const _RewardedAdCard(), // Ücretsiz elmas kartı
          const SizedBox(height: 16),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: consumables.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final product = consumables[index];
              return _DiamondPackCard(
                product: product,
                onTap: () => _showPurchaseConfirmationPopup(product),
              );
            },
          ),
        ],
      ),
    );
  }

  // Hata durumunda gösterilecek UI
  Widget _buildErrorUI(BuildContext context, ThemeData theme, String? errorMessage, PurchaseService purchaseService) {
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
              onPressed: () => purchaseService.restorePurchases(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// Abonelik ürünlerini gösteren kart widget'ı
class _SubscriptionCard extends StatelessWidget {
  final ProductDetails product;
  final VoidCallback onTap;
  final bool isPopular;

  const _SubscriptionCard({required this.product, required this.onTap, this.isPopular = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: theme.colorScheme.secondary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (isPopular)
                Chip(
                  label: const Text('En Popüler'),
                  backgroundColor: theme.colorScheme.secondary,
                  labelStyle: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.bold),
                ),
              if (isPopular) const SizedBox(height: 8),
              Text(product.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(product.description, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(product.price, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Elmas paketlerini gösteren kart widget'ı
class _DiamondPackCard extends StatelessWidget {
  final ProductDetails product;
  final VoidCallback onTap;
  final bool isPopular;

  const _DiamondPackCard({required this.product, required this.onTap, this.isPopular = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: theme.colorScheme.secondary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(flex: 2, child: Icon(Icons.diamond, size: 48, color: Colors.blueAccent)),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(product.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const Spacer(),
                    Text(product.price, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ödüllü reklam kartı widget'ı
class _RewardedAdCard extends ConsumerStatefulWidget {
  const _RewardedAdCard();

  @override
  ConsumerState<_RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends ConsumerState<_RewardedAdCard> {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    setState(() { _isAdLoading = true; });
    RewardedAd.load(
      adUnitId: 'ca-app-pub-5204870751552541/4323395912', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
          });
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() { _isAdLoading = false; });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShowAd = !_isAdLoading && _rewardedAd != null;

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.slow_motion_video, size: 40, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ücretsiz Elmas', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                  Text('Reklam izleyerek 5 elmas kazanın!', style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: canShowAd ? () {
                _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
                  ref.read(diamondNotifierProvider.notifier).addDiamonds(5);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('5 Elmas kazandın!')),
                  );
                  _loadRewardedAd(); // Yeni reklam yükle
                });
              } : null,
              child: _isAdLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('İzle'),
            ),
          ],
        ),
      ),
    );
  }
}
