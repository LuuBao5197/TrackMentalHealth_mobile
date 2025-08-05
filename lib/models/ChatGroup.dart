import 'User.dart';

class ChatGroup {
  final int id;
  final String name;
  final String des;
  final String avt;
  final DateTime createdAt;
  final User createdBy;
  final int maxMember;
  final List<User> members;

  ChatGroup({
    required this.id,
    required this.name,
    required this.des,
    required this.avt,
    required this.createdAt,
    required this.createdBy,
    required this.maxMember,
    required this.members,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'],
      name: json['name'] ?? '',
      des: json['des'] ?? '',
      avt: json['avt'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: User.fromJson(json['createdBy']),
      maxMember: json['maxMember'] ?? 0,
      members: (json['members'] as List<dynamic>)
          .map((e) => User.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'des': des,
      'avt': avt,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy.toJson(),
      'maxMember': maxMember,
      'members': members.map((e) => e.toJson()).toList(),
    };
  }
}
