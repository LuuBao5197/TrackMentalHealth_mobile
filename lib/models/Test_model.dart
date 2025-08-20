class TestModel {
  final int id;
  final String title;
  final String description;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
    );
  }
}
