// lib/models/user_model.dart
import 'package:flutter/material.dart';

class AppUser {
  final int? usersId;
  final String email;
  final String passwordHash;
  final String fullName;
  final String role;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? bio;
  final int? organizationId;
  final int? userGroupId;
  final DateTime? lastUpdateDate;
  final String lastUpdateUser;
  final DateTime? dateCreated;
  final String userCreated;

  AppUser({
    this.usersId,
    required this.email,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.profileImageUrl,
    this.phoneNumber,
    this.bio,
    this.organizationId,
    this.userGroupId,
    this.lastUpdateDate,
    required this.lastUpdateUser,
    this.dateCreated,
    required this.userCreated,
  });

 factory AppUser.fromJson(Map<String, dynamic> json) {
  // ✅ Try multiple case variations for UsersId
  int? usersId = json['usersid'] as int? ?? 
                 json['UsersId'] as int? ?? 
                 json['UsersID'] as int? ?? 
                 json['USERSID'] as int?;
  
  debugPrint('🔍 Parsing AppUser - usersId: $usersId');
  
  return AppUser(
    usersId: usersId,
    email: json['email'] ?? json['Email'] ?? '',
    passwordHash: json['passwordhash'] ?? json['PasswordHash'] ?? '',
    fullName: json['fullname'] ?? json['FullName'] ?? '',
    role: json['role'] ?? json['Role'] ?? '',
    profileImageUrl: json['profileimageurl'] ?? json['ProfileImageUrl'],
    phoneNumber: json['phonenumber'] ?? json['PhoneNumber'],
    bio: json['bio'] ?? json['Bio'],
    organizationId: json['organizationid'] as int? ?? json['OrganizationId'] as int?,
    userGroupId: json['usergroupid'] as int? ?? json['UserGroupId'] as int?,
    lastUpdateDate: json['lastupdatedate'] != null
        ? DateTime.parse(json['lastupdatedate'])
        : (json['LastUpdateDate'] != null 
            ? DateTime.parse(json['LastUpdateDate'])
            : null),
    lastUpdateUser: json['lastupdateuser'] ?? json['LastUpdateUser'] ?? '',
    dateCreated: json['datecreated'] != null
        ? DateTime.parse(json['datecreated'])
        : (json['DateCreated'] != null 
            ? DateTime.parse(json['DateCreated'])
            : null),
    userCreated: json['usercreated'] ?? json['UserCreated'] ?? '',
  );
}

  Map<String, dynamic> toJson() => {
        'email': email,
        'passwordhash': passwordHash,
        'fullname': fullName,
        'role': role,
        'profileimageurl': profileImageUrl,
        'phonenumber': phoneNumber,
        'bio': bio,
        'organizationid': organizationId,
        'usergroupid': userGroupId,
        'lastupdateuser': lastUpdateUser,
        'usercreated': userCreated,
      };
}
