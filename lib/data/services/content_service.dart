import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:kpss_tarih_app/data/models/question_model.dart';
import 'package:kpss_tarih_app/data/models/topic_model.dart';
import 'package:kpss_tarih_app/features/topics/models/category_model.dart';

class ContentService {
  // Okunan kategori dosyalarını bellekte tutarak performansı artırır.
  final Map<String, List<Topic>> _cachedTopics = {};
  // Püf noktalarını bellekte tutar.
  Map<String, dynamic>? _cachedTips;

  /// Belirli bir kategoriye ait konuları JSON dosyasından okur.
  Future<List<Topic>> getTopicsForCategory(String jsonPath) async {
    // Eğer istenen kategori daha önce okunup belleğe alındıysa, tekrar okumadan doğrudan döndür.
    if (_cachedTopics.containsKey(jsonPath)) {
      return _cachedTopics[jsonPath]!;
    }
    try {
      final String response = await rootBundle.loadString(jsonPath);
      final data = await json.decode(response);

      final List<Topic> topics = (data['topics'] as List)
          .map((topicJson) => Topic.fromJson(topicJson))
          .toList();

      _cachedTopics[jsonPath] = topics; // Okunan veriyi belleğe al
      return topics;
    } catch (e) {
      // Hata durumunda (örn: dosya bulunamadı) boş liste döndür ve hatayı konsola yazdır.
      print('Error loading topics from $jsonPath: $e');
      return [];
    }
  }

  /// Belirli bir konunun sorularını getirir.
  /// Bu fonksiyon, doğru konuyu bulmak için tüm kategori dosyalarını tarar.
  Future<List<Question>> getQuestionsForTopic(String topicId) async {
    for (final category in historyCategories) {
      final topics = await getTopicsForCategory(category.jsonPath);
      for (final topic in topics) {
        if (topic.id == topicId) {
          return topic.questions;
        }
      }
    }
    // Konu hiçbir kategoride bulunamazsa boş liste döndür.
    return [];
  }

  /// Ana sayfadaki ilerleme çubuğu için tüm kategorilerdeki toplam konu sayısını hesaplar.
  Future<int> getTotalTopicsCount() async {
    int totalCount = 0;
    for (final category in historyCategories) {
      final topics = await getTopicsForCategory(category.jsonPath);
      totalCount += topics.length;
    }
    return totalCount;
  }

  /// Rastgele sorular ekranı için 'random_questions.json' dosyasını okur.
  Future<List<Question>> getRandomQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/random_questions.json');
      final data = await json.decode(response);
      final List<Question> randomQuestions = (data['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      return randomQuestions;
    } catch (e) {
      print('Error loading random questions: $e');
      return [];
    }
  }

  /// Belirli bir konuya ait püf noktasını 'kpss_tarih_tips.json' dosyasından getirir.
  Future<String?> getTipsForTopic(String topicId) async {
    // Eğer püf noktaları daha önce yüklenmediyse, dosyadan oku ve belleğe al.
    if (_cachedTips == null) {
      try {
        final String response = await rootBundle.loadString('assets/kpss_tarih_tips.json');
        final data = await json.decode(response);
        _cachedTips = data['tips'];
      } catch (e) {
        print('Error loading tips JSON: $e');
        _cachedTips = {}; // Hata durumunda boş harita ata
      }
    }
    // İstenen topicId'ye ait püf noktasını döndür.
    return _cachedTips?[topicId];
  }
}
