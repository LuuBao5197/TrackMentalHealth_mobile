import 'user.dart';

class Psychologist {
  final int? id;
  final String? licenseNumber;
  final double? experienceYears;
  final User? usersID;
  final int? bio;

  Psychologist({
    this.id,
    this.licenseNumber,
    this.experienceYears,
    this.usersID,
    this.bio,
  });

  // Convert JSON -> Object
  factory Psychologist.fromJson(Map<String, dynamic> json) {
    return Psychologist(
      id: json['id'],
      licenseNumber: json['licenseNumber'],
      experienceYears: (json['experienceYears'] != null)
          ? (json['experienceYears'] as num).toDouble()
          : null,
      usersID: json['usersID'] != null ? User.fromJson(json['usersID']) : null,
      bio: json['bio'],
    );
  }

  // Convert Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'usersID': usersID?.toJson(),
      'bio': bio,
    };
  }
}
