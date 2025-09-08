import 'User.dart';

class Review {
  final int? id;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;
  final String? psychologistCode;
  final User? user; // người review
  final int? appointmentId; // chỉ giữ id để tránh vòng lặp vô hạn

  Review({
    this.id,
    this.rating,
    this.comment,
    this.createdAt,
    this.psychologistCode,
    this.user,
    this.appointmentId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      psychologistCode: json['psychologistCode'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      appointmentId: json['appointment']?['id'], // tránh nested loop
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "rating": rating,
      "comment": comment,
      "createdAt": createdAt?.toIso8601String(),
      "psychologistCode": psychologistCode,
      "user": user?.toJson(),
      "appointment": appointmentId != null ? {"id": appointmentId} : null,
    };
  }
}