import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/main.dart'; // navigatorKey'e erişmek için eklendi

// Bu ID'ler, Google Play Console ve App Store Connect'te oluşturduğunuz
// ürün ID'leri ile birebir aynı olmalıdır.
const String aylikAbonelikId = 'aylik_reklamsiz_20tl';
const String yillikAbonelikId = 'yillik_reklamsiz_200tl';
const String omurBoyuId = 'omur_boyu_reklamsiz_499tl';
const String elmas100Id = '100_elmas_150tl';
const String elmas250Id = '250_elmas_250tl';
const String elmas500Id = '500_elmas_400tl';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  // Satın alma işlemini tetikleyecek fonksiyon (yer tutucu)
  void _buyProduct(WidgetRef ref, String productId) {
    // TODO: PurchaseService'i çağırarak gerçek satın alma işlemini başlat.
    // final purchaseService = ref.read(purchaseServiceProvider);
    // purchaseService.buyProduct(productId);

    print('Buying product: $productId');
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text('$productId ürünü için satın alma başlatılıyor...')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          _SubscriptionCard(
            title: 'Aylık Abonelik',
            price: '20 TL',
            description: 'Her ay yenilenir.',
            color: Colors.teal,
            icon: Icons.calendar_month,
            onTap: () => _buyProduct(ref, aylikAbonelikId),
          ),
          _SubscriptionCard(
            title: 'Yıllık Abonelik',
            price: '200 TL',
            description: 'Yıllık öde, tasarruf et!',
            color: Colors.orange,
            icon: Icons.cake,
            isPopular: true,
            onTap: () => _buyProduct(ref, yillikAbonelikId),
          ),
          _SubscriptionCard(
            title: 'Ömür Boyu Premium',
            price: '499 TL',
            description: 'Tek sefer öde, sonsuza dek kullan.',
            color: Colors.purple,
            icon: Icons.rocket_launch,
            onTap: () => _buyProduct(ref, omurBoyuId),
          ),
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
                diamondAmount: 100,
                price: '150 TL',
                onTap: () => _buyProduct(ref, elmas100Id),
              ),
              _DiamondCard(
                diamondAmount: 250,
                price: '250 TL',
                onTap: () => _buyProduct(ref, elmas250Id),
              ),
              _DiamondCard(
                diamondAmount: 500,
                price: '400 TL',
                onTap: () => _buyProduct(ref, elmas500Id),
              ),
              // Gerekirse daha fazla elmas paketi eklenebilir.
            ],
          ),
        ],
      ),
    );
  }
}

// Abonelik seçeneklerini gösteren kart widget'ı
class _SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final Color color;
  final IconData icon;
  final bool isPopular;
  final VoidCallback onTap;

  const _SubscriptionCard({
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

// Elmas paketlerini gösteren kart widget'ı
class _DiamondCard extends StatelessWidget {
  final int diamondAmount;
  final String price;
  final VoidCallback onTap;

  const _DiamondCard({
    required this.diamondAmount,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.diamond, size: 48, color: theme.colorScheme.secondary),
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
