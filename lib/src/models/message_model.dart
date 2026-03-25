import 'package:uuid/uuid.dart';

/// Модель сообщения в чате с Системой
class MessageModel {
  final String id;
  final String content;
  final bool isFromSystem;
  final DateTime timestamp;

  MessageModel({
    String? id,
    required this.content,
    required this.isFromSystem,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isFromSystem': isFromSystem,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      content: map['content'] as String,
      isFromSystem: map['isFromSystem'] as bool,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

