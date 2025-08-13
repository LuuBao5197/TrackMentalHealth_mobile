import 'package:flutter/foundation.dart';
import 'role.dart';

class User {
  final int? id;
  final String? username;
  final String? email;
  final String? avatar;
  final String? status;
  final String? token;
  final String? refreshToken;
  final String? otp;
  final DateTime? otpExpiry;
  final Role? role;
  final String? fullName;
  final String? address;
  final DateTime? dob;
  final String? gender;
  final bool? isApproved;

  User({
    this.id,
    this.username,
    this.email,
    this.avatar,
    this.status,
    this.token,
    this.refreshToken,
    this.otp,
    this.otpExpiry,
    this.role,
    this.fullName,
    this.address,
    this.dob,
    this.gender,
    this.isApproved,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      status: json['status'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refreshtoken'] as String?,
      otp: json['otp'] as String?,
      otpExpiry: json['otpExpiry'] != null
          ? DateTime.parse(json['otpExpiry'] as String)
          : null,
      role: json['role'] != null
          ? Role.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      fullName: json['fullname'] as String?,
      address: json['address'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      gender: json['gender'] as String?,
      isApproved: json['isApproved'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
      if (status != null) 'status': status,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refreshtoken': refreshToken,
      if (otp != null) 'otp': otp,
      if (otpExpiry != null) 'otpExpiry': otpExpiry!.toIso8601String(),
      if (role != null) 'role': role!.toJson(),
      if (fullName != null) 'fullname': fullName,
      if (address != null) 'address': address,
      if (dob != null) 'dob': dob!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (isApproved != null) 'isApproved': isApproved,
    };
  }
}
