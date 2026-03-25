import 'package:uuid/uuid.dart';

// Тип квеста
enum QuestType {
  daily, // Ежедневный
  weekly, // Еженедельный
  special, // Особый
  story, // Сюжетный
  urgent, // Срочный (короткое окно, повышенная награда)

  /// Штрафной квест Системы (Штрафная зона); не создаётся вручную.
  penalty,
}

// Статус квеста
enum QuestStatus { active, completed, failed, expired }

// Модель квеста
class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestStatus status;
  final int experienceReward;
  final int statPointsReward;

  /// Фиксированная награда золотом при завершении.
  final int goldReward;

  /// Теги для аналитики и скрытых классов (например code, sport).
  final List<String> tags;

  /// 1–5, влияет на отображение и промпты ИИ.
  final int difficulty;

  /// Обязательный квест — при провале применяются штрафы.
  final bool mandatory;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? expiresAt;

  Quest({
    String? id,
    required this.title,
    required this.description,
    this.type = QuestType.daily,
    this.status = QuestStatus.active,
    this.experienceReward = 10,
    this.statPointsReward = 0,
    this.goldReward = 0,
    List<String>? tags,
    int difficulty = 1,
    this.mandatory = false,
    DateTime? createdAt,
    this.completedAt,
    this.failedAt,
    this.expiresAt,
  }) : id = id ?? const Uuid().v4(),
       tags = tags ?? const [],
       difficulty = difficulty.clamp(1, 5),
       createdAt = createdAt ?? DateTime.now();

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!) && status == QuestStatus.active;
  }

  bool get canComplete => status == QuestStatus.active && !isExpired;

  bool get canFail => status == QuestStatus.active && !isExpired;

  /// Штрафы за провал — для ежедневных, недельных и помеченных обязательными.
  bool get penalizeOnFailure =>
      mandatory || type == QuestType.daily || type == QuestType.weekly;

  Quest complete() {
    if (!canComplete) return this;
    return copyWith(status: QuestStatus.completed, completedAt: DateTime.now());
  }

  Quest fail() {
    if (!canFail) return this;
    return copyWith(status: QuestStatus.failed, failedAt: DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'experienceReward': experienceReward,
      'statPointsReward': statPointsReward,
      'goldReward': goldReward,
      'tags': tags,
      'difficulty': difficulty,
      'mandatory': mandatory,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: QuestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestType.daily,
      ),
      status: QuestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuestStatus.active,
      ),
      experienceReward: (map['experienceReward'] as num?)?.toInt() ?? 10,
      statPointsReward: (map['statPointsReward'] as num?)?.toInt() ?? 0,
      goldReward: (map['goldReward'] as num?)?.toInt() ?? 0,
      tags:
          (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      difficulty: (map['difficulty'] as num?)?.toInt().clamp(1, 5) ?? 1,
      mandatory: map['mandatory'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      failedAt: map['failedAt'] != null
          ? DateTime.parse(map['failedAt'] as String)
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
    );
  }

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    QuestStatus? status,
    int? experienceReward,
    int? statPointsReward,
    int? goldReward,
    List<String>? tags,
    int? difficulty,
    bool? mandatory,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? expiresAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      experienceReward: experienceReward ?? this.experienceReward,
      statPointsReward: statPointsReward ?? this.statPointsReward,
      goldReward: goldReward ?? this.goldReward,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      mandatory: mandatory ?? this.mandatory,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class DefaultQuests {
  static List<Quest> getDailyQuests() {
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return [
      Quest(
        title: 'Утренняя зарядка',
        description: 'Выполни 10 отжиманий',
        type: QuestType.daily,
        experienceReward: 15,
        goldReward: 8,
        tags: const ['sport', 'health'],
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Чтение',
        description: 'Прочитай 10 страниц книги',
        type: QuestType.daily,
        experienceReward: 10,
        goldReward: 5,
        tags: const ['mind'],
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Водный баланс',
        description: 'Выпей 2 литра воды',
        type: QuestType.daily,
        experienceReward: 10,
        goldReward: 5,
        tags: const ['health'],
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Изучение нового',
        description: 'Потрать 30 минут на изучение нового навыка',
        type: QuestType.daily,
        experienceReward: 20,
        goldReward: 12,
        tags: const ['code', 'study'],
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Прогулка',
        description: 'Соверши прогулку на 30 минут',
        type: QuestType.daily,
        experienceReward: 15,
        goldReward: 8,
        tags: const ['sport'],
        expiresAt: tomorrow,
      ),
    ];
  }
}
