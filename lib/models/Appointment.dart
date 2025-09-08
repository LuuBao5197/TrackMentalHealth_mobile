import 'dart:convert';

import 'Psychologist.dart';
import 'Review.dart';
import 'User.dart';

class Appointment {
  final int? id;
  final DateTime? timeStart;
  late final String? status;
  final User? user;
  final Psychologist? psychologist;
  final String? note;
  final Review? review;

  Appointment({
    this.id,
    this.timeStart,
    this.status,
    this.user,
    this.psychologist,
    this.note,
    this.review,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      timeStart: json['timeStart'] != null
          ? DateTime.parse(json['timeStart'])
          : null,
      status: json['status'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      psychologist: json['psychologist'] != null
          ? Psychologist.fromJson(json['psychologist'])
          : null,
      note: json['note'],
      review: json['review'] != null ? Review.fromJson(json['review']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "timeStart": timeStart?.toIso8601String(),
      "status": status,
      "user": user?.toJson(),
      "psychologist": psychologist?.toJson(),
      "note": note,
      "review": review?.toJson(),
    };
  }
}