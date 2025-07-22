
class Question {
  // ID'ye artık gerek yok, JSON'dan sırayla gelecek.
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  // JSON'dan Question nesnesi oluşturan factory constructor
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
    );
  }
}


// --------------------------------------------------------------------


