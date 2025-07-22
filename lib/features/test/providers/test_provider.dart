import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/data/models/question_model.dart';
import 'package:kpss_tarih_app/features/test/screens/test_result_screen.dart';

enum TestStatus { initial, inProgress, answered, completed }

class TestState {
  final List<Question> questions;
  final List<int?> selectedAnswers;
  final int currentQuestionIndex;
  final TestStatus status;
  final String topicId;
  final bool isJokerUsed; // JOKER: Bu soruda joker kullanıldı mı?
  final List<int> eliminatedOptions; // JOKER: Elenen şıkların index'leri

  TestState({
    this.questions = const [],
    this.selectedAnswers = const [],
    this.currentQuestionIndex = 0,
    this.status = TestStatus.initial,
    this.topicId = '',
    this.isJokerUsed = false,
    this.eliminatedOptions = const [],
  });

  TestState copyWith({
    List<Question>? questions,
    List<int?>? selectedAnswers,
    int? currentQuestionIndex,
    TestStatus? status,
    String? topicId,
    bool? isJokerUsed,
    List<int>? eliminatedOptions,
  }) {
    return TestState(
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      topicId: topicId ?? this.topicId,
      isJokerUsed: isJokerUsed ?? this.isJokerUsed,
      eliminatedOptions: eliminatedOptions ?? this.eliminatedOptions,
    );
  }
}

class TestController extends StateNotifier<TestState> {
  final Ref _ref; // Diğer provider'lara erişmek için
  TestController(this._ref) : super(TestState());

  void startTest(List<Question> questions, String topicId) {
    state = TestState(
      questions: questions,
      selectedAnswers: List<int?>.filled(questions.length, null),
      status: TestStatus.inProgress,
      topicId: topicId,
    );
  }

  void selectAnswer(int selectedIndex) {
    if (state.status == TestStatus.inProgress) {
      final newAnswers = List<int?>.from(state.selectedAnswers);
      newAnswers[state.currentQuestionIndex] = selectedIndex;
      state = state.copyWith(
        selectedAnswers: newAnswers,
        status: TestStatus.answered,
      );
    }
  }

  // --- YENİ FONKSİYON: JOKER KULLANMA ---
  void useFiftyFiftyJoker() {
    // Elmas harcama başarılı olursa joker mantığını çalıştır
    final success = _ref.read(userDataProvider.notifier).spendDiamonds(1);
    if (success) {
      final currentQuestion = state.questions[state.currentQuestionIndex];
      final correctAnswerIndex = currentQuestion.correctAnswerIndex;

      // Yanlış şıkları bul
      final wrongOptions = <int>[];
      for (int i = 0; i < currentQuestion.options.length; i++) {
        if (i != correctAnswerIndex) {
          wrongOptions.add(i);
        }
      }

      // Yanlış şıkları karıştır ve ilk ikisini ele
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
        status: TestStatus.inProgress,
        isJokerUsed: false, // JOKER: Yeni soru için jokeri sıfırla
        eliminatedOptions: [], // JOKER: Elenen şıkları temizle
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            correctAnswers: correctAnswersCount,
            totalQuestions: state.questions.length,
            topicId: state.topicId,
          ),
        ),
      );
    }
  }

  int get correctAnswersCount {
    int correctCount = 0;
    for (int i = 0; i < state.questions.length; i++) {
      if (state.selectedAnswers[i] == state.questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }
    return correctCount;
  }
}

final testControllerProvider = StateNotifierProvider.autoDispose<TestController, TestState>((ref) {
  return TestController(ref);
});
