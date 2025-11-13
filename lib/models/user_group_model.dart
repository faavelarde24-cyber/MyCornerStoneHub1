// lib/models/user_group_model.dart
class UserGroup {
  final int? userGroupId;
  final String organizationId;
  final String groupName;
  final String groupType;
  final String? description;
  final String groupCode;
  final int memberCount;
  final DateTime? lastUpdateDate;
  final String lastUpdateUser;
  final DateTime? dateCreated;
  final String userCreated;

  UserGroup({
    this.userGroupId,
    required this.organizationId,
    required this.groupName,
    required this.groupType,
    this.description,
    required this.groupCode,
    this.memberCount = 0,
    this.lastUpdateDate,
    required this.lastUpdateUser,
    this.dateCreated,
    required this.userCreated,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => UserGroup(
        userGroupId: json['usergroupid'],
        organizationId: json['organizationid'],
        groupName: json['groupname'],
        groupType: json['grouptype'],
        description: json['description'],
        groupCode: json['groupcode'],
        memberCount: json['membercount'] ?? 0,
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
        'organizationid': organizationId,
        'groupname': groupName,
        'grouptype': groupType,
        'description': description,
        'groupcode': groupCode,
        'membercount': memberCount,
        'lastupdateuser': lastUpdateUser,
        'usercreated': userCreated,
      };
}
