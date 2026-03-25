import 'package:uuid/uuid.dart';

enum DungeonStatus { active, completed, failed }

/// Подземелье = цепочка этапов, где спавнится только текущий этап.
class Dungeon {
  Dungeon({
    String? id,
    required this.title,
    required this.description,
    required this.stageTitles,
    required this.stageDescriptions,
    this.currentStageIndex = 0,
    this.status = DungeonStatus.active,
    DateTime? createdAt,
    this.completedAt,
    this.failedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;

  /// Заголовки этапов (1..N).
  final List<String> stageTitles;
  final List<String> stageDescriptions;

  final int currentStageIndex;
  final DungeonStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;

  int get totalStages => stageTitles.length;
  bool get isActive => status == DungeonStatus.active;

  Dungeon copyWith({
    String? title,
    String? description,
    List<String>? stageTitles,
    List<String>? stageDescriptions,
    int? currentStageIndex,
    DungeonStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? failedAt,
  }) {
    return Dungeon(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      stageTitles: stageTitles ?? this.stageTitles,
      stageDescriptions: stageDescriptions ?? this.stageDescriptions,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'stageTitles': stageTitles,
      'stageDescriptions': stageDescriptions,
      'currentStageIndex': currentStageIndex,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
    };
  }

  factory Dungeon.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse((map['createdAt'] ?? '').toString());
    return Dungeon(
      id: map['id']?.toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      stageTitles: (map['stageTitles'] is List)
          ? (map['stageTitles'] as List).map((e) => e.toString()).toList()
          : const [],
      stageDescriptions: (map['stageDescriptions'] is List)
          ? (map['stageDescriptions'] as List).map((e) => e.toString()).toList()
          : const [],
      currentStageIndex: (map['currentStageIndex'] is num)
          ? (map['currentStageIndex'] as num).toInt()
          : 0,
      status: DungeonStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DungeonStatus.active,
      ),
      createdAt: createdAt ?? DateTime.now(),
      completedAt: DateTime.tryParse((map['completedAt'] ?? '').toString()),
      failedAt: DateTime.tryParse((map['failedAt'] ?? '').toString()),
    );
  }
}

