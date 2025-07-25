import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/data/models/question_model.dart';
import 'package:kpss_tarih_app/features/test/providers/test_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../store/models/user_plan.dart';
import '../../store/providers/store_providers.dart'; // AdMob için eklendi

final questionsProvider = FutureProvider.autoDispose.family<List<Question>, String>((ref, topicId) {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getQuestionsForTopic(topicId);
});

class TestScreen extends ConsumerStatefulWidget {
  final String topicId;
  const TestScreen({super.key, required this.topicId});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  BannerAd? _bannerAd; // Banner reklam nesnesi
  bool _isBannerAdLoaded = false; // Banner reklamın yüklenip yüklenmediğini kontrol eder

  @override
  void initState() {
    super.initState();
    _initializeTest();
    _loadBannerAd(); // Banner reklamı yükle
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Reklamı dispose et
    super.dispose();
  }

  void _initializeTest() async {
    final questions = await ref.read(questionsProvider(widget.topicId).future);

    if (mounted && questions.isNotEmpty) {
      ref.read(testControllerProvider.notifier).startTest(questions, widget.topicId);
    } else if (mounted) {
      ref.read(testControllerProvider.notifier).startTest([], widget.topicId);
    }
  }

  // Banner reklamı yükleyen metot
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5204870751552541/3147625365', // Test Banner Reklam Birimi Kimliği
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

  // Testten çıkış onayı için pop-up gösteren fonksiyon
  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Testten Çıkmak İstiyor Musunuz?'),
        content: const Text('Testten çıkarsanız mevcut ilerlemeniz kaybolacaktır.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Hayır, çıkma
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Evet, çık
            child: const Text('Evet'),
          ),
        ],
      ),
    )) ?? false; // Eğer dialog kapatılırsa (geri tuşuyla vb.), false döndür
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testControllerProvider);
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider); // Kullanıcı verisini dinle
    final userPlan = ref.watch(userPlanProvider);
    final isPremium = userPlan != UserPlan.free;

    if (testState.status == TestStatus.initial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konu Testi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (testState.questions.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Konu Testi')),
          body: const Center(child: Text('Bu konu için test bulunamadı.'))
      );
    }

    final currentQuestion = testState.questions[testState.currentQuestionIndex];
    final selectedAnswer = testState.selectedAnswers[testState.currentQuestionIndex];

    return PopScope( // WillPopScope yerine PopScope kullanıldı
      canPop: false, // Geri tuşuyla doğrudan çıkışı engelle
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Konu Testi'),
          // --- YENİ BÖLÜM: JOKER BUTONU ---
          actions: [
            _FiftyFiftyJokerButton(),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Soru ${testState.currentQuestionIndex + 1} / ${testState.questions.length}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (testState.currentQuestionIndex + 1) / testState.questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    currentQuestion.questionText,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: currentQuestion.options.length,
                  itemBuilder: (context, index) {
                    return _OptionTile(
                      optionText: currentQuestion.options[index],
                      index: index,
                      isSelected: selectedAnswer == index,
                      isCorrect: index == currentQuestion.correctAnswerIndex,
                      isAnswered: selectedAnswer != null,
                      // JOKER: Elenen şıkkı kontrol et
                      isEliminated: testState.eliminatedOptions.contains(index),
                      onTap: () {
                        if (selectedAnswer == null) {
                          ref.read(testControllerProvider.notifier).selectAnswer(index);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Reklam alanı ve sonraki/bitir butonu
              if (!isPremium && _bannerAd != null && _isBannerAdLoaded)// Sadece premium olmayan kullanıcılar için reklamı göster
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              const SizedBox(height: 12), // Reklam ile buton arasına boşluk
              ElevatedButton(
                onPressed: selectedAnswer != null ? () => ref.read(testControllerProvider.notifier).nextQuestion(context) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                child: Text(
                  testState.currentQuestionIndex < testState.questions.length - 1
                      ? 'Sonraki Soru'
                      : 'Testi Bitir',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- YENİ WIDGET: JOKER BUTONU ---
class _FiftyFiftyJokerButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diamondCount = ref.watch(userDataProvider.select((d) => d.diamondCount));
    final testState = ref.watch(testControllerProvider);
    final isAnswered = testState.selectedAnswers[testState.currentQuestionIndex] != null;

    final bool canUseJoker = diamondCount >= 1 && !testState.isJokerUsed && !isAnswered;

    return Tooltip(
      message: 'İki yanlış şıkkı ele (1 Elmas)',
      child: ActionChip(
        avatar: const Icon(Icons.diamond_outlined, size: 18),
        label: Text('Joker (1 Elmas) ($diamondCount Elmasın Var)'), // Güncellenen kısım
        onPressed: canUseJoker
            ? () {
          ref.read(testControllerProvider.notifier).useFiftyFiftyJoker();
          // Joker kullanıldığında kullanıcıya bilgi vermek için SnackBar eklendi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(canUseJoker ? 'İki yanlış şık elendi!' : 'Yeterli elmasınız yok veya joker bu soruda kullanıldı.')),
          );
        }
            : null,
      ),
    );
  }
}


class _OptionTile extends StatelessWidget {
  final String optionText;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final bool isEliminated; // JOKER: Yeni parametre
  final VoidCallback onTap;

  const _OptionTile({
    required this.optionText,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.isEliminated,
    required this.onTap,
  });

  Color _getBorderColor(ThemeData theme) {
    if (!isAnswered) return theme.dividerColor;
    if (isSelected && isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    if (!isSelected && isCorrect) return Colors.green;
    return theme.dividerColor;
  }

  IconData? _getTrailingIcon() {
    if (!isAnswered) return null;
    if (isSelected && isCorrect) return Icons.check_circle;
    if (isSelected && !isCorrect) return Icons.cancel;
    if (!isSelected && isCorrect) return Icons.check_circle_outline;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // JOKER: Eğer şık elenmişse, tıklanamaz ve soluk yap
    if (isEliminated) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        child: ListTile(
          title: Text(
            optionText,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getBorderColor(theme), width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(optionText),
        trailing: Icon(_getTrailingIcon(), color: _getBorderColor(theme)),
      ),
    );
  }
}
