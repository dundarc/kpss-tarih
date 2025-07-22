import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/features/home/providers/home_providers.dart';
import 'package:kpss_tarih_app/features/random_test/screens/random_test_screen.dart';
import 'package:kpss_tarih_app/features/topics/screens/category_list_screen.dart';
import 'package:kpss_tarih_app/features/store/screens/store_screen.dart'; // Mağaza ekranına yönlendirme için eklendi
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob için eklendi

// Ana sayfada toplam konu sayısını göstermek için yeni provider
final totalTopicsCountProvider = FutureProvider<int>((ref) async {
  final contentService = ref.watch(contentServiceProvider);
  return await contentService.getTotalTopicsCount();
});

class HomeScreen extends ConsumerStatefulWidget { // ConsumerStatefulWidget olarak değiştirildi
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd; // Banner reklam nesnesi
  bool _isBannerAdLoaded = false; // Banner reklamın yüklenip yüklenmediğini kontrol eder

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // Banner reklamı yükle
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Reklamı dispose et
    super.dispose();
  }

  // Banner reklamı yükleyen metot
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner Reklam Birimi Kimliği
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          print('Home screen banner reklam yüklendi.');
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Home screen BannerAd failed to load: $err');
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('Home screen BannerAd opened.'),
        onAdClosed: (ad) => debugPrint('Home screen BannerAd closed.'),
        onAdImpression: (ad) => debugPrint('Home screen BannerAd impression.'),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final totalTopicsAsync = ref.watch(totalTopicsCountProvider);
    final userData = ref.watch(userDataProvider);
    final theme = Theme.of(context);
    final isPremium = userData.isPremium || userData.isLifetimePremium; // Premium durumunu kontrol et

    return Scaffold(
      // AppBar buradan kaldırıldı, artık MainNavigation tarafından sağlanıyor.
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Hoş Geldin!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300)),
          Text('Bugün tarih öğrenmeye hazır mısın?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          totalTopicsAsync.when(
            data: (totalCount) => _ProgressCard(
              completedTopics: userData.completedTopicIds.length,
              totalTopics: totalCount,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text('İlerleme bilgisi yüklenemedi.'),
          ),
          const SizedBox(height: 24),
          const _QuickActions(),
          const SizedBox(height: 24),
          const _DailyTasksSection(), // YENİ: Günlük görevler bölümü eklendi
          const SizedBox(height: 24),
          const _TodayInHistoryCard(),
          const SizedBox(height: 24), // Reklam alanı için boşluk
          if (!isPremium && _bannerAd != null && _isBannerAdLoaded) // Sadece premium olmayan kullanıcılar için reklamı göster
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          if (!isPremium && (_bannerAd == null || !_isBannerAdLoaded)) // Reklam yüklenirken veya yüklenemediğinde yer tutucu
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Text('Reklam Alanı'),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completedTopics;
  final int totalTopics;
  const _ProgressCard({required this.completedTopics, required this.totalTopics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = totalTopics > 0 ? completedTopics / totalTopics : 0;
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İlerleme Durumun', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Text('$totalTopics konudan $completedTopics tanesini tamamladın.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary.withOpacity(0.8))),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget { // ConsumerWidget yapıldı
  const _QuickActions();
  @override
  Widget build(BuildContext context, WidgetRef ref) { // WidgetRef eklendi
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Konulara Göz At', icon: Icons.menu_book_rounded, color: Colors.blue,
            onTap: () {
              // Navigator.push yerine tab değişimi yapıldı
              ref.read(mainNavigationSelectedIndexProvider.notifier).state = 1;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            title: 'Rastgele Test Çöz', icon: Icons.quiz_rounded, color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RandomTestScreen())),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayInHistoryCard extends ConsumerWidget {
  const _TodayInHistoryCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayInHistoryText = ref.watch(todayInHistoryProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarihte Bugün',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              todayInHistoryText,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// YENİ WIDGET: Günlük Görevler Bölümü
class _DailyTasksSection extends ConsumerWidget {
  const _DailyTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider);
    final isPremium = userData.isPremium || userData.isLifetimePremium; // Premium durumunu kontrol et

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük Görevler',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Görev 1: Uygulamada Geçirilen Süre
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uygulamada Geçirilen Süre', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${userData.timeSpentMinutesToday} / 20 dakika', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (userData.timeSpentMinutesToday >= 20 && !userData.dailyTimeRewardClaimed)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userDataProvider.notifier).addDiamonds(3); // Ödülü ver
                      ref.read(userDataProvider.notifier).markDailyTimeRewardClaimed(); // Ödül alındı olarak işaretle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uygulamada 20 dakika geçirdin ve 3 elmas kazandın!')),
                      );
                    },
                    child: const Text('Ödül Al (+3)'),
                  )
                else if (userData.dailyTimeRewardClaimed)
                  Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Görev 2: Rastgele Test Doğru Cevapları
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, size: 32, color: theme.colorScheme.secondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rastgele Test Doğru Cevapları', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${userData.randomTestCorrectAnswersToday} / 7 doğru', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (userData.randomTestCorrectAnswersToday >= 7 && !userData.dailyRandomTestRewardClaimed)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userDataProvider.notifier).addDiamonds(2); // Ödülü ver
                      ref.read(userDataProvider.notifier).markDailyRandomTestRewardClaimed(); // Ödül alındı olarak işaretle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rastgele testlerde 7 doğruya ulaştın ve 2 elmas kazandın!')),
                      );
                    },
                    child: const Text('Ödül Al (+2)'),
                  )
                else if (userData.dailyRandomTestRewardClaimed)
                  Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Görev 3: Premium Günlük Elmas (Koşullu olarak göster)
        if (isPremium) // Sadece premium kullanıcılar için göster
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 32, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Premium Günlük Elmas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Günlük hediye elmasınızı alın.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (!userData.dailyPremiumRewardClaimed)
                    ElevatedButton(
                      onPressed: () {
                        final success = ref.read(userDataProvider.notifier).claimDailyPremiumReward();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Premium günlük elmas ödülünüzü kazandınız! (+1 Elmas)')),
                          );
                        }
                      },
                      child: const Text('Ödül Al (+1)'),
                    )
                  else
                    Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          )
        else // Premium olmayan kullanıcılar için teşvik mesajı
          Card(
            elevation: 0,
            color: theme.colorScheme.secondary.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5))),
            child: InkWell(
              onTap: () {
                // Navigator.push yerine tab değişimi yapıldı
                ref.read(mainNavigationSelectedIndexProvider.notifier).state = 2; // Mağaza sekmesi indeksi
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Ol, Her Gün Elmas Kazan!',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aylık, Yıllık veya Ömür Boyu Premium paketlerden birini alarak her gün 1 elmas hediye kazanın!',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward_ios, size: 20, color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
