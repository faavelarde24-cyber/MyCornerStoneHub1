class Feedback {
  final String id;
  final String? userId;
  final String name;
  final String email;
  final String category;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  Feedback({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'category': category,
    'subject': subject,
    'message': message,
    'status': status,
  };
}