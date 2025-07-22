import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/data/models/question_model.dart';
import 'package:kpss_tarih_app/data/models/user_data_model.dart';

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
  final bool isJokerUsed; // JOKER
  final List<int> eliminatedOptions; // JOKER

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
    _ref.read(userDataProvider.notifier).useRewardedAd();
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

  void useFiftyFiftyJoker() {
    final success = _ref.read(userDataProvider.notifier).spendDiamonds(1);
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

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        isJokerUsed: false,
        eliminatedOptions: [],
      );
    } else {
      state = TestState(status: TestStatus.completed);
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
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimerIfNeeded());
  }

  void _startTimerIfNeeded() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.cooldownEndTime);

    if (cooldownEndTime.isAfter(DateTime.now())) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    final userData = ref.read(userDataProvider);
    final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(userData.cooldownEndTime);
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(randomTestControllerProvider);
    final userData = ref.watch(userDataProvider);
    final isPremium = userData.isPremium || userData.isLifetimePremium;

    if (testState.status == TestStatus.inProgress) return const _TestView();
    if (isPremium) return const _PremiumGateScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('Rastgele Sorular')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _buildGateScreen(context, userData, _remainingTime),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 50,
            color: Colors.grey.shade200,
            child: const Text('Banner Reklam Alanı'),
          ),
        ],
      ),
    );
  }

  Widget _buildGateScreen(BuildContext context, UserData userData, Duration remainingTime) {
    final theme = Theme.of(context);
    final canWatchAd = userData.rewardedAdWatchCount < 3;

    if (remainingTime > Duration.zero) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
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
            Text('$minutes:$seconds', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
              label: Text('Reklam İzle ve Başla (${3 - userData.rewardedAdWatchCount} hakkın kaldı)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: canWatchAd ? () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ödüllü reklam izlendi (Simülasyon)')));
                ref.read(randomTestControllerProvider.notifier).startTestWithAd();
              } : null,
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
              onPressed: selectedAnswer != null ? () => testController.nextQuestion() : null,
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
    final diamondCount = ref.watch(userDataProvider.select((d) => d.diamondCount));
    final testState = ref.watch(randomTestControllerProvider);
    final isAnswered = testState.selectedAnswers[testState.currentQuestionIndex] != null;

    final bool canUseJoker = diamondCount >= 1 && !testState.isJokerUsed && !isAnswered;

    return Tooltip(
      message: 'İki yanlış şıkkı ele (1 Elmas)',
      child: ActionChip(
        avatar: const Icon(Icons.diamond_outlined, size: 18),
        // DÜZELTME: Buton metni, maliyeti de içerecek şekilde güncellendi.
        label: const Text('Joker (1 Elmas)'),
        onPressed: canUseJoker
            ? () => ref.read(randomTestControllerProvider.notifier).useFiftyFiftyJoker()
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
