import 'dart:convert';

class Poem {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final DateTime? deletedAt;
  final List<String> tags;

  Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.deletedAt,
    this.tags = const [],
  });

  Poem copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    DateTime? deletedAt,
    bool nullifyDeletedAt = false,
    List<String>? tags,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      deletedAt: nullifyDeletedAt ? null : (deletedAt ?? this.deletedAt),
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_pinned': isPinned ? 1 : 0,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'tags': tags.join(','),
    };
  }

  factory Poem.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      parsedTags = map['tags'].toString().split(',').where((t) => t.trim().isNotEmpty).toList();
    }

    DateTime parseDate(dynamic val) {
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Poem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: parseDate(map['updated_at'] ?? map['updatedAt']),
      isPinned: (map['is_pinned'] == 1 || map['isPinned'] == true),
      deletedAt: map['deleted_at'] != null || map['deletedAt'] != null
          ? parseDate(map['deleted_at'] ?? map['deletedAt'])
          : null,
      tags: parsedTags,
    );
  }

  String toJson() => json.encode(toMap());

  factory Poem.fromJson(String source) => Poem.fromMap(json.decode(source));
}
