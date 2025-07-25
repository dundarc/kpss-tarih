import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kpss_tarih_app/data/models/topic_model.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';
import 'package:kpss_tarih_app/features/store/providers/store_providers.dart';
import 'package:kpss_tarih_app/features/test/screens/test_screen.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final Topic topic;
  const TopicDetailScreen({super.key, required this.topic});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
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
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
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
    final theme = Theme.of(context);
    // *** DÜZELTME: Artık yeni ve doğru olan userPlanProvider'ı kullanıyoruz. ***
    final userPlan = ref.watch(userPlanProvider);
    final isPremium = userPlan != UserPlan.free;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.topic.title,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  shadows: const [
                    Shadow(blurRadius: 8.0, color: Colors.black45)
                  ],
                ),
              ),
              background: Hero(
                tag: 'topic_image_${widget.topic.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.purple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.history_edu,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: widget.topic.content,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // *** GÜNCELLEME: Reklam gösterme koşulu userPlan'a bağlı. ***
          if (!isPremium && _bannerAd != null && _isBannerAdLoaded)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Konu Testini Çöz'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestScreen(topicId: widget.topic.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
