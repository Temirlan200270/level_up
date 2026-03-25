import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hunter_model.dart';
import '../models/item_model.dart';
import '../models/skill_model.dart';
import '../models/quest_model.dart';
import '../models/stats_model.dart';
import '../models/buff_model.dart';
import '../models/enums.dart';
import '../models/ai_provider_model.dart';
import '../data/items_data.dart';
import '../core/economy_scale.dart';
import '../core/game_feedback.dart';
import '../core/loot_drop_logic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_sync/cloud_sync_adapter.dart';
import 'cloud_sync/supabase_cloud_sync_adapter.dart';
import 'database_service.dart';
import 'ai_service.dart';
import 'quest_notification_service.dart';
import 'translation_service.dart';
import 'supabase/supabase_config.dart';
import 'home_widget_service.dart';
import '../core/feedback_overlay.dart';
import '../core/systems/system_config.dart';
import '../core/systems/system_id.dart';
import '../core/systems/custom_rules_preset.dart';
import '../core/systems/systems_catalog.dart';
import '../core/systems/system_rules.dart';

// === РЕЗУЛЬТАТ ДРОПА ===
/// Результат дропа для отображения в UI
class LootDropResult {
  final int? goldAmount;
  final Item? item;

  LootDropResult({this.goldAmount, this.item});
}

/// Добавляет предмет в копию инвентаря (чистая функция, без сохранения в БД).
List<InventorySlot> _inventoryAddQuantity(
  List<InventorySlot> inventory,
  Item item,
  int quantity,
) {
  final list = List<InventorySlot>.from(inventory);
  final idx = list.indexWhere((s) => s.item.id == item.id);
  if (idx >= 0) {
    list[idx] = InventorySlot(
      item: item,
      quantity: list[idx].quantity + quantity,
    );
  } else {
    list.add(InventorySlot(item: item, quantity: quantity));
  }
  return list;
}

/// Уменьшает количество предмета; null — нет слота или нельзя списать.
List<InventorySlot>? _inventoryRemoveQuantity(
  List<InventorySlot> inventory,
  String itemId,
  int quantity,
) {
  final list = List<InventorySlot>.from(inventory);
  final idx = list.indexWhere((s) => s.item.id == itemId);
  if (idx < 0) return null;
  final newQuantity = list[idx].quantity - quantity;
  if (newQuantity < 0) return null;
  if (newQuantity == 0) {
    list.removeAt(idx);
  } else {
    list[idx] = InventorySlot(item: list[idx].item, quantity: newQuantity);
  }
  return list;
}

/// Проверка и разблокировка достижений после завершения квеста.
Future<void> _evaluateQuestAchievements(
  WidgetRef ref,
  Quest completedQuest,
) async {
  if (ref.read(hunterProvider) == null) return;

  final completedTotal = DatabaseService.getAllQuests()
      .where((q) => q.status == QuestStatus.completed)
      .length;
  if (completedTotal >= 1) {
    await DatabaseService.unlockAchievement('first_quest');
  }

  final afterFirstUnlock = ref.read(hunterProvider);
  if (afterFirstUnlock == null) return;
  if (afterFirstUnlock.level >= 5) {
    await DatabaseService.unlockAchievement('level_5');
  }
  if (afterFirstUnlock.level >= 10) {
    await DatabaseService.unlockAchievement('level_10');
  }
  if (afterFirstUnlock.level >= 50) {
    await DatabaseService.unlockAchievement('monarch_mode');
  }
  if (afterFirstUnlock.gold >= 1000) {
    await DatabaseService.unlockAchievement('gold_1000');
  }
  if (afterFirstUnlock.dailyQuestStreak >= 7) {
    await DatabaseService.unlockAchievement('streak_7');
  }
  if (completedQuest.type == QuestType.urgent) {
    await DatabaseService.unlockAchievement('urgent_hero');
  }

  final counts = DatabaseService.getTagCounts();
  final codeScore = (counts['code'] ?? 0) + (counts['код'] ?? 0);
  final forClass = ref.read(hunterProvider);
  if (forClass != null && codeScore >= 10 && forClass.hiddenClassId == null) {
    await ref
        .read(hunterProvider.notifier)
        .updateHunter(forClass.copyWith(hiddenClassId: 'coder'));
    await DatabaseService.unlockAchievement('class_coder');
  }
}

// === ПРОВАЙДЕРЫ ОХОТНИКА (HUNTER) ===

// Провайдер охотника
final hunterProvider = StateNotifierProvider<HunterNotifier, Hunter?>((ref) {
  return HunterNotifier(ref);
});

class HunterNotifier extends StateNotifier<Hunter?> {
  HunterNotifier(this._ref) : super(null) {
    _loadHunter();
  }

  final Ref _ref;

  void _loadHunter() {
    state = DatabaseService.getHunter();
  }

  /// Перечитать охотника из Hive (после импорта / облачного восстановления).
  void reloadFromLocalDb() {
    _loadHunter();
  }

  Future<void> createHunter(String name) async {
    final hunter = await DatabaseService.createDefaultHunter(name);
    await DatabaseService.ensureAwakeningTutorialIfNeeded();
    await DatabaseService.setSystemSelectionShown(false);
    state = hunter;
  }

  Future<void> updateHunter(Hunter hunter) async {
    await DatabaseService.saveHunter(hunter);
    state = hunter;
    // Home widget: обновляем “снаружи” при любом апдейте охотника.
    await HomeWidgetService.update(
      hunter: hunter,
      quests: _ref.read(questsProvider),
    );
  }

  Future<void> addBuff(Buff buff) async {
    if (state == null) return;
    final next = <Buff>[
      for (final b in state!.activeBuffs)
        if (!b.isExpired) b,
      buff,
    ];
    await updateHunter(state!.copyWith(activeBuffs: next));
  }

  Future<int> addExperience(int exp, {QuestType? questType}) async {
    if (state == null) return 0;
    final beforeLevel = state!.level;
    final finalExp = state!.calculateFinalExperience(exp, questType: questType);
    final updated = state!.addExperience(exp, questType: questType);
    await updateHunter(updated);
    DatabaseService.updatePersonalRecords(updated.level, updated.gold);
    final gained = updated.level - beforeLevel;
    if (gained > 0) {
      GameFeedback.onLevelUp(levelsGained: gained);
      _ref
          .read(feedbackOverlayProvider.notifier)
          .show(FeedbackOverlayKind.levelUp);
      await DatabaseService.trySpawnStoryMilestones(updated.level);
      if (_ref.read(activeSystemIdProvider) == SystemId.cultivator) {
        await _ref
            .read(questsProvider.notifier)
            .spawnCultivatorTribulationIfNeeded(updated.level);
      }
      _ref.read(questsProvider.notifier).refresh();
    }
    return finalExp;
  }

  /// Начисление золота (квесты, события).
  Future<void> addGold(int amount) async {
    if (state == null || amount <= 0) return;
    final h = state!.copyWith(gold: state!.gold + amount);
    await updateHunter(h);
    DatabaseService.updatePersonalRecords(h.level, h.gold);
  }

  /// +1 к стрику ежедневных квестов после успешного daily.
  Future<void> incrementDailyStreak() async {
    if (state == null) return;
    final h = state!.copyWith(dailyQuestStreak: state!.dailyQuestStreak + 1);
    await updateHunter(h);
  }

  Future<void> resetDailyStreak() async {
    if (state == null) return;
    await updateHunter(state!.copyWith(dailyQuestStreak: 0));
  }

  Future<void> levelUp() async {
    if (state == null || !state!.canLevelUp) return;
    final before = state!.level;
    final updated = state!.levelUp();
    await updateHunter(updated);
    GameFeedback.onLevelUp(levelsGained: 1);
    if (updated.level > before) {
      await DatabaseService.trySpawnStoryMilestones(updated.level);
      _ref.read(questsProvider.notifier).refresh();
    }
  }

  Future<void> updateStats(Stats stats) async {
    if (state == null) return;
    final updated = state!.copyWith(stats: stats);
    await updateHunter(updated);
  }

  /// Награда очков характеристик за квест (добавление к availablePoints).
  Future<void> addStatPointsReward(int points) async {
    if (state == null || points <= 0) return;
    final h = state!;
    final newStats = h.stats.copyWith(
      availablePoints: h.stats.availablePoints + points,
    );
    await updateHunter(h.copyWith(stats: newStats));
  }

  /// Распределяет очко характеристики на указанный стат
  Future<void> allocateStatPoint(String statName) async {
    if (state == null) return;
    final hunter = state!;

    // Проверяем, есть ли доступные очки
    if (hunter.stats.availablePoints <= 0) return;

    // Добавляем очко к стату
    final newStats = hunter.stats.addToStat(statName, 1);
    final updated = hunter.copyWith(stats: newStats);
    await updateHunter(updated);
  }

  Future<void> resetHunter() async {
    await DatabaseService.clearGamificationMeta();
    await DatabaseService.deleteHunter();
    state = null;
  }

  /// Штрафы за провал «обязательного» квеста (ежедневный / недельный / флаг mandatory).
  Future<void> applyQuestFailurePenalties() async {
    if (state == null) return;
    final h = state!;
    final rules = _ref.read(activeSystemRulesProvider);
    // Квест-контекст для правил (минимум: тип daily/weekly/mandatory).
    final quest = Quest(
      title: '',
      description: '',
      type: QuestType.daily,
      mandatory: true,
      experienceReward: 0,
      goldReward: 0,
      statPointsReward: 0,
      tags: const ['system'],
      difficulty: 1,
    );
    final m =
        h.questFailurePenaltyMultiplier *
        DatabaseService.getWorldEventFailurePenaltyMultiplier();
    final baseGoldLoss = ((10 + h.level * 2) * m).round();
    final baseExpLoss = h.currentExp * 0.05 * m;
    final goldLoss = rules.mapFailureGoldLoss(
      hunter: h,
      quest: quest,
      baseGoldLoss: baseGoldLoss,
    );
    final expLoss = rules.mapFailureExperienceLoss(
      hunter: h,
      quest: quest,
      baseExpLoss: baseExpLoss,
    );
    await updateHunter(
      h.copyWith(
        gold: max(0, h.gold - goldLoss),
        currentExp: max(0.0, h.currentExp - expLoss),
        dailyQuestStreak: 0,
      ),
    );
  }

  /// Дебафф «Штрафная зона» после провала обязательного квеста.
  Future<void> applyPenaltyZoneDebuff() async {
    if (state == null) return;
    final without = state!.activeBuffs
        .where((b) => b.effectId != 'penalty_zone')
        .toList();
    final debuff = Buff(
      effectId: 'penalty_zone',
      value: 0.5,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );
    await updateHunter(state!.copyWith(activeBuffs: [...without, debuff]));
  }

  /// Снятие дебаффа (после выполнения штрафного квеста).
  Future<void> clearPenaltyZoneDebuff() async {
    if (state == null) return;
    final next = state!.activeBuffs
        .where((b) => b.effectId != 'penalty_zone')
        .toList();
    if (next.length == state!.activeBuffs.length) return;
    await updateHunter(state!.copyWith(activeBuffs: next));
  }

  void refresh() {
    _loadHunter();
  }

  Future<void> buyItem(Item item) async {
    if (state == null) return;
    final hunter = state!;
    final cost = EconomyScale.scaledShopBuyPrice(item.buyPrice, hunter.level);
    if (hunter.gold < cost) return;

    final newInventory = _inventoryAddQuantity(hunter.inventory, item, 1);
    final updated = hunter.copyWith(
      inventory: newInventory,
      gold: hunter.gold - cost,
    );
    await updateHunter(updated);
    GameFeedback.onPurchase();
  }

  // === ЛОГИКА ИНВЕНТАРЯ ===

  /// Добавляет предмет в инвентарь или увеличивает количество
  void addItem(Item item, int quantity) {
    if (state == null) return;
    final hunter = state!;

    List<InventorySlot> newInventory = List.from(hunter.inventory);
    bool found = false;

    for (int i = 0; i < newInventory.length; i++) {
      if (newInventory[i].item.id == item.id) {
        newInventory[i] = InventorySlot(
          item: item,
          quantity: newInventory[i].quantity + quantity,
        );
        found = true;
        break;
      }
    }

    if (!found) {
      newInventory.add(InventorySlot(item: item, quantity: quantity));
    }

    state = hunter.copyWith(inventory: newInventory);
    updateHunter(state!);
  }

  /// Удаляет предмет из инвентаря
  void removeItem(String itemId, int quantity) {
    if (state == null) return;
    final hunter = state!;

    List<InventorySlot> newInventory = List.from(hunter.inventory);

    for (int i = 0; i < newInventory.length; i++) {
      if (newInventory[i].item.id == itemId) {
        final newQuantity = newInventory[i].quantity - quantity;
        if (newQuantity <= 0) {
          newInventory.removeAt(i);
        } else {
          newInventory[i] = InventorySlot(
            item: newInventory[i].item,
            quantity: newQuantity,
          );
        }
        break;
      }
    }

    state = hunter.copyWith(inventory: newInventory);
    updateHunter(state!);
  }

  /// Продает предмет (удаляет из инвентаря и добавляет золото)
  Future<void> sellItem(String itemId, int quantity, int sellPrice) async {
    if (state == null) return;
    final hunter = state!;

    // Вычисляем общую стоимость
    final totalPrice = sellPrice * quantity;

    // Удаляем предмет из инвентаря
    List<InventorySlot> newInventory = List.from(hunter.inventory);
    for (int i = 0; i < newInventory.length; i++) {
      if (newInventory[i].item.id == itemId) {
        final newQuantity = newInventory[i].quantity - quantity;
        if (newQuantity <= 0) {
          newInventory.removeAt(i);
        } else {
          newInventory[i] = InventorySlot(
            item: newInventory[i].item,
            quantity: newQuantity,
          );
        }
        break;
      }
    }

    // Обновляем охотника: удаляем предмет и добавляем золото атомарно
    final updated = hunter.copyWith(
      inventory: newInventory,
      gold: hunter.gold + totalPrice,
    );
    await updateHunter(updated);
    GameFeedback.onSell();
  }

  /// Использует расходник
  Future<void> useItem(InventorySlot slot) async {
    if (state == null) return;
    final hunter = state!;

    // Проверяем, что это расходник
    if (slot.item.type != ItemType.consumable) return;

    final newInventory = _inventoryRemoveQuantity(
      hunter.inventory,
      slot.item.id,
      1,
    );
    if (newInventory == null) return;

    var updated = hunter.copyWith(inventory: newInventory);
    final effects = slot.item.effects ?? {};

    if (effects.containsKey('restore_streak')) {
      final ns = (updated.dailyQuestStreak + 3).clamp(0, 999);
      updated = updated.copyWith(dailyQuestStreak: ns);
      if (kDebugMode) {
        debugPrint('Восстановлен стрик задач: $ns');
      }
    }

    if (effects.containsKey('xp_multiplier_2x')) {
      final duration = (effects['duration'] as num?)?.toInt() ?? 3600;
      final buff = Buff(
        effectId: 'xp_multiplier',
        value: effects['xp_multiplier_2x'],
        expiresAt: DateTime.now().add(Duration(seconds: duration)),
      );

      updated = updated.copyWith(activeBuffs: [...updated.activeBuffs, buff]);
    }

    await updateHunter(updated);
    GameFeedback.onConsumable();
  }

  /// Экипирует предмет
  Future<void> equipItem(Item item) async {
    if (state == null) return;
    final hunter = state!;

    // Проверяем, что это экипировка
    if (item.type != ItemType.equipment || item.slot == null) return;

    var newInventory = _inventoryRemoveQuantity(hunter.inventory, item.id, 1);
    if (newInventory == null) return;

    final slot = item.slot!;
    final newEquipment = Map<String, Item?>.from(hunter.equipment);
    final oldItem = newEquipment[slot];
    if (oldItem != null) {
      newInventory = _inventoryAddQuantity(newInventory, oldItem, 1);
    }

    newEquipment[slot] = item;
    // Бонусы экипировки считаются динамически в Hunter.equipmentStatsBonus / displayStats.

    await updateHunter(
      hunter.copyWith(inventory: newInventory, equipment: newEquipment),
    );
    GameFeedback.onEquip();
  }

  /// Снимает предмет с экипировки
  Future<void> unequipItem(String slot) async {
    if (state == null) return;
    final hunter = state!;

    final item = hunter.equipment[slot];
    if (item == null) return;

    final newEquipment = Map<String, Item?>.from(hunter.equipment);
    newEquipment[slot] = null;

    final newInventory = _inventoryAddQuantity(hunter.inventory, item, 1);

    await updateHunter(
      hunter.copyWith(equipment: newEquipment, inventory: newInventory),
    );
    GameFeedback.onUnequip();
  }

  Future<void> learnSkill(Skill skill) async {
    if (state == null) return;
    final hunter = state!;

    final alreadyLearned = hunter.skills.any((s) => s.id == skill.id);

    if (hunter.skillPoints >= skill.cost && !alreadyLearned) {
      final newSP = hunter.skillPoints - skill.cost;
      final newSkills = [...hunter.skills, skill];

      await updateHunter(
        hunter.copyWith(skillPoints: newSP, skills: newSkills),
      );
      GameFeedback.onSkillProgress();
    }
  }

  // === ЛОГИКА НАВЫКОВ ===

  /// Активирует активный навык
  void activateSkill(Skill skill) {
    if (state == null) return;
    final hunter = state!;

    // Проверяем, что навык изучен
    if (!hunter.skills.any((s) => s.id == skill.id)) {
      if (kDebugMode) {
        debugPrint('Навык не изучен: ${skill.name}');
      }
      return;
    }

    // Проверяем тип навыка
    if (skill.type != SkillType.active) {
      if (kDebugMode) {
        debugPrint('Навык не активный: ${skill.name}');
      }
      return;
    }

    // Проверяем cooldown
    final learnedSkill = hunter.skills.firstWhere(
      (s) => s.id == skill.id,
      orElse: () => skill,
    );

    if (!learnedSkill.isReady) {
      final remaining = learnedSkill.remainingCooldown;
      if (kDebugMode) {
        debugPrint('Навык на перезарядке. Осталось: ${remaining ?? 0} сек');
      }
      return;
    }

    // Обновляем время использования навыка
    final updatedSkill = learnedSkill.withLastUsed(DateTime.now());
    final newSkills = List<Skill>.from(hunter.skills);
    final skillIndex = newSkills.indexWhere((s) => s.id == skill.id);
    if (skillIndex != -1) {
      newSkills[skillIndex] = updatedSkill;
    }

    // Применяем эффект на duration
    if (kDebugMode) {
      debugPrint('Навык активирован: ${skill.name}');
    }

    GameFeedback.onSkillActivate();

    // Пример: для Sprint добавляем бафф на x2 опыт
    if (skill.id == 'skill_sprint') {
      final duration = skill.durationSeconds ?? 1800;
      final buff = Buff(
        effectId: 'sprint_bonus',
        value: 2.0,
        expiresAt: DateTime.now().add(Duration(seconds: duration)),
      );

      final newBuffs = List<Buff>.from(hunter.activeBuffs)..add(buff);
      state = hunter.copyWith(activeBuffs: newBuffs, skills: newSkills);
      updateHunter(state!);
    } else if (skill.id == 'focus') {
      /// Медитация: символическая награда + фокус-сессия в UI (таймер в SkillCard / оверлей).
      state = hunter.copyWith(skills: newSkills, gold: hunter.gold + 5);
      updateHunter(state!);
    } else {
      state = hunter.copyWith(skills: newSkills);
      updateHunter(state!);
    }
  }

  /// Улучшает навык
  void spendSkillPointAndUpgradeSkill(Skill skill) {
    if (state == null) return;
    final hunter = state!;

    // Проверяем, что навык изучен
    final skillIndex = hunter.skills.indexWhere((s) => s.id == skill.id);
    if (skillIndex == -1) {
      if (kDebugMode) {
        debugPrint('Навык не изучен: ${skill.name}');
      }
      return;
    }

    final currentSkill = hunter.skills[skillIndex];

    // Проверяем максимальный уровень
    if (currentSkill.level >= currentSkill.maxLevel) {
      if (kDebugMode) {
        debugPrint('Навык уже на максимальном уровне: ${skill.name}');
      }
      return;
    }

    // Проверяем наличие очков навыков
    if (hunter.skillPoints < currentSkill.cost) {
      if (kDebugMode) {
        debugPrint('Недостаточно очков навыков');
      }
      return;
    }

    // Улучшаем навык
    final updatedSkill = Skill(
      id: currentSkill.id,
      name: currentSkill.name,
      description: currentSkill.description,
      branch: currentSkill.branch,
      tier: currentSkill.tier,
      level: currentSkill.level + 1,
      maxLevel: currentSkill.maxLevel,
      cost: currentSkill.cost,
      type: currentSkill.type,
      parentId: currentSkill.parentId,
      lastUsed: currentSkill.lastUsed,
      cooldownSeconds: currentSkill.cooldownSeconds,
      durationSeconds: currentSkill.durationSeconds,
    );

    final newSkills = List<Skill>.from(hunter.skills);
    newSkills[skillIndex] = updatedSkill;

    state = hunter.copyWith(
      skills: newSkills,
      skillPoints: hunter.skillPoints - currentSkill.cost,
    );
    updateHunter(state!);
    GameFeedback.onSkillProgress();
  }

  // === СИСТЕМА ДРОПА (RNG) ===

  /// Генерирует дроп при завершении квеста и возвращает результат
  LootDropResult? generateLootDrop() {
    if (state == null) return null;

    final random = Random();
    final tier = lootTierForRoll(
      rollLootWithBonus(random, DatabaseService.getWorldEventLootRollBonus()),
    );

    switch (tier) {
      case LootDropTier.goldBand:
        final goldAmount = EconomyScale.scaleLootGold(
          rollLootGoldSmall(random),
          state!.level,
        );
        state = state!.copyWith(gold: state!.gold + goldAmount);
        updateHunter(state!);
        if (kDebugMode) {
          debugPrint('Получено золото: $goldAmount');
        }
        return LootDropResult(goldAmount: goldAmount);

      case LootDropTier.materialBand:
        final material = pickRandomItem(filterMaterials(allGameItems), random);
        if (material != null) {
          addItem(material, 1);
          if (kDebugMode) {
            debugPrint('Получен материал: ${material.name}');
          }
          return LootDropResult(item: material);
        }
        return null;

      case LootDropTier.consumableBand:
        final consumable = pickRandomItem(filterConsumables(allGameItems), random);
        if (consumable != null) {
          addItem(consumable, 1);
          if (kDebugMode) {
            debugPrint('Получен расходник: ${consumable.name}');
          }
          return LootDropResult(item: consumable);
        }
        return null;

      case LootDropTier.equipmentOrFallbackGold:
        final equip = pickRandomItem(filterEquipmentLike(allGameItems), random);
        if (equip != null) {
          addItem(equip, 1);
          if (kDebugMode) {
            debugPrint('Получена экипировка: ${equip.name}');
          }
          return LootDropResult(item: equip);
        }
        final goldAmount = EconomyScale.scaleLootGold(
          rollLootGoldLarge(random),
          state!.level,
        );
        state = state!.copyWith(gold: state!.gold + goldAmount);
        updateHunter(state!);
        if (kDebugMode) {
          debugPrint('Получено золото (вместо экипировки): $goldAmount');
        }
        return LootDropResult(goldAmount: goldAmount);
    }
  }
}

// === ПРОВАЙДЕРЫ КВЕСТОВ ===

/// Флаг защищённой мутации квестов (complete/fail), чтобы UI мог блокировать повторы.
final questMutationBusyProvider = StateProvider<bool>((ref) => false);

// Провайдер всех квестов
final questsProvider = StateNotifierProvider<QuestsNotifier, List<Quest>>((
  ref,
) {
  return QuestsNotifier(ref);
});

class QuestsNotifier extends StateNotifier<List<Quest>> {
  QuestsNotifier(this._ref) : super([]) {
    _loadQuests();
  }

  final Ref _ref;
  bool _questMutationInProgress = false;

  Future<T?> _runQuestMutation<T>(Future<T?> Function() mutation) async {
    if (_questMutationInProgress) return null;
    _questMutationInProgress = true;
    _ref.read(questMutationBusyProvider.notifier).state = true;
    try {
      return await mutation();
    } finally {
      _questMutationInProgress = false;
      _ref.read(questMutationBusyProvider.notifier).state = false;
    }
  }

  /// Псевдо-транзакция на уровне игры: snapshot -> мутация -> rollback при ошибке.
  /// Нужна для связанной цепочки (квест -> награды -> лвлап -> дроп -> достижения).
  Future<T?> _runQuestMutationAtomic<T>(Future<T?> Function() mutation) async {
    return _runQuestMutation(() async {
      final backupJson = DatabaseService.exportGameBackupJson();
      try {
        return await mutation();
      } catch (_) {
        await DatabaseService.importGameBackupJson(backupJson);
        _ref.read(hunterProvider.notifier).reloadFromLocalDb();
        _loadQuests();
        rethrow;
      }
    });
  }

  /// Тестовый хук для проверки rollback в псевдо-транзакции.
  @visibleForTesting
  Future<void> runAtomicMutationForTest(Future<void> Function() mutation) async {
    await _runQuestMutationAtomic(() async {
      await mutation();
      return null;
    });
  }

  void _loadQuests() {
    state = DatabaseService.getAllQuests();
    unawaited(QuestNotificationService.rescheduleForActiveQuests(state));
    unawaited(
      HomeWidgetService.update(
        hunter: _ref.read(hunterProvider),
        quests: state,
      ),
    );
    final h = DatabaseService.getHunter();
    if (h != null) {
      unawaited(_afterLoadSpawnStoryMilestones(h.level));
    }
  }

  Future<void> _afterLoadSpawnStoryMilestones(int hunterLevel) async {
    await DatabaseService.trySpawnStoryMilestones(hunterLevel);
    state = DatabaseService.getAllQuests();
    await QuestNotificationService.rescheduleForActiveQuests(state);
  }

  /// Перечитать квесты из Hive (после импорта / облачного восстановления).
  void reloadFromLocalDb() {
    _loadQuests();
  }

  Future<void> addQuest(Quest quest) async {
    await DatabaseService.addQuest(quest);
    _loadQuests();
  }

  Future<void> updateQuest(Quest quest) async {
    await DatabaseService.updateQuest(quest);
    _loadQuests();
  }

  Future<Map<String, dynamic>?> completeQuest(
    String questId,
    WidgetRef ref,
  ) async {
    return _runQuestMutationAtomic(() async {
      final quest = DatabaseService.getQuest(questId);
      if (quest == null || !quest.canComplete) return null;

      final rules = _ref.read(activeSystemRulesProvider);
      final systemId = _ref.read(activeSystemIdProvider);
      final hunterBefore = ref.read(hunterProvider);
      if (hunterBefore == null) return null;

      final completed = quest.complete();
      await updateQuest(completed);
      await DatabaseService.resetMoraleHardFailStreak();

      if (completed.type == QuestType.penalty) {
        await ref.read(hunterProvider.notifier).clearPenaltyZoneDebuff();
      }

      var mappedExp = rules.mapQuestExperienceReward(
        hunter: hunterBefore,
        quest: completed,
        baseExp: completed.experienceReward,
      );

      // Mage: энтропия (затухание рун) — если давно не использовали теги, опыт снижается.
      if (systemId == SystemId.mage && mappedExp > 0) {
        final lastUsedByTag = DatabaseService.getMageRuneLastUsedByTag();
        final now = DateTime.now();
        double mult = 1.0;
        for (final rawTag in completed.tags) {
          final key = rawTag.toLowerCase().trim();
          if (key.isEmpty) continue;
          if (key == 'system' || key.startsWith('system_id_')) continue;
          final iso = lastUsedByTag[key];
          if (iso == null) continue; // Новая руна — не штрафуем.
          final dt = DateTime.tryParse(iso);
          if (dt == null) continue;
          final days = now.difference(dt).inHours / 24.0;
          if (days >= 7) {
            mult = min(mult, 0.90);
          } else if (days >= 3) {
            mult = min(mult, 0.95);
          }
        }
        if (mult < 1.0) {
          mappedExp = (mappedExp * mult).round();
          await DatabaseService.unlockAchievement('mage_entropy');
        }
      }

      final finalExp = await ref
          .read(hunterProvider.notifier)
          .addExperience(mappedExp, questType: completed.type);

      if (completed.statPointsReward > 0) {
        await ref
            .read(hunterProvider.notifier)
            .addStatPointsReward(completed.statPointsReward);
      }

      final hunterNow = ref.read(hunterProvider);
      if (completed.goldReward > 0 && hunterNow != null) {
        final baseGold = EconomyScale.scaledQuestGoldReward(
          completed.goldReward,
          hunterNow.level,
        );
        final mappedGold = rules.mapQuestCurrencyReward(
          hunter: hunterNow,
          quest: completed,
          baseGold: baseGold,
        );
        await ref.read(hunterProvider.notifier).addGold(mappedGold);
      }

      if (completed.type == QuestType.daily) {
        await ref.read(hunterProvider.notifier).incrementDailyStreak();
      }

      await DatabaseService.incrementTagCounts(completed.tags);
      if (systemId == SystemId.mage) {
        // Mage: “комбинация рун” — квест с 2+ тегами даёт краткий бафф к опыту.
        final uniqueTags = completed.tags
            .map((t) => t.toLowerCase().trim())
            .where((t) => t.isNotEmpty && t != 'system' && !t.startsWith('system_id_'))
            .toSet();
        if (uniqueTags.length >= 2) {
          await ref.read(hunterProvider.notifier).addBuff(
                Buff(
                  effectId: 'xp_multiplier',
                  value: 1.10,
                  expiresAt: DateTime.now().add(const Duration(hours: 2)),
                ),
              );
          await DatabaseService.unlockAchievement('mage_combo');
        }
        final runeTags = completed.tags
            .map((t) => t.toLowerCase().trim())
            .where((t) => t.isNotEmpty && t != 'system' && !t.startsWith('system_id_'))
            .toList();
        await DatabaseService.markMageRunesUsed(runeTags);
      }
      await _evaluateQuestAchievements(ref, completed);

      final lootDrop = ref.read(hunterProvider.notifier).generateLootDrop();
      if (lootDrop != null) {
        GameFeedback.onLootDrop();
        if (lootDrop.item != null && lootDrop.item!.rarity.index >= 3) {
          ref
              .read(feedbackOverlayProvider.notifier)
              .show(FeedbackOverlayKind.legendaryLoot);
        }
      } else {
        GameFeedback.onQuestComplete();
      }

      // Dungeons: после успешного этапа спавним следующий (или закрываем данж).
      await DatabaseService.advanceDungeonOnStageComplete(completed);

      return {'experience': finalExp, 'lootDrop': lootDrop};
    });
  }

  /// Провал квеста (штрафы для daily / weekly / mandatory).
  Future<void> failQuest(String questId, WidgetRef ref) async {
    await _runQuestMutationAtomic(() async {
      final quest = DatabaseService.getQuest(questId);
      if (quest == null || !quest.canFail) return;

      await updateQuest(quest.fail());
      GameFeedback.onQuestFail();
      if (quest.penalizeOnFailure) {
        await ref.read(hunterProvider.notifier).applyQuestFailurePenalties();
      }
      // Штрафная зона: обязательный квест (кроме уже штрафного).
      if (quest.mandatory && quest.type != QuestType.penalty) {
        await ref.read(hunterProvider.notifier).applyPenaltyZoneDebuff();
        await spawnPenaltyQuestIfNeeded();
      }

      // Серия провалов сложных квестов → мягкий квест восстановления морали.
      if (quest.difficulty >= 4) {
        await DatabaseService.recordMoraleHardQuestFail();
        if (DatabaseService.getMoraleHardFailStreak() >= 3) {
          await spawnMoraleRecoveryQuestIfNeeded();
          await DatabaseService.resetMoraleHardFailStreak();
        }
      }

      // Dungeons: провал этапа = провал подземелья.
      await DatabaseService.failDungeonOnStageFail(quest);
      return null;
    });
  }

  /// Один активный квест поддержки после тройного провала сложного задания.
  Future<void> spawnMoraleRecoveryQuestIfNeeded() async {
    final has = state.any(
      (q) =>
          q.tags.contains('morale_recovery') &&
          q.status == QuestStatus.active &&
          !q.isExpired,
    );
    if (has) return;

    final title = TranslationService.translate('morale_recovery_title');
    final desc = TranslationService.translate('morale_recovery_desc');
    await addQuest(
      Quest(
        title: title,
        description: desc,
        type: QuestType.special,
        experienceReward: 20,
        goldReward: 15,
        statPointsReward: 1,
        tags: const ['morale_recovery', 'system'],
        difficulty: 1,
        mandatory: false,
        expiresAt: DateTime.now().add(const Duration(hours: 72)),
      ),
    );
  }

  /// Красный штрафной квест Системы (один активный за раз).
  Future<void> spawnPenaltyQuestIfNeeded() async {
    final has = state.any(
      (q) =>
          q.type == QuestType.penalty &&
          q.status == QuestStatus.active &&
          !q.isExpired,
    );
    if (has) return;

    final rnd = Random();
    final variant = 1 + rnd.nextInt(3);
    final title = TranslationService.translate('penalty_quest_title_$variant');
    final desc = TranslationService.translate('penalty_quest_desc_$variant');
    await addQuest(
      Quest(
        title: title,
        description: desc,
        type: QuestType.penalty,
        mandatory: true,
        difficulty: 5,
        experienceReward: 10,
        goldReward: 6,
        tags: const ['penalty', 'system'],
        expiresAt: DateTime.now().add(const Duration(hours: 72)),
      ),
    );
  }

  /// Cultivator: “Небесное испытание” как квест на прорыв.
  /// Спавним на ключевых уровнях, не чаще одного активного испытания.
  Future<void> spawnCultivatorTribulationIfNeeded(int hunterLevel) async {
    final targets = {10, 25, 50};
    if (!targets.contains(hunterLevel)) return;

    final has = state.any(
      (q) =>
          q.tags.contains('tribulation') &&
          q.status == QuestStatus.active &&
          !q.isExpired,
    );
    if (has) return;

    final title = TranslationService.translate('tribulation_title');
    final desc = TranslationService.translate(
      'tribulation_desc',
      params: {'level': hunterLevel.toString()},
    );
    await addQuest(
      Quest(
        title: title,
        description: desc,
        type: QuestType.special,
        mandatory: true,
        difficulty: 5,
        experienceReward: 60 + hunterLevel * 4,
        goldReward: 40 + hunterLevel * 2,
        statPointsReward: 2,
        tags: const ['tribulation', 'cultivator', 'system'],
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }

  /// Случайный срочный квест с коротким дедлайном.
  Future<void> spawnUrgentQuest() async {
    final rnd = Random();
    final titles = ['Срочное усиление', 'Вызов Системы', 'Окно возможности'];
    final t = titles[rnd.nextInt(titles.length)];
    final hours = 1 + rnd.nextInt(3);
    final urgent = Quest(
      title: t,
      description:
          'Выполни любую полезную задачу из реальной жизни в отведённое время.',
      type: QuestType.urgent,
      experienceReward: 25 + rnd.nextInt(20),
      statPointsReward: rnd.nextInt(3),
      goldReward: 20 + rnd.nextInt(30),
      tags: const ['urgent', 'challenge'],
      difficulty: 4,
      expiresAt: DateTime.now().add(Duration(hours: hours)),
    );
    await addQuest(urgent);
  }

  Future<void> deleteQuest(String id) async {
    await DatabaseService.deleteQuest(id);
    _loadQuests();
  }

  Future<void> deleteAllQuests() async {
    await DatabaseService.deleteAllQuests();
    _loadQuests();
  }

  Future<void> initializeDailyQuests() async {
    await DatabaseService.initializeDailyQuests();
    _loadQuests();
  }

  void refresh() {
    _loadQuests();
  }
}

// Провайдер активных квестов
final activeQuestsProvider = Provider<List<Quest>>((ref) {
  final quests = ref.watch(questsProvider);
  return quests
      .where((q) => q.status == QuestStatus.active && !q.isExpired)
      .toList();
});

// Провайдер выполненных квестов
final completedQuestsProvider = Provider<List<Quest>>((ref) {
  final quests = ref.watch(questsProvider);
  return quests.where((q) => q.status == QuestStatus.completed).toList();
});

// === ПРОВАЙДЕРЫ НАСТРОЕК ===

// Провайдер языка
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ru') {
    state = DatabaseService.getLanguage();
    // Загружаем переводы при инициализации
    TranslationService.loadTranslations(state);
  }

  Future<void> setLanguage(String language) async {
    await DatabaseService.setLanguage(language);
    await TranslationService.loadTranslations(language);
    state = language;
  }
}

/// Активная “философия” (system_id) — пока влияет на терминологию/тон.
final activeSystemIdProvider =
    StateNotifierProvider<ActiveSystemIdNotifier, SystemId>((ref) {
  return ActiveSystemIdNotifier(ref);
});

/// Активный slug в ветке `custom_<slug>`.
/// Если в Hive лежит `custom_default` или просто `custom`, возвращаем `default`.
final activeCustomSlugProvider = Provider<String>((ref) {
  return DatabaseService.getActiveCustomSystemSlug();
});

/// Полная конфигурация активной системы.
final activeSystemProvider = Provider<SystemConfig>((ref) {
  final id = ref.watch(activeSystemIdProvider);
  ref.watch(settingsMetaRefreshProvider);
  if (id == SystemId.custom) {
    final slug = ref.watch(activeCustomSlugProvider);
    return DatabaseService.getCustomSystemConfigForSlug(slug);
  }
  return SystemsCatalog.forId(id);
});

final activeSystemRulesProvider = Provider<SystemRules>((ref) {
  final id = ref.watch(activeSystemIdProvider);
  ref.watch(settingsMetaRefreshProvider);
  if (id != SystemId.custom) {
    return SystemsCatalog.rulesForId(id);
  }

  final slug = ref.watch(activeCustomSlugProvider);
  final presetRaw = DatabaseService.getCustomSystemRulesPresetForSlug(slug);
  final base = switch (presetRaw) {
    'solo' => const SoloRules(),
    'mage' => const MageRules(),
    'cultivator' => const CultivatorRules(),
    _ => const SoloRules(), // balanced = safe default for now
  };

  return CustomRules(
    base: base,
    userPrompt: DatabaseService.getCustomSystemAiUserPromptForSlug(slug),
  );
});

class ActiveSystemIdNotifier extends StateNotifier<SystemId> {
  ActiveSystemIdNotifier(this._ref) : super(SystemId.solo) {
    _load();
  }

  final Ref _ref;

  void _load() {
    state = SystemId.fromValue(DatabaseService.getActiveSystemId());
  }

  Future<void> setSystem(SystemId id) async {
    final prevHunter = _ref.read(hunterProvider);

    state = id;
    if (id == SystemId.custom) {
      final slug = _ref.read(activeCustomSlugProvider);
      await DatabaseService.setActiveSystemId('custom_$slug');
    } else {
      await DatabaseService.setActiveSystemId(id.value);
    }

    // Привязываем философию к “витринной” теме оформления (theme_skin_id),
    // чтобы глубинные токены (ThemeExtension) реально ощущались пользователем.
    final skinId = switch (id) {
      SystemId.solo => 'solo',
      SystemId.mage => 'archmage',
      SystemId.cultivator => 'cultivation',
      SystemId.custom => () {
          final slug = _ref.read(activeCustomSlugProvider);
          final presetRaw =
              DatabaseService.getCustomSystemRulesPresetForSlug(slug);
          return switch (CustomRulesPreset.fromValue(presetRaw)) {
            CustomRulesPreset.mage => 'archmage',
            CustomRulesPreset.cultivator => 'cultivation',
            _ => 'solo',
          };
        }(),
    };
    await _ref.read(themeSkinIdProvider.notifier).setSkin(skinId);

    // В multi-save режиме создаём профиль для системы при первом входе.
    if (prevHunter != null &&
        DatabaseService.getHunter(systemId: id) == null) {
      await DatabaseService.createDefaultHunter(
        prevHunter.name,
        systemId: id,
      );
      // Для нового профиля в системе сразу семплим onbording-квесты,
      // чтобы не получить “пустую” вселенную в Mage/Cultivator.
      await DatabaseService.ensureAwakeningTutorialIfNeeded();
    }

    _ref.read(hunterProvider.notifier).reloadFromLocalDb();
    _ref.read(questsProvider.notifier).reloadFromLocalDb();
    _ref.read(settingsMetaRefreshProvider.notifier).state++;
  }

  Future<void> setCustomSystemSlug(String slug) async {
    await DatabaseService.setCustomSystemSlugExists(slug);

    // Не дергаем setSystem(SystemId.custom), чтобы не подхватить “старый” slug.
    final prevHunter = _ref.read(hunterProvider);
    state = SystemId.custom;
    await DatabaseService.setActiveSystemId('custom_$slug');

    final presetRaw =
        DatabaseService.getCustomSystemRulesPresetForSlug(slug);
    final skinId = switch (CustomRulesPreset.fromValue(presetRaw)) {
      CustomRulesPreset.mage => 'archmage',
      CustomRulesPreset.cultivator => 'cultivation',
      _ => 'solo',
    };
    await _ref.read(themeSkinIdProvider.notifier).setSkin(skinId);

    if (prevHunter != null && DatabaseService.getHunter(systemId: state) == null) {
      await DatabaseService.createDefaultHunter(
        prevHunter.name,
        systemId: state,
      );
      await DatabaseService.ensureAwakeningTutorialIfNeeded();
    }

    _ref.read(hunterProvider.notifier).reloadFromLocalDb();
    _ref.read(questsProvider.notifier).reloadFromLocalDb();
    _ref.read(settingsMetaRefreshProvider.notifier).state++;
  }
}

/// Тик для перерисовки баннеров ивентов после `resumed` / смены фазы приложения.
final worldEventTickProvider = StateProvider<int>((ref) => 0);

// === ПРОВАЙДЕРЫ AI НАСТРОЕК ===

// Провайдер текущего AI провайдера
final aiProviderProvider =
    StateNotifierProvider<AIProviderNotifier, AIProvider>((ref) {
      return AIProviderNotifier();
    });

class AIProviderNotifier extends StateNotifier<AIProvider> {
  AIProviderNotifier() : super(AIProvider.openai) {
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    state = await AIService.getProvider();
  }

  Future<void> setProvider(AIProvider provider) async {
    await AIService.setProvider(provider);
    state = provider;
  }

  void refresh() {
    _loadProvider();
  }
}

// Провайдер текущей AI модели
final aiModelProvider = StateNotifierProvider<AIModelNotifier, String>((ref) {
  return AIModelNotifier();
});

class AIModelNotifier extends StateNotifier<String> {
  AIModelNotifier() : super('') {
    _loadModel();
  }

  Future<void> _loadModel() async {
    state = await AIService.getModel();
  }

  Future<void> setModel(String model) async {
    await AIService.setModel(model);
    state = model;
  }

  void refresh() {
    _loadModel();
  }
}

// Провайдер API ключа для провайдера
final aiApiKeyProvider =
    StateNotifierProvider.family<AIApiKeyNotifier, String, AIProvider>((
      ref,
      provider,
    ) {
      return AIApiKeyNotifier(provider);
    });

class AIApiKeyNotifier extends StateNotifier<String> {
  final AIProvider provider;

  AIApiKeyNotifier(this.provider) : super('') {
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await AIService.getApiKey(provider);
    state = key ?? '';
  }

  Future<void> setKey(String key) async {
    await AIService.setApiKey(provider, key);
    state = key;
  }

  void refresh() {
    _loadKey();
  }
}

// === ФОКУС-СЕССИЯ (МЕДИТАЦИЯ) ===

/// Активная полноэкранная фокус-сессия с дедлайном.
class FocusSessionState {
  final DateTime endsAt;
  final bool closedMeditation;
  final bool rewardGranted;

  const FocusSessionState({
    required this.endsAt,
    this.closedMeditation = false,
    this.rewardGranted = false,
  });

  FocusSessionState copyWith({
    DateTime? endsAt,
    bool? closedMeditation,
    bool? rewardGranted,
  }) {
    return FocusSessionState(
      endsAt: endsAt ?? this.endsAt,
      closedMeditation: closedMeditation ?? this.closedMeditation,
      rewardGranted: rewardGranted ?? this.rewardGranted,
    );
  }
}

final focusSessionProvider = StateProvider<FocusSessionState?>((ref) => null);

// === СКИН ТЕМЫ ===

final themeSkinIdProvider = StateNotifierProvider<ThemeSkinNotifier, String>((
  ref,
) {
  return ThemeSkinNotifier();
});

class ThemeSkinNotifier extends StateNotifier<String> {
  ThemeSkinNotifier() : super(DatabaseService.getThemeSkinId());

  Future<void> setSkin(String id) async {
    await DatabaseService.setThemeSkinId(id);
    state = id;
  }

  /// После импорта бэкапа — подтянуть ID из Hive.
  void reloadFromDb() {
    state = DatabaseService.getThemeSkinId();
  }
}

// === ДОСТИЖЕНИЯ (список разблокированных id) ===

final unlockedAchievementIdsProvider = Provider<List<String>>((ref) {
  ref.watch(hunterProvider);
  ref.watch(questsProvider);
  return DatabaseService.getUnlockedAchievements();
});

/// Счётчик для принудительного обновления метаданных на экране настроек (гильдия и т.п.).
final settingsMetaRefreshProvider = StateProvider<int>((ref) => 0);

/// Облачная синхронизация: Supabase при заданных dart-define, иначе заглушка.
final cloudSyncAdapterProvider = Provider<CloudSyncAdapter>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return LocalOnlyCloudSyncAdapter();
  }
  return SupabaseCloudSyncAdapter(Supabase.instance.client);
});
