import 'enums.dart';

class Skill {
  final String id;
  final String name;
  final String description;
  final String branch; // assassin/mage/tank
  final int tier;
  final int level;
  final int maxLevel;
  final int cost;
  final SkillType type;
  final String? parentId;
  final DateTime? lastUsed; // Время последнего использования (для cooldown)
  final int? cooldownSeconds; // Время перезарядки в секундах
  final int? durationSeconds; // Длительность эффекта в секундах

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.branch,
    required this.tier,
    this.level = 1,
    this.maxLevel = 5,
    required this.cost,
    required this.type,
    this.parentId,
    this.lastUsed,
    this.cooldownSeconds,
    this.durationSeconds,
  });

  /// Проверяет, готов ли навык к использованию (прошел ли cooldown)
  bool get isReady {
    if (lastUsed == null || cooldownSeconds == null) return true;
    final timeSinceLastUse = DateTime.now().difference(lastUsed!);
    return timeSinceLastUse.inSeconds >= cooldownSeconds!;
  }

  /// Возвращает оставшееся время cooldown в секундах
  int? get remainingCooldown {
    if (lastUsed == null || cooldownSeconds == null) return null;
    final timeSinceLastUse = DateTime.now().difference(lastUsed!);
    final remaining = cooldownSeconds! - timeSinceLastUse.inSeconds;
    return remaining > 0 ? remaining : null;
  }

  /// Создает копию навыка с обновленным временем использования
  Skill withLastUsed(DateTime time) {
    return Skill(
      id: id,
      name: name,
      description: description,
      branch: branch,
      tier: tier,
      level: level,
      maxLevel: maxLevel,
      cost: cost,
      type: type,
      parentId: parentId,
      lastUsed: time,
      cooldownSeconds: cooldownSeconds,
      durationSeconds: durationSeconds,
    );
  }
}
