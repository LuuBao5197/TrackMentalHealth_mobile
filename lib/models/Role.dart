class Role {
  final int? id;
  final String? roleName;

  Role({this.id, this.roleName});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id'],
    roleName: json['roleName'],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (roleName != null) 'roleName': roleName,
  };
}
