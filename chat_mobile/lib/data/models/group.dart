// lib/data/models/group.dart

class Group {
  final int id;
  final String name;
  final String? description;
  final String? avatar;
  final int createdBy;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.createdBy,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatar: json['avatar'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}