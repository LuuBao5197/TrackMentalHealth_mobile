class QuizSubmitResponse {
  final int totalScore;
  final String resultLabel;

  QuizSubmitResponse({required this.totalScore, required this.resultLabel});

  factory QuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResponse(
      totalScore: json["totalScore"] ?? 0,
      resultLabel: json["resultLabel"] ?? "",
    );
  }
}
