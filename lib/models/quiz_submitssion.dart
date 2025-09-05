class QuizSubmission {
  final int quizId;
  final int userId;
  final List<AnswerDto> answers;

  QuizSubmission({
    required this.quizId,
    required this.userId,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
    "quizId": quizId,
    "userId": userId,
    "answers": answers.map((a) => a.toJson()).toList(),
  };
}

class AnswerDto {
  final int questionId;
  final String? userInput;
  final List<int>? selectedOptionIds;
  final List<MatchingPair>? matchingPairs;
  final List<OrderingItem>? orderingItems;

  AnswerDto({
    required this.questionId,
    this.userInput,
    this.selectedOptionIds,
    this.matchingPairs,
    this.orderingItems,
  });

  Map<String, dynamic> toJson() {
    final map = {
      "questionId": questionId,
      "userInput": userInput,
      "selectedOptionIds": selectedOptionIds,
      "matchingPairs": matchingPairs?.map((m) => m.toJson()).toList(),
      "orderingItems": orderingItems?.map((o) => o.toJson()).toList(),
    };

    // ⚡ auto bỏ field null
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class MatchingPair {
  final String leftText;
  final String rightText;

  MatchingPair({required this.leftText, required this.rightText});

  Map<String, dynamic> toJson() => {
    "leftText": leftText,
    "rightText": rightText,
  };
}

class OrderingItem {
  final int itemId;
  final String text;
  final int userOrder;

  OrderingItem({
    required this.itemId,
    required this.text,
    required this.userOrder,
  });

  Map<String, dynamic> toJson() => {
    "itemId": itemId,
    "text": text,
    "userOrder": userOrder,
  };
}
