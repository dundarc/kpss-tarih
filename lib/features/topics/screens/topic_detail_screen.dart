import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/data/models/topic_model.dart';
import 'package:kpss_tarih_app/features/test/screens/test_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob için eklendi

// Belirli bir konuya ait püf noktasını getiren yeni provider
final tipsForTopicProvider = FutureProvider.autoDispose.family<String?, String>((ref, topicId) {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getTipsForTopic(topicId);
});

class TopicDetailScreen extends ConsumerStatefulWidget { // ConsumerStatefulWidget olarak değiştirildi
  final Topic topic;
  const TopicDetailScreen({super.key, required this.topic});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
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
          print('Banner reklam yüklendi.');
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('BannerAd opened.'),
        onAdClosed: (ad) => debugPrint('BannerAd closed.'),
        onAdImpression: (ad) => debugPrint('BannerAd impression.'),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final isPremium = userData.isPremium || userData.isLifetimePremium;
    final theme = Theme.of(context);

    final bool areTipsUnlocked = userData.unlockedTipsTopicIds.contains(widget.topic.id); // widget.topic.id olarak değiştirildi

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.title)), // widget.topic.title olarak değiştirildi
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: widget.topic.content, // widget.topic.content olarak değiştirildi
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      h3: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Püf noktası bölümünü yeni provider ile oluştur
                  _TipsSection(topicId: widget.topic.id, areTipsUnlocked: areTipsUnlocked), // widget.topic.id olarak değiştirildi
                ],
              ),
            ),
          ),
          // Test butonu ve reklam alanı
          Container(
            padding: const EdgeInsets.all(16.0).copyWith(top: 8),
            decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      alignment: Alignment.center, width: double.infinity, height: 50,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Reklam Alanı'),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('Konu Testini Çöz'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TestScreen(topicId: widget.topic.id))),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TipsSection extends ConsumerWidget {
  final String topicId;
  final bool areTipsUnlocked;
  const _TipsSection({required this.topicId, required this.areTipsUnlocked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Yeni provider'ı kullanarak püf noktası verisini çek
    final tipsAsyncValue = ref.watch(tipsForTopicProvider(topicId));

    return tipsAsyncValue.when(
      data: (tips) {
        // Eğer bu konu için bir püf noktası yoksa, hiçbir şey gösterme
        if (tips == null || tips.isEmpty) {
          return const SizedBox.shrink();
        }
        // Püf noktası varsa, kilidin durumuna göre ilgili widget'ı göster
        if (areTipsUnlocked) {
          return _TipsContent(tips: tips);
        } else {
          return _UnlockTipsButton(topicId: topicId);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Püf noktaları yüklenemedi.')),
    );
  }
}


// Püf noktalarını açma butonu (Aynı kalıyor)
class _UnlockTipsButton extends ConsumerWidget {
  final String topicId;
  const _UnlockTipsButton({required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diamondCount = ref.watch(userDataProvider.select((data) => data.diamondCount));

    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Püf Noktalarını Gör (3 Elmas)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.secondary,
          side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: diamondCount >= 3 ? () {
          final success = ref.read(userDataProvider.notifier).unlockTips(topicId);
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yeterli elmasınız yok!')),
            );
          }
        } : null,
      ),
    );
  }
}

// Püf noktaları içeriğini gösteren widget (Aynı kalıyor)
class _TipsContent extends StatelessWidget {
  final String tips;
  const _TipsContent({required this.tips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: MarkdownBody(
        data: tips,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyLarge,
          h3: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }
}
