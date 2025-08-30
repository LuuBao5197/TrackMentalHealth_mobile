import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:trackmentalhealth/models/Question.dart';

class QuestionRenderer extends StatelessWidget {
  final Question question;
  final dynamic answer;
  final Function(dynamic) onChanged;
  final VoidCallback? onMarkReview; // 👈 thêm thuộc tính này

  const QuestionRenderer({
    Key? key,
    required this.question,
    required this.answer,
    required this.onChanged,
    this.onMarkReview, required bool isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Html(data: question.text), // 👈 hiển thị câu hỏi
            if (onMarkReview != null)
              TextButton(
                onPressed: onMarkReview,
                child: const Text("Review later", style: TextStyle(color: Colors.purple)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAnswerWidget(), // phần switch-case bạn đã viết
      ],
    );
  }

  Widget _buildAnswerWidget() {
    switch (question.type) {
      case QuestionType.singleChoice:
        return Column(
          children: question.options.map((opt) {
            return RadioListTile<int>(
              title: Text(opt.content),
              value: opt.id,
              groupValue: answer,
              onChanged: (val) => onChanged(val),
            );
          }).toList(),
        );

      case QuestionType.multiChoice:
        return Column(
          children: question.options.map((opt) {
            final selected = (answer ?? <int>[]).contains(opt.id);
            return CheckboxListTile(
              title: Text(opt.content),
              value: selected,
              onChanged: (val) {
                final newList = List<int>.from(answer ?? []);
                if (val == true) {
                  newList.add(opt.id);
                } else {
                  newList.remove(opt.id);
                }
                onChanged(newList);
              },
            );
          }).toList(),
        );

      case QuestionType.scoreBased:
        return Column(
          children: question.options.map((opt) {
            return RadioListTile<int>(
              title: Text("${opt.content} (${opt.score})"),
              value: opt.id,
              groupValue: answer,
              onChanged: (val) => onChanged(val),
            );
          }).toList(),
        );

      case QuestionType.textInput:
        return TextFormField(
          initialValue: answer ?? "",
          decoration: const InputDecoration(
            hintText: "Nhập câu trả lời...",
          ),
          onChanged: (val) => onChanged(val),
        );

      case QuestionType.ordering:
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            final list = List<String>.from(answer ?? question.orderingItems!.map((e) => e.content));
            if (newIndex > oldIndex) newIndex -= 1;
            final item = list.removeAt(oldIndex);
            list.insert(newIndex, item);
            onChanged(list);
          },
          children: [
            for (int i = 0; i < (answer ?? question.orderingItems!.map((e) => e.content)).length; i++)
              ListTile(
                key: ValueKey(i),
                title: Text((answer ?? question.orderingItems!.map((e) => e.content)).toList()[i]),
              ),
          ],
        );

      case QuestionType.matching:
        return Column(
          children: question.matchingItems!.map((pair) {
            return Row(
              children: [
                Expanded(child: Text(pair.left)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: answer?[pair.left],
                    items: question.matchingItems!
                        .map((e) => DropdownMenuItem(
                      value: e.right,
                      child: Text(e.right),
                    ))
                        .toList(),
                    onChanged: (val) {
                      final newMap = Map<String, String>.from(answer ?? {});
                      newMap[pair.left] = val!;
                      onChanged(newMap);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
