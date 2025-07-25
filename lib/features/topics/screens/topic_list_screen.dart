import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/data/models/topic_model.dart';
import 'package:kpss_tarih_app/features/topics/models/category_model.dart';
import 'package:kpss_tarih_app/features/topics/screens/topic_detail_screen.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart'; // Content service için eklendi

// Belirli bir kategoriye ait konuları getiren yeni provider
final topicsForCategoryProvider = FutureProvider.autoDispose.family<List<Topic>, String>((ref, jsonPath) {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getTopicsForCategory(jsonPath);
});

class TopicListScreen extends ConsumerWidget {
  final Category category;
  const TopicListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kategoriye ait konuları asenkron olarak yükle
    final topicsAsyncValue = ref.watch(topicsForCategoryProvider(category.jsonPath));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // *** HATA DÜZELTMESİ: 'title' yerine modeldeki doğru alan olan 'name' kullanıldı. ***
        title: Text(category.title),
      ),
      body: topicsAsyncValue.when(
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('Bu kategoride henüz konu eklenmemiş.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: category.color,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(topic.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopicDetailScreen(topic: topic),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Konular yüklenirken bir hata oluştu: $err')),
      ),
    );
  }
}
