import 'package:uuid/uuid.dart';

// Тип квеста
enum QuestType {
  daily,      // Ежедневный
  weekly,     // Еженедельный
  special,    // Особый
  story,      // Сюжетный
}

// Статус квеста
enum QuestStatus {
  active,     // Активный
  completed,  // Выполнен
  failed,     // Провален
  expired,    // Истёк
}

// Модель квеста
class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestStatus status;
  final int experienceReward;  // Награда опыта
  final int statPointsReward;  // Награда очков статов
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;   // Срок выполнения (для ежедневных/еженедельных)

  Quest({
    String? id,
    required this.title,
    required this.description,
    this.type = QuestType.daily,
    this.status = QuestStatus.active,
    this.experienceReward = 10,
    this.statPointsReward = 0,
    DateTime? createdAt,
    this.completedAt,
    this.expiresAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Проверка, истёк ли квест
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!) && status == QuestStatus.active;
  }

  // Проверка, можно ли выполнить квест
  bool get canComplete => status == QuestStatus.active && !isExpired;

  // Отметить квест как выполненный
  Quest complete() {
    if (!canComplete) return this;
    return copyWith(
      status: QuestStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  // Отметить квест как проваленный
  Quest fail() {
    return copyWith(status: QuestStatus.failed);
  }

  // Конвертация в Map для хранения
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'experienceReward': experienceReward,
      'statPointsReward': statPointsReward,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  // Создание объекта из Map
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
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
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
    DateTime? createdAt,
    DateTime? completedAt,
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
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

// Предустановленные квесты для демо
class DefaultQuests {
  static List<Quest> getDailyQuests() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    return [
      Quest(
        title: 'Утренняя зарядка',
        description: 'Выполни 10 отжиманий',
        type: QuestType.daily,
        experienceReward: 15,
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Чтение',
        description: 'Прочитай 10 страниц книги',
        type: QuestType.daily,
        experienceReward: 10,
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Водный баланс',
        description: 'Выпей 2 литра воды',
        type: QuestType.daily,
        experienceReward: 10,
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Изучение нового',
        description: 'Потрать 30 минут на изучение нового навыка',
        type: QuestType.daily,
        experienceReward: 20,
        expiresAt: tomorrow,
      ),
      Quest(
        title: 'Прогулка',
        description: 'Соверши прогулку на 30 минут',
        type: QuestType.daily,
        experienceReward: 15,
        expiresAt: tomorrow,
      ),
    ];
  }
}

