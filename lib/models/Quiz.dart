class Quiz {
  final int id;
  final String title;
  final String description;
  final String status;

  Quiz({required this.id, required this.title, required this.description, required this.status});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
    );
  }
}