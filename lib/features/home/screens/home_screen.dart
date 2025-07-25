import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/features/home/providers/home_providers.dart';
import 'package:kpss_tarih_app/features/random_test/screens/random_test_screen.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';
import 'package:kpss_tarih_app/features/store/providers/store_providers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Ana sayfada toplam konu sayısını göstermek için provider
final totalTopicsCountProvider = FutureProvider<int>((ref) async {
  final contentService = ref.watch(contentServiceProvider);
  return await contentService.getTotalTopicsCount();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final totalTopicsAsync = ref.watch(totalTopicsCountProvider);
    final userData = ref.watch(userDataProvider);
    final theme = Theme.of(context);

    final userPlan = ref.watch(userPlanProvider);

    return Scaffold(
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
          const _TodayInHistoryCard(),
          const SizedBox(height: 24),
          const _DailyTasksSection(),
          const SizedBox(height: 24),

          if (userPlan == UserPlan.free && _bannerAd != null && _isBannerAdLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
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

class _QuickActions extends ConsumerWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Konulara Göz At', icon: Icons.menu_book_rounded, color: Colors.blue,
            onTap: () {
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

class _DailyTasksSection extends ConsumerWidget {
  const _DailyTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider);
    final userPlan = ref.watch(userPlanProvider);
    final isPremium = userPlan != UserPlan.free;



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük Görevler',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
                      ref.read(diamondNotifierProvider.notifier).addDiamonds(3);
                      ref.read(userDataProvider.notifier).markDailyTimeRewardClaimed();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('3 elmas kazandın!')),
                      );
                    },
                    child: const Text('Ödül Al (+3)'),
                  )
                else if (userData.dailyTimeRewardClaimed)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                      ref.read(diamondNotifierProvider.notifier).addDiamonds(2);
                      ref.read(userDataProvider.notifier).markDailyRandomTestRewardClaimed();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rastgele testlerde 7 doğruya ulaştın ve 2 elmas kazandın!')),
                      );
                    },
                    child: const Text('Ödül Al (+2)'),
                  )
                else if (userData.dailyRandomTestRewardClaimed)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isPremium)
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
                        const Text('Günlük hediye elmasınızı alın.'),
                      ],
                    ),
                  ),
                  // *** DÜZELTME: Butonun görünürlüğü artık tarihe göre belirleniyor. ***
                  if (true)
                    ElevatedButton(
                      onPressed: () async {
                        final success = await ref.read(userDataProvider.notifier).claimDailyPremiumReward();
                        if (success) {
                          await ref.read(diamondNotifierProvider.notifier).addDiamonds(1);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Premium günlük 1 elmas kazandın!')),
                            );
                          }
                        }
                      },
                      child: const Text('Ödül Al (+1)'),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            color: theme.colorScheme.secondary.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5))),
            child: InkWell(
              onTap: () {
                ref.read(mainNavigationSelectedIndexProvider.notifier).state = 2; // Mağaza sekmesi
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Ol, Her Gün Elmas Kazan!',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Premium\'a geçerek her gün hediye elmas kazanın.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 20, color: theme.colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
