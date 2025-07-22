import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';

class TestResultScreen extends ConsumerWidget {
  final int correctAnswers;
  final int totalQuestions;
  final String topicId; // Hangi konunun bittiğini bilmek için

  const TestResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final int earnedDiamonds = (correctAnswers / 5).floor();

    // Bu callback, build işlemi bittikten sonra state'i güvenli bir şekilde günceller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Konuyu tamamlandı olarak işaretle
      ref.read(userDataProvider.notifier).completeTopic(topicId);

      if (earnedDiamonds > 0) {
        ref.read(userDataProvider.notifier).addDiamonds(earnedDiamonds);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonucu'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tebrikler!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Testi başarıyla tamamladın.', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 32),
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$correctAnswers', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      Text('DOĞRU', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('$totalQuestions sorudan $correctAnswers tanesini doğru cevapladın.', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (earnedDiamonds > 0)
                Chip(
                  avatar: Icon(Icons.diamond, color: theme.colorScheme.secondary),
                  label: Text('$earnedDiamonds Elmas Kazandın!', style: const TextStyle(fontWeight: FontWeight.bold)),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
