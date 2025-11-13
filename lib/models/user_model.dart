// lib/models/user_model.dart
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

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        usersId: json['usersid'],
        email: json['email'],
        passwordHash: json['passwordhash'],
        fullName: json['fullname'],
        role: json['role'],
        profileImageUrl: json['profileimageurl'],
        phoneNumber: json['phonenumber'],
        bio: json['bio'],
        organizationId: json['organizationid'],
        userGroupId: json['usergroupid'],
        lastUpdateDate: json['lastupdatedate'] != null
            ? DateTime.parse(json['lastupdatedate'])
            : null,
        lastUpdateUser: json['lastupdateuser'],
        dateCreated: json['datecreated'] != null
            ? DateTime.parse(json['datecreated'])
            : null,
        userCreated: json['usercreated'],
      );

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
