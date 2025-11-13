// lib/models/organization_model.dart
class Organization {
  final int? organizationId;
  final String organizationName;
  final String organizationType;
  final String? address;
  final String? city;
  final String? country;
  final String? phoneNumber;
  final String? website;
  final String? logoUrl;
  final String? settings;
  final String status;
  final DateTime? lastUpdateDate;
  final String lastUpdateUser;
  final DateTime? dateCreated;
  final String userCreated;

  Organization({
    this.organizationId,
    required this.organizationName,
    required this.organizationType,
    this.address,
    this.city,
    this.country,
    this.phoneNumber,
    this.website,
    this.logoUrl,
    this.settings,
    required this.status,
    this.lastUpdateDate,
    required this.lastUpdateUser,
    this.dateCreated,
    required this.userCreated,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        organizationId: json['organizationid'],
        organizationName: json['organizationname'],
        organizationType: json['organizationtype'],
        address: json['address'],
        city: json['city'],
        country: json['country'],
        phoneNumber: json['phonenumber'],
        website: json['website'],
        logoUrl: json['logourl'],
        settings: json['settings'],
        status: json['status'],
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
        'organizationname': organizationName,
        'organizationtype': organizationType,
        'address': address,
        'city': city,
        'country': country,
        'phonenumber': phoneNumber,
        'website': website,
        'logourl': logoUrl,
        'settings': settings,
        'status': status,
        'lastupdateuser': lastUpdateUser,
        'usercreated': userCreated,
      };
}
