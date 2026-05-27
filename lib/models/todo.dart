import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
  });

  factory Todo.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      userId: d['user_id'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      isDone: d['is_done'] ?? false,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'is_done': isDone,
        'created_at': Timestamp.fromDate(createdAt),
      };

  Todo copyWith({bool? isDone}) => Todo(
        id: id,
        userId: userId,
        title: title,
        description: description,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
      );
}
