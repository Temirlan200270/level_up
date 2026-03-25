import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'item_model.dart';
import 'skill_model.dart';
import 'stats_model.dart';
import 'buff_model.dart';
import '../data/items_data.dart';
import '../data/skills_data.dart';

// Класс слота инвентаря
class InventorySlot {
  final Item item;
  final int quantity;

  const InventorySlot({required this.item, required this.quantity});
}

@immutable
class Hunter {
  final String id;
  final String name;
  final int level;
  
  // ТВОИ НАЗВАНИЯ ПОЛЕЙ
  final double currentExp; 
  final double maxExp;
  
  final Stats stats;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // МОИ НОВЫЕ ПОЛЯ (для магазина и навыков)
  final int gold;
  final int skillPoints;
  final List<InventorySlot> inventory;
  final Map<String, Item?> equipment;
  final List<Skill> skills;
  final List<Buff> activeBuffs; // Временные эффекты

  Hunter({
    String? id,
    required this.name,
    this.level = 1,
    this.currentExp = 0, // Используем currentExp
    double? maxExp,      // Используем maxExp
    Stats? stats,
    DateTime? createdAt,
    this.lastLoginAt,
    // Новые поля
    this.gold = 0,
    this.skillPoints = 0,
    this.inventory = const [],
    this.equipment = const {
      'weapon': null,
      'armor': null,
      'accessory': null,
    },
    this.skills = const [],
    this.activeBuffs = const [],
  })  : id = id ?? const Uuid().v4(),
        maxExp = maxExp ?? (level * 100).toDouble(), // Логика расчета maxExp
        stats = stats ?? const Stats(),
        createdAt = createdAt ?? DateTime.now();

  // Геттеры
  double get experienceToNextLevel => maxExp;
  double get levelProgress => (maxExp == 0) ? 0 : currentExp / maxExp;
  bool get canLevelUp => currentExp >= maxExp;

  // Метод повышения уровня
  Hunter levelUp() {
    if (!canLevelUp) return this;

    final newLevel = level + 1;
    final remainingExp = currentExp - maxExp;
    final newMaxExp = (newLevel * 100).toDouble();

    return copyWith(
      level: newLevel,
      currentExp: remainingExp,
      maxExp: newMaxExp,
      // Бонусы за уровень
      stats: stats.copyWith(availablePoints: stats.availablePoints + 5),
      skillPoints: skillPoints + 1,
    );
  }

  // COPYWITH (Синхронизирован с полями)
  Hunter copyWith({
    String? id,
    String? name,
    int? level,
    double? currentExp,
    double? maxExp,
    Stats? stats,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? gold,
    int? skillPoints,
    List<InventorySlot>? inventory,
    Map<String, Item?>? equipment,
    List<Skill>? skills,
    List<Buff>? activeBuffs,
  }) {
    return Hunter(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      maxExp: maxExp ?? this.maxExp,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      gold: gold ?? this.gold,
      skillPoints: skillPoints ?? this.skillPoints,
      inventory: inventory ?? this.inventory,
      equipment: equipment ?? this.equipment,
      skills: skills ?? this.skills,
      activeBuffs: activeBuffs ?? this.activeBuffs,
    );
  }

  // Вычисляет финальный опыт с учетом модификаторов (без добавления)
  int calculateFinalExperience(int baseExp) {
    if (baseExp <= 0) return 0;
    
    // Применяем модификаторы опыта от экипировки и баффов
    double expMultiplier = 1.0;
    
    // Проверяем активные баффы
    for (final buff in activeBuffs) {
      if (buff.isExpired) continue;
      if (buff.effectId == 'xp_multiplier' || buff.effectId == 'sprint_bonus') {
        expMultiplier *= (buff.value as num).toDouble();
      }
    }
    
    // Проверяем пассивные статы экипировки
    for (final equippedItem in equipment.values) {
      if (equippedItem?.effects != null) {
        final effects = equippedItem!.effects!;
        if (effects.containsKey('xp_bonus')) {
          expMultiplier += (effects['xp_bonus'] as num).toDouble();
        }
        if (effects.containsKey('xp_hard_quest')) {
          // TODO: Проверять тип квеста (сложный/обычный) при получении опыта
          expMultiplier += (effects['xp_hard_quest'] as num).toDouble();
        }
      }
    }
    
    return (baseExp * expMultiplier).round();
  }

  Hunter addExperience(int exp) {
    if (exp <= 0) return this;

    final gain = calculateFinalExperience(exp).toDouble();
    var h = copyWith(currentExp: currentExp + gain);
    // Поддержка нескольких уровней подряд при большой награде
    while (h.canLevelUp) {
      h = h.levelUp();
    }
    return h;
  }

  // TO MAP (для сохранения в базу)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'currentExp': currentExp,
      'maxExp': maxExp,
      'stats': stats.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'gold': gold,
      'skillPoints': skillPoints,
      'inventory': inventory.map((slot) => {
        'itemId': slot.item.id,
        'quantity': slot.quantity,
      }).toList(),
      'equipment': equipment.map((key, item) => 
        MapEntry(key, item?.id)
      ),
      'skills': skills.map((s) => {
        'id': s.id,
        'level': s.level,
        'lastUsed': s.lastUsed?.toIso8601String(),
      }).toList(),
      'activeBuffs': activeBuffs.map((b) => b.toMap()).toList(),
    };
  }

  // FROM MAP (для загрузки из базы)
  factory Hunter.fromMap(Map<String, dynamic> map) {
    // Используем реальные данные из items_data и skills_data

    return Hunter(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      currentExp: map['currentExp'],
      maxExp: map['maxExp'],
      stats: Stats.fromMap(map['stats']),
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.parse(map['lastLoginAt']) 
          : null,
      gold: map['gold'],
      skillPoints: map['skillPoints'],
      inventory: (map['inventory'] as List).map((slotMap) {
        final item = allGameItems.firstWhere(
          (i) => i.id == slotMap['itemId'],
          orElse: () => throw Exception('Item not found: ${slotMap['itemId']}'),
        );
        return InventorySlot(item: item, quantity: slotMap['quantity']);
      }).toList(),
      equipment: (map['equipment'] as Map<String, dynamic>).map((key, itemId) {
        if (itemId == null) {
          return MapEntry(key, null);
        }
        final item = allGameItems.firstWhere(
          (i) => i.id == itemId,
          orElse: () => throw Exception('Item not found: $itemId'),
        );
        return MapEntry(key, item);
      }),
      skills: (map['skills'] as List).map((skillMap) {
        // Если это Map, значит есть дополнительные данные
        if (skillMap is Map) {
          final skillId = skillMap['id'] as String;
          final baseSkill = initialSkills.firstWhere(
            (s) => s.id == skillId,
            orElse: () => throw Exception('Skill not found: $skillId'),
          );
          return Skill(
            id: baseSkill.id,
            name: baseSkill.name,
            description: baseSkill.description,
            branch: baseSkill.branch,
            tier: baseSkill.tier,
            level: skillMap['level'] as int? ?? baseSkill.level,
            maxLevel: baseSkill.maxLevel,
            cost: baseSkill.cost,
            type: baseSkill.type,
            parentId: baseSkill.parentId,
            lastUsed: skillMap['lastUsed'] != null 
                ? DateTime.parse(skillMap['lastUsed']) 
                : null,
            cooldownSeconds: baseSkill.cooldownSeconds,
            durationSeconds: baseSkill.durationSeconds,
          );
        } else {
          // Старый формат - только ID
          return initialSkills.firstWhere(
            (s) => s.id == skillMap,
            orElse: () => throw Exception('Skill not found: $skillMap'),
          );
        }
      }).toList(),
      activeBuffs: (map['activeBuffs'] as List?)?.map((buffMap) {
        return Buff.fromMap(buffMap);
      }).toList() ?? [],
    );
  }
}