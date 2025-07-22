import 'package:kpss_tarih_app/data/models/question_model.dart';

class Topic {
  final String id;
  final String title;
  final String content;
  final List<Question> questions;

  Topic({
    required this.id,
    required this.title,
    required this.content,
    required this.questions,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    var questionList = json['questions'] as List;
    List<Question> questions = questionList.map((q) => Question.fromJson(q)).toList();

    return Topic(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      questions: questions,
    );
  }
}
