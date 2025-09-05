enum QuestionType { singleChoice, multiChoice, scoreBased, textInput, ordering, matching }

class Question {
  final int id;
  final String text;
  final QuestionType type;
  final List<Option> options;
  final List<OrderingItem>? orderingItems;
  final List<MatchingItem>? matchingItems;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
    this.orderingItems,
    this.matchingItems,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['content'] ?? "",   // 👈 API dùng 'content' chứ không phải 'questionText'
      type: _mapType(json['type']),
      options: (json['options'] as List? ?? [])
          .map((e) => Option.fromJson(e))
          .toList(),
      orderingItems: (json['orderingItems'] as List? ?? [])
          .map((e) => OrderingItem.fromJson(e))
          .toList(),
      matchingItems: (json['matchingItems'] as List? ?? [])
          .map((e) => MatchingItem.fromJson(e))
          .toList(),
    );
  }

  static QuestionType _mapType(String type) {
    switch (type) {
      case "SINGLE_CHOICE": return QuestionType.singleChoice;
      case "MULTI_CHOICE": return QuestionType.multiChoice;
      case "SCORE_BASED": return QuestionType.scoreBased;
      case "TEXT_INPUT": return QuestionType.textInput;
      case "ORDERING": return QuestionType.ordering;
      case "MATCHING": return QuestionType.matching;
      default: return QuestionType.textInput;
    }
  }
  Map<String, dynamic> toAnswerDto(dynamic answer) {
    switch (type) {
      case QuestionType.singleChoice:
      case QuestionType.scoreBased:
        return {
          "questionId": id,
          "selectedOptionIds": answer != null ? [answer] : [],
        };

      case QuestionType.multiChoice:
        return {
          "questionId": id,
          "selectedOptionIds": answer ?? [],
        };

      case QuestionType.textInput:
        return {
          "questionId": id,
          "answerText": answer ?? "",
        };

      case QuestionType.ordering:
        return {
          "questionId": id,
          "ordering": answer ?? [],
        };

      case QuestionType.matching:
        final list = <Map<String, String>>[];
        if (answer != null) {
          (answer as Map<String, String>).forEach((left, right) {
            list.add({"leftText": left, "rightText": right});
          });
        }
        return {
          "questionId": id,
          "matching": list,
        };

      default:
        return {"questionId": id};
    }
  }
}

class Option {
  final int id;
  final String content;
  final int? score;
  Option({required this.id, required this.content, this.score});

  factory Option.fromJson(Map<String, dynamic> json) =>
      Option(id: json['id'], content: json['content'], score: json['score']);
}

class OrderingItem {
  final int id;
  final String content;
  final int correctOrder;

  OrderingItem({
    required this.id,
    required this.content,
    required this.correctOrder,
  });

  factory OrderingItem.fromJson(Map<String, dynamic> json) {
    return OrderingItem(
      id: json['id'],
      content: json['content'] ?? "",
      correctOrder: json['correctOrder'] ?? 0,
    );
  }
}


class MatchingItem {
  final String left;
  final String right;

  MatchingItem({required this.left, required this.right});

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      left: json['leftItem'] ?? "",   // 👈 đổi đúng key
      right: json['rightItem'] ?? "",
    );
  }
}

