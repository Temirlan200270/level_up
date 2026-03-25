// Модель статов охотника
class Stats {
  final int strength; // Сила
  final int agility; // Ловкость
  final int intelligence; // Интеллект
  final int vitality; // Живучесть
  final int availablePoints; // Доступные очки для распределения

  const Stats({
    this.strength = 0,
    this.agility = 0,
    this.intelligence = 0,
    this.vitality = 0,
    this.availablePoints = 0,
  });

  /// Сумма базовых статов без availablePoints.
  int get total => strength + agility + intelligence + vitality;

  /// Пассивный бонус от экипировки (availablePoints не меняется).
  Stats mergeEquipmentBonus(Stats bonus) {
    return Stats(
      strength: strength + bonus.strength,
      agility: agility + bonus.agility,
      intelligence: intelligence + bonus.intelligence,
      vitality: vitality + bonus.vitality,
      availablePoints: availablePoints,
    );
  }

  // Конвертация в Map для хранения
  Map<String, dynamic> toMap() {
    return {
      'strength': strength,
      'agility': agility,
      'intelligence': intelligence,
      'vitality': vitality,
      'availablePoints': availablePoints,
    };
  }

  // Создание объекта из Map
  factory Stats.fromMap(Map<String, dynamic> map) {
    return Stats(
      strength: (map['strength'] as num?)?.toInt() ?? 0,
      agility: (map['agility'] as num?)?.toInt() ?? 0,
      intelligence: (map['intelligence'] as num?)?.toInt() ?? 0,
      vitality: (map['vitality'] as num?)?.toInt() ?? 0,
      availablePoints: (map['availablePoints'] as num?)?.toInt() ?? 0,
    );
  }

  Stats copyWith({
    int? strength,
    int? agility,
    int? intelligence,
    int? vitality,
    int? availablePoints,
  }) {
    return Stats(
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intelligence: intelligence ?? this.intelligence,
      vitality: vitality ?? this.vitality,
      availablePoints: availablePoints ?? this.availablePoints,
    );
  }

  // Добавить очки к стату
  Stats addToStat(String statName, int points) {
    // Проверяем, что есть достаточно доступных очков
    if (availablePoints < points || points <= 0) {
      return this;
    }

    switch (statName) {
      case 'strength':
        return copyWith(
          strength: strength + points,
          availablePoints: availablePoints - points,
        );
      case 'agility':
        return copyWith(
          agility: agility + points,
          availablePoints: availablePoints - points,
        );
      case 'intelligence':
        return copyWith(
          intelligence: intelligence + points,
          availablePoints: availablePoints - points,
        );
      case 'vitality':
        return copyWith(
          vitality: vitality + points,
          availablePoints: availablePoints - points,
        );
      default:
        return this;
    }
  }
}
