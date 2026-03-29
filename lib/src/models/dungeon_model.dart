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
    this.stageDifficulties = const [],
    this.stageExpRewards = const [],
    this.stageGoldRewards = const [],
    this.currentStageIndex = 0,
    this.status = DungeonStatus.active,
    DateTime? createdAt,
    this.completedAt,
    this.failedAt,
    this.isRedGate = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;

  /// Заголовки этапов (1..N).
  final List<String> stageTitles;
  final List<String> stageDescriptions;

  /// Награды из ИИ (параллельно этапам); пусто — дефолты в [DatabaseService].
  final List<int> stageDifficulties;
  final List<int> stageExpRewards;
  final List<int> stageGoldRewards;

  final int currentStageIndex;
  final DungeonStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final bool isRedGate;

  int get totalStages => stageTitles.length;
  bool get isActive => status == DungeonStatus.active;

  Dungeon copyWith({
    String? title,
    String? description,
    List<String>? stageTitles,
    List<String>? stageDescriptions,
    List<int>? stageDifficulties,
    List<int>? stageExpRewards,
    List<int>? stageGoldRewards,
    int? currentStageIndex,
    DungeonStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? failedAt,
    bool? isRedGate,
  }) {
    return Dungeon(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      stageTitles: stageTitles ?? this.stageTitles,
      stageDescriptions: stageDescriptions ?? this.stageDescriptions,
      stageDifficulties: stageDifficulties ?? this.stageDifficulties,
      stageExpRewards: stageExpRewards ?? this.stageExpRewards,
      stageGoldRewards: stageGoldRewards ?? this.stageGoldRewards,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      isRedGate: isRedGate ?? this.isRedGate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'stageTitles': stageTitles,
      'stageDescriptions': stageDescriptions,
      'stageDifficulties': stageDifficulties,
      'stageExpRewards': stageExpRewards,
      'stageGoldRewards': stageGoldRewards,
      'currentStageIndex': currentStageIndex,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'isRedGate': isRedGate,
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
      stageDifficulties: _parseIntList(map['stageDifficulties']),
      stageExpRewards: _parseIntList(map['stageExpRewards']),
      stageGoldRewards: _parseIntList(map['stageGoldRewards']),
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
      isRedGate: map['isRedGate'] == true,
    );
  }

  static List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      if (e is num) return e.toInt();
      return int.tryParse(e.toString()) ?? 0;
    }).toList();
  }
}

