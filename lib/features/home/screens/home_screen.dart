import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/features/home/providers/home_providers.dart';
import 'package:kpss_tarih_app/features/random_test/screens/random_test_screen.dart';
import 'package:kpss_tarih_app/features/topics/screens/category_list_screen.dart';

// Ana sayfada toplam konu sayısını göstermek için yeni provider
final totalTopicsCountProvider = FutureProvider<int>((ref) async {
  final contentService = ref.watch(contentServiceProvider);
  return await contentService.getTotalTopicsCount();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalTopicsAsync = ref.watch(totalTopicsCountProvider);
    final userData = ref.watch(userDataProvider);
    final theme = Theme.of(context);

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

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Konulara Göz At', icon: Icons.menu_book_rounded, color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryListScreen())),
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
