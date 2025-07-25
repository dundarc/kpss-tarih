import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/data/models/question_model.dart';
import 'package:kpss_tarih_app/data/models/user_data_model.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';
import 'package:kpss_tarih_app/features/store/providers/store_providers.dart';
import 'package:kpss_tarih_app/features/test/screens/test_result_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// --- STATE MANAGEMENT ---

final randomQuestionsProvider = FutureProvider.autoDispose<List<Question>>((ref) {
  return ref.watch(contentServiceProvider).getRandomQuestions();
});

final randomTestControllerProvider = StateNotifierProvider.autoDispose<RandomTestController, TestState>((ref) {
  return RandomTestController(ref);
});

enum TestStatus { initial, inProgress, completed }

class TestState {
  final List<Question> questions;
  final List<int?> selectedAnswers;
  final int currentQuestionIndex;
  final TestStatus status;
  final bool isJokerUsed;
  final List<int> eliminatedOptions;

  TestState({
    this.questions = const [],
    this.selectedAnswers = const [],
    this.currentQuestionIndex = 0,
    this.status = TestStatus.initial,
    this.isJokerUsed = false,
    this.eliminatedOptions = const [],
  });

  TestState copyWith({
    List<Question>? questions,
    List<int?>? selectedAnswers,
    int? currentQuestionIndex,
    TestStatus? status,
    bool? isJokerUsed,
    List<int>? eliminatedOptions,
  }) {
    return TestState(
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      isJokerUsed: isJokerUsed ?? this.isJokerUsed,
      eliminatedOptions: eliminatedOptions ?? this.eliminatedOptions,
    );
  }
}

class RandomTestController extends StateNotifier<TestState> {
  final Ref _ref;
  RandomTestController(this._ref) : super(TestState());

  Future<void> _prepareAndStartTest() async {
    final allQuestions = await _ref.read(randomQuestionsProvider.future);
    allQuestions.shuffle();
    final testQuestions = allQuestions.take(10).toList();

    state = TestState(
      questions: testQuestions,
      selectedAnswers: List<int?>.filled(10, null),
      status: TestStatus.inProgress,
    );
  }

  void startTestWithAd() {
    _prepareAndStartTest();
  }

  void startTestPremium() {
    _prepareAndStartTest();
  }

  void selectAnswer(int selectedIndex) {
    if (state.status == TestStatus.inProgress) {
      final newAnswers = List<int?>.from(state.selectedAnswers);
      newAnswers[state.currentQuestionIndex] = selectedIndex;
      state = state.copyWith(selectedAnswers: newAnswers);
    }
  }

  // *** HATA DÜZELTMESİ: Fonksiyon 'async' yapıldı ve 'await' eklendi. ***
  Future<void> useFiftyFiftyJoker() async {
    final success = await _ref.read(diamondNotifierProvider.notifier).spendDiamonds(1);
    if (success) {
      final currentQuestion = state.questions[state.currentQuestionIndex];
      final correctAnswerIndex = currentQuestion.correctAnswerIndex;

      final wrongOptions = <int>[];
      for (int i = 0; i < currentQuestion.options.length; i++) {
        if (i != correctAnswerIndex) {
          wrongOptions.add(i);
        }
      }

      wrongOptions.shuffle();
      final eliminated = wrongOptions.take(2).toList();

      state = state.copyWith(
        isJokerUsed: true,
        eliminatedOptions: eliminated,
      );
    }
  }

  void nextQuestion(BuildContext context) {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        isJokerUsed: false,
        eliminatedOptions: [],
      );
    } else {
      int correctCount = 0;
      for (int i = 0; i < state.questions.length; i++) {
        if (state.selectedAnswers[i] == state.questions[i].correctAnswerIndex) {
          correctCount++;
        }
      }

      _ref.read(userDataProvider.notifier).recordRandomTestResult(correctCount);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            correctAnswers: correctCount,
            totalQuestions: state.questions.length,
            topicId: 'random_test',
          ),
        ),
      );
    }
  }
}

// --- UI (ARAYÜZ) ---

class RandomTestScreen extends ConsumerStatefulWidget {
  const RandomTestScreen({super.key});
  @override
  ConsumerState<RandomTestScreen> createState() => _RandomTestScreenState();
}

class _RandomTestScreenState extends ConsumerState<RandomTestScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimerIfNeeded();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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

  void _loadRewardedAd() {
    setState(() {
      _isRewardedAdLoaded = false;
      _rewardedAd = null;
    });
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('RewardedAd failed to load: $err');
          if (!mounted) return;
          setState(() {
            _isRewardedAdLoaded = false;
            _rewardedAd = null;
          });
        },
      ),
    );
  }

  void _startTimerIfNeeded() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.randomTestEntryAdCooldownEndTime);

    if (cooldownEndTime.isAfter(DateTime.now())) {
      _updateRemainingTime();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    } else {
      ref.read(userDataProvider.notifier).resetAdCount();
    }
  }

  void _updateRemainingTime() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.randomTestEntryAdCooldownEndTime);
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

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Testten Çıkmak İstiyor Musunuz?'),
        content: const Text('Testten çıkarsanız mevcut ilerlemeniz kaybolacaktır.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(userDataProvider.select((data) => data.randomTestEntryAdCooldownEndTime), (previous, next) {
      if (previous != next) {
        _startTimerIfNeeded();
        _loadRewardedAd();
      }
    });

    final testState = ref.watch(randomTestControllerProvider);

    final userPlan = ref.watch(userPlanProvider);
    final isPremium = userPlan != UserPlan.free;

    if (testState.status == TestStatus.inProgress) return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: const _TestView(),
    );

    if (isPremium) return const _PremiumGateScreen();

    final userData = ref.watch(userDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rastgele Sorular')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _buildGateScreen(context, userData, _remainingTime),
            ),
          ),
          if (!isPremium && _bannerAd != null && _isBannerAdLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGateScreen(BuildContext context, UserData userData, Duration remainingTime) {
    final theme = Theme.of(context);
    final canWatchAd = userData.randomTestEntryAdWatchCount == 0;

    if (remainingTime > Duration.zero) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(remainingTime.inHours);
      final minutes = twoDigits(remainingTime.inMinutes.remainder(60));
      final seconds = twoDigits(remainingTime.inSeconds.remainder(60));

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off_outlined, size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text('Hakkınız Doldu!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Tekrar soru çözebilmek için lütfen aşağıdaki sürenin dolmasını bekleyin.', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text('$hours:$minutes:$seconds', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('10 Rastgele Soru Çöz', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.slow_motion_video),
              label: Text(
                canWatchAd
                    ? (_isRewardedAdLoaded ? 'Reklam İzle ve Başla (1 hakkın kaldı)' : 'Reklam Yükleniyor...')
                    : 'Bugünlük hakkın doldu',
              ),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: canWatchAd && _isRewardedAdLoaded
                  ? () {
                _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
                  final success = ref.read(userDataProvider.notifier).useRandomTestEntryAd();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reklam izlendi, teste başlayabilirsiniz!')),
                    );
                    ref.read(randomTestControllerProvider.notifier).startTestWithAd();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bugün zaten reklam izlediniz veya bir sorun oluştu.')),
                    );
                  }
                  _loadRewardedAd();
                });
                _rewardedAd = null;
              }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGateScreen extends ConsumerWidget {
  const _PremiumGateScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Rastgele Sorular')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined, size: 80, color: theme.colorScheme.secondary),
              const SizedBox(height: 24),
              Text('Sınırsız Soru Çöz!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Premium üye olduğunuz için dilediğiniz kadar rastgele soru çözebilirsiniz.', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Teste Başla'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => ref.read(randomTestControllerProvider.notifier).startTestPremium(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestView extends ConsumerWidget {
  const _TestView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(randomTestControllerProvider);
    final testController = ref.read(randomTestControllerProvider.notifier);
    final theme = Theme.of(context);

    if (testState.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rastgele Test')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = testState.questions[testState.currentQuestionIndex];
    final selectedAnswer = testState.selectedAnswers[testState.currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastgele Test'),
        actions: [
          _RandomTestFiftyFiftyJokerButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Soru ${testState.currentQuestionIndex + 1} / ${testState.questions.length}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (testState.currentQuestionIndex + 1) / testState.questions.length, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 24),
            Expanded(flex: 2, child: Center(child: Text(currentQuestion.questionText, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center))),
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
                    isEliminated: testState.eliminatedOptions.contains(index),
                    onTap: () {
                      if (selectedAnswer == null) {
                        testController.selectAnswer(index);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedAnswer != null ? () => testController.nextQuestion(context) : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              child: Text(testState.currentQuestionIndex < testState.questions.length - 1 ? 'Sonraki Soru' : 'Bitir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RandomTestFiftyFiftyJokerButton extends ConsumerWidget {
  const _RandomTestFiftyFiftyJokerButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diamondCount = ref.watch(diamondNotifierProvider);
    final testState = ref.watch(randomTestControllerProvider);
    final isAnswered = testState.selectedAnswers[testState.currentQuestionIndex] != null;

    final bool canUseJoker = diamondCount >= 1 && !testState.isJokerUsed && !isAnswered;

    return Tooltip(
      message: 'İki yanlış şıkkı ele (1 Elmas)',
      child: ActionChip(
        avatar: const Icon(Icons.diamond_outlined, size: 18),
        label: Text('Joker ($diamondCount)'),
        onPressed: canUseJoker
            ? () {
          ref.read(randomTestControllerProvider.notifier).useFiftyFiftyJoker();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İki yanlış şık elendi!')),
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
  final bool isEliminated;
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
