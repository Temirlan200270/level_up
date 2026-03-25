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
import 'database_service.dart';
import 'ai_service.dart';
import 'translation_service.dart';

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

// === ПРОВАЙДЕРЫ ОХОТНИКА (HUNTER) ===

// Провайдер охотника
final hunterProvider = StateNotifierProvider<HunterNotifier, Hunter?>((ref) {
  return HunterNotifier();
});

class HunterNotifier extends StateNotifier<Hunter?> {
  HunterNotifier() : super(null) {
    _loadHunter();
  }

  void _loadHunter() {
    state = DatabaseService.getHunter();
  }

  Future<void> createHunter(String name) async {
    final hunter = await DatabaseService.createDefaultHunter(name);
    state = hunter;
  }

  Future<void> updateHunter(Hunter hunter) async {
    await DatabaseService.saveHunter(hunter);
    state = hunter;
  }

  Future<int> addExperience(int exp) async {
    if (state == null) return 0;
    final finalExp = state!.calculateFinalExperience(exp);
    final updated = state!.addExperience(exp);
    await updateHunter(updated);
    return finalExp; // Возвращаем финальный опыт для отображения
  }

  Future<void> levelUp() async {
    if (state == null || !state!.canLevelUp) return;
    final updated = state!.levelUp();
    await updateHunter(updated);
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
    await DatabaseService.deleteHunter();
    state = null;
  }

  void refresh() {
    _loadHunter();
  }

  Future<void> buyItem(Item item) async {
    if (state == null) return;
    final hunter = state!;
    if (hunter.gold < item.buyPrice) return;

    final newInventory = _inventoryAddQuantity(hunter.inventory, item, 1);
    final updated = hunter.copyWith(
      inventory: newInventory,
      gold: hunter.gold - item.buyPrice,
    );
    await updateHunter(updated);
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
      // Восстанавливаем стрик (логика будет в QuestsNotifier)
      if (kDebugMode) {
        debugPrint('Восстановлен стрик задач');
      }
    }

    if (effects.containsKey('xp_multiplier_2x')) {
      final duration = (effects['duration'] as num?)?.toInt() ?? 3600;
      final buff = Buff(
        effectId: 'xp_multiplier',
        value: effects['xp_multiplier_2x'],
        expiresAt: DateTime.now().add(Duration(seconds: duration)),
      );

      updated = updated.copyWith(
        activeBuffs: [...updated.activeBuffs, buff],
      );
    }

    await updateHunter(updated);
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
      // TODO: Убрать пассивные статы старого предмета
    }

    newEquipment[slot] = item;
    // TODO: Применить пассивные статы нового предмета к Stats (если нужно)

    await updateHunter(
      hunter.copyWith(inventory: newInventory, equipment: newEquipment),
    );
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

    // Пример: для Sprint добавляем бафф на x2 опыт
    if (skill.id == 'skill_sprint') {
      final duration = skill.durationSeconds ?? 1800;
      final buff = Buff(
        effectId: 'sprint_bonus',
        value: 2.0,
        expiresAt: DateTime.now().add(Duration(seconds: duration)),
      );

      final newBuffs = List<Buff>.from(hunter.activeBuffs)..add(buff);
      state = hunter.copyWith(
        activeBuffs: newBuffs,
        skills: newSkills,
      );
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
    );

    final newSkills = List<Skill>.from(hunter.skills);
    newSkills[skillIndex] = updatedSkill;

    state = hunter.copyWith(
      skills: newSkills,
      skillPoints: hunter.skillPoints - currentSkill.cost,
    );
    updateHunter(state!);
  }

  // === СИСТЕМА ДРОПА (RNG) ===
  
  /// Генерирует дроп при завершении квеста и возвращает результат
  LootDropResult? generateLootDrop() {
    if (state == null) return null;
    
    final random = Random();
    final roll = random.nextInt(101); // 0-100
    
    if (roll <= 70) {
      // 0-70: Золото (10-50)
      final goldAmount = 10 + random.nextInt(41);
      state = state!.copyWith(gold: state!.gold + goldAmount);
      updateHunter(state!);
      if (kDebugMode) {
        debugPrint('Получено золото: $goldAmount');
      }
      return LootDropResult(goldAmount: goldAmount);
    } else if (roll <= 90) {
      // 71-90: Материал
      final materials = allGameItems
          .where((item) => item.type == ItemType.material)
          .toList();
      if (materials.isNotEmpty) {
        final material = materials[random.nextInt(materials.length)];
        addItem(material, 1);
        if (kDebugMode) {
          debugPrint('Получен материал: ${material.name}');
        }
        return LootDropResult(item: material);
      }
    } else if (roll <= 98) {
      // 91-98: Расходник
      final consumables = allGameItems
          .where((item) => item.type == ItemType.consumable)
          .toList();
      if (consumables.isNotEmpty) {
        final consumable = consumables[random.nextInt(consumables.length)];
        addItem(consumable, 1);
        if (kDebugMode) {
          debugPrint('Получен расходник: ${consumable.name}');
        }
        return LootDropResult(item: consumable);
      }
    } else {
      // 99-100: Экипировка/Руна
      final equipment = allGameItems
          .where(
            (item) =>
                item.type == ItemType.equipment ||
                item.type == ItemType.runestone,
          )
          .toList();
      if (equipment.isNotEmpty) {
        final equip = equipment[random.nextInt(equipment.length)];
        addItem(equip, 1);
        if (kDebugMode) {
          debugPrint('Получена экипировка: ${equip.name}');
        }
        return LootDropResult(item: equip);
      } else {
        // Если нет экипировки, даем золото
        final goldAmount = 50 + random.nextInt(51);
        state = state!.copyWith(gold: state!.gold + goldAmount);
        updateHunter(state!);
        if (kDebugMode) {
          debugPrint('Получено золото (вместо экипировки): $goldAmount');
        }
        return LootDropResult(goldAmount: goldAmount);
      }
    }
    return null;
  }
}

// === ПРОВАЙДЕРЫ КВЕСТОВ ===

// Провайдер всех квестов
final questsProvider = StateNotifierProvider<QuestsNotifier, List<Quest>>((
  ref,
) {
  return QuestsNotifier();
});

class QuestsNotifier extends StateNotifier<List<Quest>> {
  QuestsNotifier() : super([]) {
    _loadQuests();
  }

  void _loadQuests() {
    state = DatabaseService.getAllQuests();
  }

  Future<void> addQuest(Quest quest) async {
    await DatabaseService.addQuest(quest);
    _loadQuests();
  }

  Future<void> updateQuest(Quest quest) async {
    await DatabaseService.updateQuest(quest);
    _loadQuests();
  }

  Future<Map<String, dynamic>?> completeQuest(String questId, WidgetRef ref) async {
    final quest = DatabaseService.getQuest(questId);
    if (quest == null || !quest.canComplete) return null;

    final completed = quest.complete();
    await updateQuest(completed);

    // ВАЖНО: Опыт всегда добавляется, независимо от дропа!
    // Добавляем опыт охотнику и ждем завершения
    final finalExp =
        await ref.read(hunterProvider.notifier).addExperience(completed.experienceReward);

    if (completed.statPointsReward > 0) {
      await ref.read(hunterProvider.notifier).addStatPointsReward(completed.statPointsReward);
    }

    // Система дропа (RNG) - возвращаем результат для отображения
    // Дроп - это дополнительная награда, опыт уже начислен выше
    final lootDrop = ref.read(hunterProvider.notifier).generateLootDrop();
    
    // Возвращаем и опыт, и дроп для отображения
    return {
      'experience': finalExp,
      'lootDrop': lootDrop,
    };
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
