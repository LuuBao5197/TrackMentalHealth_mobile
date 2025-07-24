class AnswerRequest {
  final int questionId;
  final int selectedOptionId;

  AnswerRequest({required this.questionId, required this.selectedOptionId});

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedOptionId': selectedOptionId,
  };
}

class TestSubmissionRequest {
  final int userId;
  final int testId;
  final int totalScore;
  final List<AnswerRequest> answers;

  TestSubmissionRequest({
    required this.userId,
    required this.testId,
    required this.totalScore,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'testId': testId,
    'totalScore': totalScore,
    'answers': answers.map((a) => a.toJson()).toList(),
  };
}
