import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import '../core/experience_curve.dart';
import '../core/story_milestone_seed.dart';
import '../core/tutorial_quests_seed.dart';
import '../core/systems/system_config.dart';
import '../core/systems/system_dictionary.dart';
import '../core/systems/system_id.dart';
import '../models/buff_model.dart';
import '../models/hunter_model.dart';
import '../models/quest_model.dart';
import '../models/dungeon_model.dart';

class DatabaseService {
  static const String settingsBox = 'settings';
  static const String hunterBox = 'hunter';
  static const String questsBox = 'quests';

  // Инициализация Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(settingsBox);
    await Hive.openBox<Map>(hunterBox);
    await Hive.openBox<Map>(questsBox);
  }

  /// Фоновая обработка дедлайнов квестов (без UI и Riverpod).
  ///
  /// Задача: если квест просрочен и всё ещё `active`, перевести в `failed/expired`
  /// и применить базовые штрафы (gold/exp, сброс стрика, penalty_zone для mandatory).
  ///
  /// Важно: это “скелет”. Дальше можно:
  /// - подключить системные правила (`SystemRules`) для маппинга штрафов,
  /// - добавить спавн penalty-quest,
  /// - покрыть widget/UI уведомлениями.
  static Future<int> applyQuestDeadlinesInBackground() async {
    refreshWorldEventState();
    final hunter = getHunter();
    if (hunter == null) return 0;

    final now = DateTime.now();
    final all = getAllQuests(includeAllSystems: true);
    final expiredActive = all
        .where((q) => q.status == QuestStatus.active && q.expiresAt != null)
        .where((q) => now.isAfter(q.expiresAt!))
        .toList();
    if (expiredActive.isEmpty) return 0;

    var updatedHunter = hunter;
    var processed = 0;
    for (final q in expiredActive) {
      processed++;
      final penalize = q.penalizeOnFailure;
      final nextStatus = penalize ? QuestStatus.failed : QuestStatus.expired;
      await addQuest(
        q.copyWith(status: nextStatus, failedAt: now),
        ensureSystemTag: false,
      );

      if (!penalize) continue;

      // Базовые штрафы (без system rules, чтобы фон был безопасным).
      final m =
          updatedHunter.questFailurePenaltyMultiplier *
          getWorldEventFailurePenaltyMultiplier();
      final goldLoss = ((10 + updatedHunter.level * 2) * m).round();
      final expLoss = updatedHunter.currentExp * 0.05 * m;

      updatedHunter = updatedHunter.copyWith(
        gold: max(0, updatedHunter.gold - goldLoss),
        currentExp: max(0.0, updatedHunter.currentExp - expLoss),
        dailyQuestStreak: 0,
      );

      if (q.mandatory && q.type != QuestType.penalty) {
        final without = updatedHunter.activeBuffs
            .where((b) => b.effectId != 'penalty_zone')
            .toList();
        final debuff = Buff(
          effectId: 'penalty_zone',
          value: 0.5,
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
        );
        updatedHunter = updatedHunter.copyWith(activeBuffs: [...without, debuff]);
      }
    }

    await saveHunter(updatedHunter);
    return processed;
  }

  static SystemId _activeSystemTyped() {
    return SystemId.fromValue(getActiveSystemId());
  }

  static String _profileKey(SystemId id) => 'profile_${id.value}';

  // === НАСТРОЙКИ ===

  // Получить язык
  static String getLanguage() {
    final box = Hive.box(settingsBox);
    return box.get('language', defaultValue: 'ru') as String;
  }

  // Установить язык
  static Future<void> setLanguage(String language) async {
    final box = Hive.box(settingsBox);
    await box.put('language', language);
  }

  // === ОХОТНИК (HUNTER) ===

  /// Миграция с линейной кривой (`level * 100`) на [ExperienceCurve].
  static (Hunter, bool didMigrate) _normalizeHunterExperienceCurve(
    Hunter hunter,
  ) {
    if (!ExperienceCurve.matchesLegacyLinear(hunter.maxExp, hunter.level)) {
      return (hunter, false);
    }
    var migrated = hunter.copyWith(
      maxExp: ExperienceCurve.maxExperienceForLevel(hunter.level),
    );
    while (migrated.canLevelUp) {
      migrated = migrated.levelUp();
    }
    return (migrated, true);
  }

  // Получить охотника для конкретной философии.
  // Legacy: если для solo нет `profile_solo`, читаем старый ключ `current`.
  static Hunter? getHunter({SystemId? systemId}) {
    try {
      final box = Hive.box<Map>(hunterBox);
      final id = systemId ?? _activeSystemTyped();

      final map = box.get(_profileKey(id)) ?? (id == SystemId.solo ? box.get('current') : null);
      if (map == null) return null;
      // Безопасное преобразование Map<dynamic, dynamic> в Map<String, dynamic>
      final hunter = Hunter.fromMap(Map<String, dynamic>.from(map));
      final (normalized, didMigrate) = _normalizeHunterExperienceCurve(hunter);
      if (didMigrate) {
        unawaited(saveHunter(normalized, systemId: id));
      }

      // Миграция legacy solo-хантера в новую структуру.
      if (id == SystemId.solo && box.get(_profileKey(id)) == null) {
        unawaited(saveHunter(normalized, systemId: id));
      }
      return normalized;
    } catch (e) {
      // Если ошибка при чтении, возвращаем null
      return null;
    }
  }

  // Сохранить охотника
  static Future<void> saveHunter(
    Hunter hunter, {
    SystemId? systemId,
  }) async {
    final box = Hive.box<Map>(hunterBox);
    final id = systemId ?? _activeSystemTyped();
    await box.put(_profileKey(id), hunter.toMap());
  }

  // Создать нового охотника (если его нет)
  static Future<Hunter> createDefaultHunter(
    String name, {
    SystemId? systemId,
  }) async {
    final id = systemId ?? _activeSystemTyped();
    final existing = getHunter(systemId: id);
    if (existing != null) return existing;

    final newHunter = Hunter(name: name);
    await saveHunter(newHunter, systemId: id);
    return newHunter;
  }

  // Удалить охотника (для сброса прогресса)
  static Future<void> deleteHunter({SystemId? systemId}) async {
    final box = Hive.box<Map>(hunterBox);
    final id = systemId ?? _activeSystemTyped();
    await box.delete(_profileKey(id));
    if (id == SystemId.solo) {
      // Подстраховка для старых сейвов.
      await box.delete('current');
    }
  }

  // === КВЕСТЫ ===

  static String _systemQuestTag(SystemId id) => 'system_id_${id.value}';

  static bool _questBelongsToSystem(Quest quest, SystemId systemId) {
    final hasAnySystemTag =
        quest.tags.any((t) => t.startsWith('system_id_'));
    if (quest.tags.contains(_systemQuestTag(systemId))) return true;
    // Legacy: квесты без `system_id_*` считаем solo.
    return systemId == SystemId.solo && !hasAnySystemTag;
  }

  // Получить все квесты
  static List<Quest> getAllQuests({
    SystemId? systemId,
    bool includeAllSystems = false,
  }) {
    try {
      final box = Hive.box<Map>(questsBox);
      final quests = box.values
          .map((map) => Quest.fromMap(Map<String, dynamic>.from(map)))
          .toList();

      if (includeAllSystems) {
        quests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return quests;
      }

      final id = systemId ?? _activeSystemTyped();
      final filtered = quests
          .where((q) => _questBelongsToSystem(q, id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filtered;
    } catch (e) {
      // Если ошибка при чтении, возвращаем пустой список
      return [];
    }
  }

  // Получить активные квесты
  static List<Quest> getActiveQuests() {
    return getAllQuests()
        .where((q) => q.status == QuestStatus.active && !q.isExpired)
        .toList();
  }

  // Получить квест по ID
  static Quest? getQuest(String id) {
    try {
      final box = Hive.box<Map>(questsBox);
      final map = box.get(id);
      if (map == null) return null;
      final quest = Quest.fromMap(Map<String, dynamic>.from(map));
      final systemId = _activeSystemTyped();
      if (!_questBelongsToSystem(quest, systemId)) return null;
      return quest;
    } catch (e) {
      return null;
    }
  }

  // Добавить квест
  static Future<void> addQuest(
    Quest quest, {
    bool ensureSystemTag = true,
  }) async {
    final box = Hive.box<Map>(questsBox);
    if (!ensureSystemTag) {
      await box.put(quest.id, quest.toMap());
      return;
    }
    final systemId = _activeSystemTyped();
    final hasAnySystemTag =
        quest.tags.any((t) => t.startsWith('system_id_'));

    if (!hasAnySystemTag && systemId != SystemId.solo) {
      final newTags = [...quest.tags, _systemQuestTag(systemId)];
      final tagged = Quest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        type: quest.type,
        status: quest.status,
        experienceReward: quest.experienceReward,
        statPointsReward: quest.statPointsReward,
        goldReward: quest.goldReward,
        tags: newTags,
        difficulty: quest.difficulty,
        mandatory: quest.mandatory,
        createdAt: quest.createdAt,
        completedAt: quest.completedAt,
        failedAt: quest.failedAt,
        expiresAt: quest.expiresAt,
      );
      await box.put(quest.id, tagged.toMap());
      return;
    }

    await box.put(quest.id, quest.toMap());
  }

  // Обновить квест
  static Future<void> updateQuest(
    Quest quest, {
    bool ensureSystemTag = true,
  }) async {
    final box = Hive.box<Map>(questsBox);
    if (!ensureSystemTag) {
      await box.put(quest.id, quest.toMap());
      return;
    }
    final systemId = _activeSystemTyped();
    final hasAnySystemTag =
        quest.tags.any((t) => t.startsWith('system_id_'));

    if (!hasAnySystemTag && systemId != SystemId.solo) {
      final newTags = [...quest.tags, _systemQuestTag(systemId)];
      final tagged = Quest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        type: quest.type,
        status: quest.status,
        experienceReward: quest.experienceReward,
        statPointsReward: quest.statPointsReward,
        goldReward: quest.goldReward,
        tags: newTags,
        difficulty: quest.difficulty,
        mandatory: quest.mandatory,
        createdAt: quest.createdAt,
        completedAt: quest.completedAt,
        failedAt: quest.failedAt,
        expiresAt: quest.expiresAt,
      );
      await box.put(quest.id, tagged.toMap());
      return;
    }

    await box.put(quest.id, quest.toMap());
  }

  // Удалить квест
  static Future<void> deleteQuest(String id) async {
    final box = Hive.box<Map>(questsBox);
    await box.delete(id);
  }

  // Удалить все квесты (для сброса)
  static Future<void> deleteAllQuests() async {
    final box = Hive.box<Map>(questsBox);
    await box.clear();
  }

  // Инициализировать ежедневные квесты (если их нет)
  static Future<void> initializeDailyQuests() async {
    final activeQuests = getActiveQuests()
        .where((q) => q.type == QuestType.daily)
        .toList();

    // Если нет активных ежедневных квестов, создаём новые
    if (activeQuests.isEmpty) {
      final dailyQuests = DefaultQuests.getDailyQuests();
      for (var quest in dailyQuests) {
        await addQuest(quest);
      }
    }
  }

  /// Проверка: сюжетная веха [gateLevel] выполнена (Quest со status=completed и тегом `story_gate_<level>`).
  static bool isStoryGateCompleted(int gateLevel) {
    final tag = 'story_gate_$gateLevel';
    return getAllQuests().any(
      (q) => q.status == QuestStatus.completed && q.tags.contains(tag),
    );
  }

  /// Онбординг «Пробуждение»: три квеста один раз для существующих охотников без тега awakening.
  static Future<void> ensureAwakeningTutorialIfNeeded() async {
    final box = Hive.box(settingsBox);
    final systemId = _activeSystemTyped();
    final seededKey = _tutorialAwakeningSeededKey(systemId);

    // Legacy fallback: если у solo был флаг, переносим на систему.
    if (box.get(seededKey, defaultValue: false) == true) {
      return;
    }
    if (systemId == SystemId.solo &&
        box.get(_kTutorialAwakeningSeeded, defaultValue: false) == true) {
      await box.put(seededKey, true);
      return;
    }
    if (getHunter() == null) return;

    final hasAwakening = getAllQuests().any((q) => q.tags.contains('awakening'));
    if (hasAwakening) {
      await box.put(seededKey, true);
      return;
    }

    for (final q in TutorialQuestsSeed.build(getLanguage())) {
      await addQuest(q);
    }
    await box.put(seededKey, true);
  }

  // === Онбординг «Пробуждение»: интерактивная сцена (один раз) ===

  static bool isAwakeningTutorialSceneShown() {
    final systemId = _activeSystemTyped();
    final box = Hive.box(settingsBox);
    final key = _awakeningTutorialSceneShownKey(systemId);

    final v = box.get(key);
    if (v == null && systemId == SystemId.solo) {
      return box.get(_kAwakeningTutorialSceneShown, defaultValue: false) ==
          true;
    }
    return (v ?? false) == true;
  }

  static Future<void> setAwakeningTutorialSceneShown(bool shown) async {
    final systemId = _activeSystemTyped();
    await Hive.box(settingsBox)
        .put(_awakeningTutorialSceneShownKey(systemId), shown);
  }

  static bool canShowAwakeningTutorialScene() {
    if (getHunter() == null) return false;
    if (isAwakeningTutorialSceneShown()) return false;

    // Сцена имеет смысл, если seed-квесты уже появились.
    final hasAwakeningActive = getAllQuests().any(
      (q) => q.tags.contains('awakening') && q.status == QuestStatus.active && !q.isExpired,
    );

    return hasAwakeningActive;
  }

  static Set<int> _spawnedStoryMilestoneLevels(SystemId systemId) {
    final box = Hive.box(settingsBox);
    final key = _storyMilestonesSpawnedKey(systemId);
    final raw = box.get(key) ?? (systemId == SystemId.solo
        ? box.get(_kStoryMilestonesSpawned)
        : null);
    if (raw is! List) return {};
    return raw.map((e) => (e as num).toInt()).toSet();
  }

  static Future<void> _persistSpawnedStoryMilestones(
    SystemId systemId,
    Set<int> levels,
  ) async {
    final sorted = levels.toList()..sort();
    await Hive.box(settingsBox).put(_storyMilestonesSpawnedKey(systemId), sorted);
  }

  /// Сюжетные вехи на уровнях из [StoryMilestoneSeed.milestoneLevels].
  static Future<void> trySpawnStoryMilestones(int hunterLevel) async {
    if (getHunter() == null) return;

    final systemId = _activeSystemTyped();
    var spawned = _spawnedStoryMilestoneLevels(systemId);
    var changed = false;
    final lang = getLanguage();

    for (final gate in StoryMilestoneSeed.milestoneLevels) {
      if (hunterLevel < gate) continue;

      final tag = 'story_gate_$gate';
      final existsInDb = getAllQuests().any((q) => q.tags.contains(tag));
      if (existsInDb || spawned.contains(gate)) {
        if (!spawned.contains(gate)) {
          spawned = {...spawned, gate};
          changed = true;
        }
        continue;
      }

      await addQuest(StoryMilestoneSeed.questForGate(gate, lang));
      spawned = {...spawned, gate};
      changed = true;
    }

    if (changed) {
      await _persistSpawnedStoryMilestones(systemId, spawned);
    }
  }

  // === Мировые ивенты (аномалии Системы) ===

  static const String _kWorldEventKind = 'world_event_kind';
  static const String _kWorldEventUntil = 'world_event_until_iso';

  /// Сбрасывает просроченный ивент.
  static void refreshWorldEventState() {
    final box = Hive.box(settingsBox);
    final untilStr = box.get(_kWorldEventUntil) as String?;
    if (untilStr == null) {
      return;
    }
    final until = DateTime.tryParse(untilStr);
    if (until == null || DateTime.now().isAfter(until)) {
      box.delete(_kWorldEventKind);
      box.delete(_kWorldEventUntil);
    }
  }

  /// Идентификатор активного ивента (`blood_moon`) или `null`.
  static String? getActiveWorldEventId() {
    refreshWorldEventState();
    final v = Hive.box(settingsBox).get(_kWorldEventKind) as String?;
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static bool get isBloodMoonActive => getActiveWorldEventId() == 'blood_moon';

  /// Множитель к штрафам за провал квеста во время «Кровавой луны».
  static double getWorldEventFailurePenaltyMultiplier() {
    return isBloodMoonActive ? 2.0 : 1.0;
  }

  /// Смещение броска дропа (0–100): чаще выше по тиру.
  static int getWorldEventLootRollBonus() {
    return isBloodMoonActive ? 8 : 0;
  }

  /// Случайный старт ивента при холодном старте (если слот свободен).
  static Future<void> tryRollWorldEventOnSessionStart() async {
    refreshWorldEventState();
    final box = Hive.box(settingsBox);
    if (box.get(_kWorldEventKind) != null) return;

    if (Random().nextInt(100) >= 5) return;

    await box.put(_kWorldEventKind, 'blood_moon');
    await box.put(
      _kWorldEventUntil,
      DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    );
  }

  // === Поведение: серия провалов сложных квестов ===

  static const String _kMoraleHardFailStreak = 'morale_hard_fail_streak';

  static int getMoraleHardFailStreak() {
    return (Hive.box(settingsBox).get(_kMoraleHardFailStreak, defaultValue: 0)
            as num)
        .toInt();
  }

  static Future<void> recordMoraleHardQuestFail() async {
    final box = Hive.box(settingsBox);
    final n = getMoraleHardFailStreak() + 1;
    await box.put(_kMoraleHardFailStreak, n);
  }

  static Future<void> resetMoraleHardFailStreak() async {
    await Hive.box(settingsBox).put(_kMoraleHardFailStreak, 0);
  }

  // === Геймификация: мета-данные в box settings ===

  static const String _kTagCounts = 'tag_counts';
  static const String _kTagCountsBySystem = 'tag_counts_by_system_json';
  static const String _kAchievements = 'achievement_ids';
  static const String _kAchievementsBySystem = 'achievement_ids_by_system_json';
  static const String _kGuildName = 'guild_name';
  static const String _kSocialDisplayName = 'social_display_name';
  static const String _kSocialDiscriminator = 'social_discriminator_4';
  static const String _kOnboardingPersonaPrefix = 'onboarding_persona_v1_';
  static const String _kThemeSkin = 'theme_skin_id';
  static const String _kActiveSystemId = 'active_system_id';
  static const String _kSystemSelectionShown = 'system_selection_shown';
  static const String _kOnboardingStepPrefix = 'onboarding_step_v1_';
  static const String _kMageRuneLastUsed = 'mage_rune_last_used_iso_by_tag';
  static const String _kCustomSystemDictionary = 'custom_system_dictionary_json';
  static const String _kCustomSystemRulesPreset = 'custom_system_rules_preset';
  static const String _kCustomSystemAiVoiceName = 'custom_system_ai_voice_name';
  static const String _kCustomSystemAiToneHint = 'custom_system_ai_tone_hint';
  static const String _kCustomSystemAiUserPrompt = 'custom_system_ai_user_prompt';
  static const String _kCustomSystemSlugsIndex = 'custom_system_slugs_index_json';

  // Slug-scoped (multi-world) keys.
  static const String _kCustomSystemDictionaryPrefix =
      'custom_system_dictionary_json_';
  static const String _kCustomSystemRulesPresetPrefix =
      'custom_system_rules_preset_';
  static const String _kCustomSystemAiVoiceNamePrefix =
      'custom_system_ai_voice_name_';
  static const String _kCustomSystemAiToneHintPrefix =
      'custom_system_ai_tone_hint_';
  static const String _kCustomSystemAiUserPromptPrefix =
      'custom_system_ai_user_prompt_';
  static const String _kCustomSystemThemeNamePrefix =
      'custom_system_theme_name_';
  static const String _kCustomSystemColorsJsonPrefix = 'custom_system_colors_';
  static const String _kCustomSystemBgAssetPathPrefix =
      'custom_system_bg_asset_path_';
  static const String _kCustomSystemBgKindPrefix = 'custom_system_bg_kind_';
  static const String _kCustomSystemParticlesKindPrefix =
      'custom_system_particles_kind_';
  static const String _kCustomSystemPanelRadiusPrefix =
      'custom_system_panel_radius_';
  static const String _kStatLabels = 'stat_labels_json';
  static const String _kDungeonsJson = 'dungeons_json';
  static const String _kBestLevel = 'record_best_level';
  static const String _kBestGold = 'record_best_gold';
  static const String _kRecordsBySystem = 'records_by_system_json';
  static const String _kTutorialAwakeningSeeded = 'tutorial_awakening_seeded';
  static const String _kAwakeningTutorialSceneShown = 'tutorial_awakening_scene_shown';
  static const String _kStoryMilestonesSpawned = 'story_milestones_spawned_json';

  static String _tutorialAwakeningSeededKey(SystemId id) =>
      '${_kTutorialAwakeningSeeded}_${id.value}';
  static String _awakeningTutorialSceneShownKey(SystemId id) =>
      '${_kAwakeningTutorialSceneShown}_${id.value}';
  static String _storyMilestonesSpawnedKey(SystemId id) =>
      '${_kStoryMilestonesSpawned}_${id.value}';
  static String _onboardingStepKey(SystemId id) => '$_kOnboardingStepPrefix${id.value}';
  static String _onboardingPersonaKey(SystemId id) => '$_kOnboardingPersonaPrefix${id.value}';

  static OnboardingStep getOnboardingStep({SystemId? systemId}) {
    final id = systemId ?? _activeSystemTyped();
    final raw = Hive.box(settingsBox).get(_onboardingStepKey(id)) as String?;
    return OnboardingStep.fromValue(raw);
  }

  static Future<void> setOnboardingStep(
    OnboardingStep step, {
    SystemId? systemId,
  }) async {
    final id = systemId ?? _activeSystemTyped();
    await Hive.box(settingsBox).put(_onboardingStepKey(id), step.value);
  }

  static Map<String, dynamic>? getOnboardingPersonaRaw({SystemId? systemId}) {
    final id = systemId ?? _activeSystemTyped();
    final raw = Hive.box(settingsBox).get(_onboardingPersonaKey(id));
    if (raw is! String || raw.trim().isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setOnboardingPersonaRaw(
    Map<String, dynamic> persona, {
    SystemId? systemId,
  }) async {
    final id = systemId ?? _activeSystemTyped();
    await Hive.box(settingsBox).put(
      _onboardingPersonaKey(id),
      jsonEncode(persona),
    );
  }

  /// Нормализует шаг онбординга по текущим флагам (защитный переход).
  static Future<void> normalizeOnboardingStep({SystemId? systemId}) async {
    final id = systemId ?? _activeSystemTyped();
    if (getHunter(systemId: id) == null) return;

    // Новая кинематографичная цепочка (Фаза 7.5) приоритетнее legacy.
    // Если пользователь ещё не прошёл философию — начинаем с лора.
    if (!isSystemSelectionShown()) {
      await setOnboardingStep(OnboardingStep.needLore, systemId: id);
      return;
    }

    // Если философия уже выбрана, но мы ещё не завершили кинематографичный запуск —
    // продолжаем дальше. (Awakening legacy сцену считаем уже заменённой.)
    final step = getOnboardingStep(systemId: id);
    if (step != OnboardingStep.done) {
      // Если step пустой/устаревший — продолжаем с мастера.
      if (step == OnboardingStep.needLore ||
          step == OnboardingStep.needPhilosophySelection) {
        await setOnboardingStep(OnboardingStep.needMasterEncounter, systemId: id);
      }
      return;
    }
  }

  // ============================================================
  // Multiverse meta: per-system keys (tagCounts/achievements/records).
  // Key = raw activeSystemId value (solo/mage/cultivator/custom_<slug>).
  // ============================================================

  static String _activeSystemMetaKey() {
    final raw = getActiveSystemId().trim();
    if (raw.isEmpty) return SystemId.solo.value;
    if (raw == SystemId.custom.value) return 'custom_default';
    return raw;
  }

  static Map<String, dynamic> _decodeJsonObj(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> _writeJsonObj(String key, Map<String, dynamic> obj) async {
    await Hive.box(settingsBox).put(key, jsonEncode(obj));
  }

  // ============================================================
  // Multiverse: Custom systems catalog (custom_<slug>).
  // ============================================================

  static String getActiveCustomSystemSlug() {
    final raw = getActiveSystemId();
    return SystemId.extractCustomSlug(raw) ?? 'default';
  }

  static String _slugSafe(String slug) {
    final s = slug.trim().toLowerCase();
    if (s.isEmpty) return 'default';
    final cleaned = s.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return cleaned.isEmpty ? 'default' : cleaned;
  }

  static String _keyFor(String prefix, String slug) => '$prefix${_slugSafe(slug)}';

  static List<String> getCustomSystemSlugs() {
    final box = Hive.box(settingsBox);
    final raw = box.get(_kCustomSystemSlugsIndex);
    final cur = <String>[];
    if (raw is List) {
      cur.addAll(raw.map((e) => e.toString()));
    }
    // Legacy compatibility: всегда считаем `default` валидным.
    if (!cur.contains('default')) cur.add('default');
    // Нормализуем и делаем уникальным.
    final normalized = <String>{};
    for (final s in cur) {
      final v = _slugSafe(s);
      normalized.add(v);
    }
    return normalized.toList();
  }

  /// Создаёт slug в индексе, чтобы он появился в каталоге.
  static Future<void> setCustomSystemSlugExists(String slug) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);

    final cur = getCustomSystemSlugs();
    if (cur.contains(s)) return;

    cur.add(s);
    await box.put(_kCustomSystemSlugsIndex, cur);
  }

  static Map<String, String> _decodeJsonStringMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }

  static Map<String, String> getCustomSystemDictionaryRawForSlug(
      String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);

    // Для `default` пробуем новый формат, а если нет - падаем на legacy.
    if (s == 'default') {
      final prefKey = _keyFor(_kCustomSystemDictionaryPrefix, s);
      final raw = box.get(prefKey) as String?;
      if (raw != null && raw.trim().isNotEmpty) {
        return _decodeJsonStringMap(raw);
      }
      return getCustomSystemDictionaryRaw();
    }

    final prefKey = _keyFor(_kCustomSystemDictionaryPrefix, s);
    final raw = box.get(prefKey) as String?;
    return _decodeJsonStringMap(raw);
  }

  static Future<void> setCustomSystemDictionaryRawForSlug(
      String slug, Map<String, String> m) async {
    final s = _slugSafe(slug);
    final json = jsonEncode(m);
    final box = Hive.box(settingsBox);

    await box.put(_keyFor(_kCustomSystemDictionaryPrefix, s), json);

    // Legacy compatibility.
    if (s == 'default') {
      await box.put(_kCustomSystemDictionary, json);
    }
  }

  static String getCustomSystemRulesPresetForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    if (s == 'default') {
      final prefKey = _keyFor(_kCustomSystemRulesPresetPrefix, s);
      final raw = box.get(prefKey) as String?;
      if (raw != null && raw.trim().isNotEmpty) return raw;
      return getCustomSystemRulesPreset();
    }
    return box
            .get(_keyFor(_kCustomSystemRulesPresetPrefix, s),
                defaultValue: 'balanced')
            as String;
  }

  static Future<void> setCustomSystemRulesPresetForSlug(
      String slug, String preset) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    await box.put(_keyFor(_kCustomSystemRulesPresetPrefix, s), preset);
    if (s == 'default') {
      await box.put(_kCustomSystemRulesPreset, preset);
    }
  }

  static String getCustomSystemAiVoiceNameForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    if (s == 'default') {
      final prefKey = _keyFor(_kCustomSystemAiVoiceNamePrefix, s);
      final raw = box.get(prefKey) as String?;
      if (raw != null && raw.trim().isNotEmpty) return raw;
      return getCustomSystemAiVoiceName();
    }
    return box
            .get(_keyFor(_kCustomSystemAiVoiceNamePrefix, s),
                defaultValue: 'Ваш голос')
            as String;
  }

  static Future<void> setCustomSystemAiVoiceNameForSlug(
      String slug, String name) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    await box.put(_keyFor(_kCustomSystemAiVoiceNamePrefix, s), name);
    if (s == 'default') {
      await box.put(_kCustomSystemAiVoiceName, name);
    }
  }

  static String getCustomSystemAiToneHintForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    if (s == 'default') {
      final prefKey = _keyFor(_kCustomSystemAiToneHintPrefix, s);
      final raw = box.get(prefKey) as String?;
      if (raw != null && raw.trim().isNotEmpty) return raw;
      return getCustomSystemAiToneHint();
    }
    return box
            .get(_keyFor(_kCustomSystemAiToneHintPrefix, s),
                defaultValue: 'задается пользователем')
            as String;
  }

  static Future<void> setCustomSystemAiToneHintForSlug(
      String slug, String hint) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    await box.put(_keyFor(_kCustomSystemAiToneHintPrefix, s), hint);
    if (s == 'default') {
      await box.put(_kCustomSystemAiToneHint, hint);
    }
  }

  static String getCustomSystemAiUserPromptForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    if (s == 'default') {
      final prefKey = _keyFor(_kCustomSystemAiUserPromptPrefix, s);
      final raw = box.get(prefKey) as String?;
      if (raw != null && raw.trim().isNotEmpty) return raw;
      return getCustomSystemAiUserPrompt();
    }
    return box
            .get(_keyFor(_kCustomSystemAiUserPromptPrefix, s),
                defaultValue: '')
            as String;
  }

  static Future<void> setCustomSystemAiUserPromptForSlug(
      String slug, String prompt) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    await box.put(_keyFor(_kCustomSystemAiUserPromptPrefix, s), prompt);
    if (s == 'default') {
      await box.put(_kCustomSystemAiUserPrompt, prompt);
    }
  }

  static String getCustomSystemThemeNameForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final raw = box.get(_keyFor(_kCustomSystemThemeNamePrefix, s)) as String?;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return s == 'default' ? 'Custom' : s;
  }

  static Future<void> setCustomSystemThemeNameForSlug(
      String slug, String themeName) async {
    final s = _slugSafe(slug);
    await Hive.box(settingsBox).put(
      _keyFor(_kCustomSystemThemeNamePrefix, s),
      themeName.trim(),
    );
  }

  static Map<String, String> getCustomSystemColorsHexForSlug(String slug) {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final raw = box.get(_keyFor(_kCustomSystemColorsJsonPrefix, s)) as String?;
    return _decodeJsonStringMap(raw);
  }

  static Future<void> setCustomSystemColorsHexForSlug(
      String slug, Map<String, String> hexMap) async {
    final s = _slugSafe(slug);
    await Hive.box(settingsBox).put(
      _keyFor(_kCustomSystemColorsJsonPrefix, s),
      jsonEncode(hexMap),
    );
  }

  static String? getCustomSystemBackgroundAssetPathForSlug(String slug) {
    final s = _slugSafe(slug);
    final raw = Hive.box(settingsBox)
        .get(_keyFor(_kCustomSystemBgAssetPathPrefix, s)) as String?;
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setCustomSystemBackgroundAssetPathForSlug(
    String slug,
    String? path,
  ) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final v = path?.trim();
    if (v == null || v.isEmpty) {
      await box.delete(_keyFor(_kCustomSystemBgAssetPathPrefix, s));
      return;
    }
    await box.put(_keyFor(_kCustomSystemBgAssetPathPrefix, s), v);
  }

  static String? getCustomSystemBackgroundKindForSlug(String slug) {
    final s = _slugSafe(slug);
    final raw = Hive.box(settingsBox)
        .get(_keyFor(_kCustomSystemBgKindPrefix, s)) as String?;
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setCustomSystemBackgroundKindForSlug(
    String slug,
    String? kind,
  ) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final v = kind?.trim();
    if (v == null || v.isEmpty) {
      await box.delete(_keyFor(_kCustomSystemBgKindPrefix, s));
      return;
    }
    await box.put(_keyFor(_kCustomSystemBgKindPrefix, s), v);
  }

  static String? getCustomSystemParticlesKindForSlug(String slug) {
    final s = _slugSafe(slug);
    final raw = Hive.box(settingsBox)
        .get(_keyFor(_kCustomSystemParticlesKindPrefix, s)) as String?;
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setCustomSystemParticlesKindForSlug(
    String slug,
    String? kind,
  ) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final v = kind?.trim();
    if (v == null || v.isEmpty) {
      await box.delete(_keyFor(_kCustomSystemParticlesKindPrefix, s));
      return;
    }
    await box.put(_keyFor(_kCustomSystemParticlesKindPrefix, s), v);
  }

  static double? getCustomSystemPanelRadiusForSlug(String slug) {
    final s = _slugSafe(slug);
    final raw =
        Hive.box(settingsBox).get(_keyFor(_kCustomSystemPanelRadiusPrefix, s));
    if (raw is num) return raw.toDouble();
    return null;
  }

  static Future<void> setCustomSystemPanelRadiusForSlug(
    String slug,
    double? radius,
  ) async {
    final s = _slugSafe(slug);
    final box = Hive.box(settingsBox);
    final v = radius;
    if (v == null || v.isNaN || v.isInfinite) {
      await box.delete(_keyFor(_kCustomSystemPanelRadiusPrefix, s));
      return;
    }
    await box.put(_keyFor(_kCustomSystemPanelRadiusPrefix, s), v);
  }

  // ============================================================
  // Dungeons (цепочки этапов)
  // ============================================================

  static List<Dungeon> getDungeons() {
    final raw = Hive.box(settingsBox).get(_kDungeonsJson);
    if (raw is! String || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => Dungeon.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static Future<void> _setDungeons(List<Dungeon> dungeons) async {
    final json = jsonEncode(dungeons.map((d) => d.toMap()).toList());
    await Hive.box(settingsBox).put(_kDungeonsJson, json);
  }

  static Future<void> createDungeon(Dungeon dungeon) async {
    final cur = getDungeons().toList();
    cur.add(dungeon);
    await _setDungeons(cur);
    await _spawnDungeonStageQuest(dungeon, stageIndex: 0);
  }

  static String _dungeonTag(String dungeonId) => 'dungeon:$dungeonId';
  static String _dungeonStageTag(int stageIndex) => 'dungeon_stage:${stageIndex + 1}';

  static Future<void> _spawnDungeonStageQuest(
    Dungeon dungeon, {
    required int stageIndex,
  }) async {
    if (stageIndex < 0 || stageIndex >= dungeon.totalStages) return;

    final title = dungeon.stageTitles[stageIndex];
    final desc = dungeon.stageDescriptions[stageIndex];

    // Важное: спавним только текущий этап, следующий появится после complete.
    await addQuest(
      Quest(
        title: title,
        description: desc,
        type: QuestType.special,
        experienceReward: 35,
        goldReward: 25,
        statPointsReward: 1,
        tags: [
          'dungeon',
          _dungeonTag(dungeon.id),
          _dungeonStageTag(stageIndex),
          'system',
        ],
        difficulty: 3,
        mandatory: true,
        expiresAt: DateTime.now().add(const Duration(hours: 72)),
      ),
    );
  }

  /// Возвращает dungeonId, если квест является этапом данжа.
  static String? dungeonIdFromQuest(Quest quest) {
    for (final tag in quest.tags) {
      final s = tag.trim().toLowerCase();
      if (s.startsWith('dungeon:')) {
        final id = tag.substring('dungeon:'.length).trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  static int? dungeonStageIndexFromQuest(Quest quest) {
    for (final tag in quest.tags) {
      final s = tag.trim().toLowerCase();
      if (s.startsWith('dungeon_stage:')) {
        final raw = tag.substring('dungeon_stage:'.length).trim();
        final n = int.tryParse(raw);
        if (n == null) continue;
        return n - 1; // tag uses 1-based
      }
    }
    return null;
  }

  static Future<void> advanceDungeonOnStageComplete(Quest completedQuest) async {
    final dungeonId = dungeonIdFromQuest(completedQuest);
    final stageIndex = dungeonStageIndexFromQuest(completedQuest);
    if (dungeonId == null || stageIndex == null) return;

    final cur = getDungeons().toList();
    final idx = cur.indexWhere((d) => d.id == dungeonId);
    if (idx < 0) return;
    final d = cur[idx];
    if (!d.isActive) return;

    final nextIndex = stageIndex + 1;
    if (nextIndex >= d.totalStages) {
      cur[idx] = d.copyWith(
        status: DungeonStatus.completed,
        currentStageIndex: d.totalStages,
        completedAt: DateTime.now(),
      );
      await _setDungeons(cur);
      return;
    }

    cur[idx] = d.copyWith(currentStageIndex: nextIndex);
    await _setDungeons(cur);
    await _spawnDungeonStageQuest(d, stageIndex: nextIndex);
  }

  static Future<void> failDungeonOnStageFail(Quest failedQuest) async {
    final dungeonId = dungeonIdFromQuest(failedQuest);
    if (dungeonId == null) return;
    final cur = getDungeons().toList();
    final idx = cur.indexWhere((d) => d.id == dungeonId);
    if (idx < 0) return;
    final d = cur[idx];
    if (!d.isActive) return;
    cur[idx] = d.copyWith(status: DungeonStatus.failed, failedAt: DateTime.now());
    await _setDungeons(cur);
  }

  static SystemConfig getCustomSystemConfigForSlug(String slug) {
    final s = _slugSafe(slug);
    final raw = getCustomSystemDictionaryRawForSlug(s);

    String pick(String key, String fallback) {
      final v = raw[key]?.trim();
      if (v == null || v.isEmpty) return fallback;
      return v;
    }

    return SystemConfig(
      id: SystemId.custom,
      dictionary: SystemDictionary(
        levelName: pick('levelName', 'Уровень'),
        experienceName: pick('experienceName', 'Опыт'),
        currencyName: pick('currencyName', 'Валюта'),
        energyName: pick('energyName', 'Энергия'),
        skillsName: pick('skillsName', 'Навыки'),
      ),
      aiVoiceName: getCustomSystemAiVoiceNameForSlug(s).trim().isEmpty
          ? 'Ваш голос'
          : getCustomSystemAiVoiceNameForSlug(s).trim(),
      aiToneHint: getCustomSystemAiToneHintForSlug(s).trim().isEmpty
          ? 'задается пользователем'
          : getCustomSystemAiToneHintForSlug(s).trim(),
    );
  }

  static Map<String, int> getTagCounts({String? systemKey}) {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final raw = box.get(_kTagCountsBySystem) as String?;
    final bySystem = _decodeJsonObj(raw);
    final entry = bySystem[key];
    if (entry is Map) {
      return entry.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    // Legacy fallback (solo).
    if (key == SystemId.solo.value) {
      final legacy = box.get(_kTagCounts);
      if (legacy is Map) {
        return legacy.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    }
    return {};
  }

  static Future<void> incrementTagCounts(
    Iterable<String> tags, {
    String? systemKey,
  }) async {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final cur = Map<String, int>.from(getTagCounts(systemKey: key));
    for (final t in tags) {
      final tag = t.toLowerCase().trim();
      if (tag.isEmpty) continue;
      cur[tag] = (cur[tag] ?? 0) + 1;
    }

    final bySystem = _decodeJsonObj(box.get(_kTagCountsBySystem) as String?);
    bySystem[key] = cur;
    await _writeJsonObj(_kTagCountsBySystem, bySystem);

    // Legacy mirror (solo only).
    if (key == SystemId.solo.value) {
      await box.put(_kTagCounts, cur);
    }
  }

  static Map<String, String> getMageRuneLastUsedByTag() {
    final box = Hive.box(settingsBox);
    final raw = box.get(_kMageRuneLastUsed);
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  static Future<void> markMageRunesUsed(Iterable<String> tags) async {
    final box = Hive.box(settingsBox);
    final cur = Map<String, String>.from(getMageRuneLastUsedByTag());
    final now = DateTime.now().toIso8601String();
    for (final t in tags) {
      final key = t.toLowerCase().trim();
      if (key.isEmpty) continue;
      cur[key] = now;
    }
    await box.put(_kMageRuneLastUsed, cur);
  }

  static Map<String, String> getCustomSystemDictionaryRaw() {
    final box = Hive.box(settingsBox);
    final raw = box.get(_kCustomSystemDictionary) as String?;
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }

  static Future<void> setCustomSystemDictionaryRaw(Map<String, String> m) async {
    await Hive.box(settingsBox).put(_kCustomSystemDictionary, jsonEncode(m));
  }

  static String getCustomSystemRulesPreset() {
    return Hive.box(settingsBox)
            .get(_kCustomSystemRulesPreset, defaultValue: 'balanced')
        as String;
  }

  static Future<void> setCustomSystemRulesPreset(String preset) async {
    await Hive.box(settingsBox).put(_kCustomSystemRulesPreset, preset);
  }

  static String getCustomSystemAiVoiceName() {
    return Hive.box(settingsBox)
        .get(_kCustomSystemAiVoiceName, defaultValue: 'Ваш голос') as String;
  }

  static Future<void> setCustomSystemAiVoiceName(String name) async {
    await Hive.box(settingsBox).put(_kCustomSystemAiVoiceName, name);
  }

  static String getCustomSystemAiToneHint() {
    return Hive.box(settingsBox)
            .get(_kCustomSystemAiToneHint, defaultValue: 'задается пользователем')
        as String;
  }

  static Future<void> setCustomSystemAiToneHint(String hint) async {
    await Hive.box(settingsBox).put(_kCustomSystemAiToneHint, hint);
  }

  static String getCustomSystemAiUserPrompt() {
    return Hive.box(settingsBox)
        .get(_kCustomSystemAiUserPrompt, defaultValue: '') as String;
  }

  static Future<void> setCustomSystemAiUserPrompt(String prompt) async {
    await Hive.box(settingsBox).put(_kCustomSystemAiUserPrompt, prompt);
  }

  static SystemConfig getCustomSystemConfig() {
    // Legacy “single custom system” entry point.
    return getCustomSystemConfigForSlug('default');
  }

  static List<String> getUnlockedAchievements({String? systemKey}) {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final raw = box.get(_kAchievementsBySystem) as String?;
    final bySystem = _decodeJsonObj(raw);
    final entry = bySystem[key];
    if (entry is List) {
      return entry.map((e) => e.toString()).toList();
    }

    // Legacy fallback (solo).
    if (key == SystemId.solo.value) {
      final legacy = box.get(_kAchievements);
      if (legacy is List) {
        return legacy.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  static Future<void> unlockAchievement(
    String id, {
    String? systemKey,
  }) async {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final cur = List<String>.from(getUnlockedAchievements(systemKey: key));
    if (cur.contains(id)) return;
    cur.add(id);

    final bySystem = _decodeJsonObj(box.get(_kAchievementsBySystem) as String?);
    bySystem[key] = cur;
    await _writeJsonObj(_kAchievementsBySystem, bySystem);

    // Legacy mirror (solo only).
    if (key == SystemId.solo.value) {
      await box.put(_kAchievements, cur);
    }
  }

  static String? getGuildName() {
    return Hive.box(settingsBox).get(_kGuildName) as String?;
  }

  static Future<void> setGuildName(String? name) async {
    final box = Hive.box(settingsBox);
    if (name == null || name.trim().isEmpty) {
      await box.delete(_kGuildName);
    } else {
      await box.put(_kGuildName, name.trim());
    }
  }

  static String getSocialDisplayName({Hunter? fallbackHunter}) {
    final box = Hive.box(settingsBox);
    final v = (box.get(_kSocialDisplayName) as String?)?.trim();
    if (v != null && v.isNotEmpty) return v;
    final fallback = (fallbackHunter?.name ?? getHunter()?.name ?? '').trim();
    return fallback.isEmpty ? 'Player' : fallback;
  }

  static Future<void> setSocialDisplayName(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    await Hive.box(settingsBox).put(_kSocialDisplayName, v);
  }

  static String getOrCreateSocialDiscriminator() {
    final box = Hive.box(settingsBox);
    final existing = (box.get(_kSocialDiscriminator) as String?)?.trim();
    if (existing != null && RegExp(r'^\d{4}$').hasMatch(existing)) {
      return existing;
    }
    final d = (Random().nextInt(10000)).toString().padLeft(4, '0');
    unawaited(box.put(_kSocialDiscriminator, d));
    return d;
  }

  static String getSocialHandle({Hunter? fallbackHunter}) {
    final name = getSocialDisplayName(fallbackHunter: fallbackHunter);
    final d = getOrCreateSocialDiscriminator();
    return '$name#$d';
  }

  static String getThemeSkinId() {
    return Hive.box(settingsBox).get(_kThemeSkin, defaultValue: 'solo')
        as String;
  }

  static Future<void> setThemeSkinId(String id) async {
    await Hive.box(settingsBox).put(_kThemeSkin, id);
  }

  static String getActiveSystemId() {
    return Hive.box(settingsBox).get(_kActiveSystemId, defaultValue: 'solo')
        as String;
  }

  static Future<void> setActiveSystemId(String id) async {
    await Hive.box(settingsBox).put(_kActiveSystemId, id);
  }

  static bool isSystemSelectionShown() {
    return Hive.box(settingsBox)
            .get(_kSystemSelectionShown, defaultValue: false) ==
        true;
  }

  static Future<void> setSystemSelectionShown(bool shown) async {
    await Hive.box(settingsBox).put(_kSystemSelectionShown, shown);
  }

  static Map<String, String> getStatLabelOverrides() {
    final raw = Hive.box(settingsBox).get(_kStatLabels);
    if (raw is! String || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> setStatLabelOverrides(Map<String, String> m) async {
    await Hive.box(settingsBox).put(_kStatLabels, jsonEncode(m));
  }

  static void updatePersonalRecords(
    int level,
    int gold, {
    String? systemKey,
  }) {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final raw = box.get(_kRecordsBySystem) as String?;
    final bySystem = _decodeJsonObj(raw);
    final entry = bySystem[key];
    final cur = entry is Map ? Map<String, dynamic>.from(entry) : <String, dynamic>{};

    final bl = ((cur['bestLevel'] ?? 0) as num).toInt();
    final bg = ((cur['bestGold'] ?? 0) as num).toInt();
    var nextBestLevel = bl;
    var nextBestGold = bg;
    if (level > bl) nextBestLevel = level;
    if (gold > bg) nextBestGold = gold;

    cur['bestLevel'] = nextBestLevel;
    cur['bestGold'] = nextBestGold;
    bySystem[key] = cur;
    unawaited(_writeJsonObj(_kRecordsBySystem, bySystem));

    // Legacy mirror (solo only).
    if (key == SystemId.solo.value) {
      box.put(_kBestLevel, nextBestLevel);
      box.put(_kBestGold, nextBestGold);
    }
  }

  static int getRecordBestLevel({String? systemKey}) {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final raw = box.get(_kRecordsBySystem) as String?;
    final bySystem = _decodeJsonObj(raw);
    final entry = bySystem[key];
    if (entry is Map && entry['bestLevel'] is num) {
      return (entry['bestLevel'] as num).toInt();
    }

    // Legacy fallback (solo).
    if (key == SystemId.solo.value) {
      return (box.get(_kBestLevel, defaultValue: 0) as num).toInt();
    }
    return 0;
  }

  static int getRecordBestGold({String? systemKey}) {
    final key = systemKey?.trim().isNotEmpty == true
        ? systemKey!.trim()
        : _activeSystemMetaKey();

    final box = Hive.box(settingsBox);
    final raw = box.get(_kRecordsBySystem) as String?;
    final bySystem = _decodeJsonObj(raw);
    final entry = bySystem[key];
    if (entry is Map && entry['bestGold'] is num) {
      return (entry['bestGold'] as num).toInt();
    }

    // Legacy fallback (solo).
    if (key == SystemId.solo.value) {
      return (box.get(_kBestGold, defaultValue: 0) as num).toInt();
    }
    return 0;
  }

  /// Сброс тегов и достижений вместе с прогрессом охотника.
  static Future<void> clearGamificationMeta() async {
    final box = Hive.box(settingsBox);
    await box.delete(_kTagCounts);
    await box.delete(_kTagCountsBySystem);
    await box.delete(_kAchievements);
    await box.delete(_kAchievementsBySystem);
    await box.delete(_kBestLevel);
    await box.delete(_kBestGold);
    await box.delete(_kRecordsBySystem);
    // Legacy keys + per-system keys.
    await box.delete(_kTutorialAwakeningSeeded);
    await box.delete(_kAwakeningTutorialSceneShown);
    await box.delete(_kStoryMilestonesSpawned);
    for (final id in SystemId.values) {
      await box.delete(_tutorialAwakeningSeededKey(id));
      await box.delete(_awakeningTutorialSceneShownKey(id));
      await box.delete(_storyMilestonesSpawnedKey(id));
    }
    await box.delete(_kWorldEventKind);
    await box.delete(_kWorldEventUntil);
    await box.delete(_kMoraleHardFailStreak);
    await box.delete(_kActiveSystemId);
    await box.delete(_kSystemSelectionShown);
    await box.delete(_kMageRuneLastUsed);
    await box.delete(_kCustomSystemDictionary);
    await box.delete(_kCustomSystemRulesPreset);
    await box.delete(_kCustomSystemAiVoiceName);
    await box.delete(_kCustomSystemAiToneHint);
    await box.delete(_kCustomSystemAiUserPrompt);
  }

  static String exportGameBackupJson() {
    final settings = Hive.box(settingsBox);

    // Сохраняем все профили по system_id (multiverse).
    final profiles = <String, Map<String, dynamic>>{};
    final hb = Hive.box<Map>(hunterBox);
    for (final entry in hb.toMap().entries) {
      final key = entry.key.toString();
      final rawMap = entry.value;

      SystemId id;
      if (key == 'current') {
        id = SystemId.solo;
      } else if (key.startsWith('profile_')) {
        final rawId = key.replaceFirst('profile_', '');
        id = SystemId.fromValue(rawId);
      } else {
        continue;
      }

      final hunter = Hunter.fromMap(Map<String, dynamic>.from(rawMap));
      final (normalized, didMigrate) = _normalizeHunterExperienceCurve(hunter);
      profiles[id.value] = normalized.toMap();
      if (didMigrate) {
        unawaited(saveHunter(normalized, systemId: id));
      }
    }

    // Сохраняем ВСЕ квесты (по системе фильтруем при чтении).
    final quests = getAllQuests(includeAllSystems: true);
    final activeHunter = getHunter();

    bool seededFor(SystemId id) {
      final key = _tutorialAwakeningSeededKey(id);
      final v = settings.get(key);
      if (v == null) {
        if (id == SystemId.solo) {
          return settings.get(_kTutorialAwakeningSeeded, defaultValue: false) ==
              true;
        }
        return false;
      }
      return v == true;
    }

    bool sceneShownFor(SystemId id) {
      final key = _awakeningTutorialSceneShownKey(id);
      final v = settings.get(key);
      if (v == null) {
        if (id == SystemId.solo) {
          return settings.get(_kAwakeningTutorialSceneShown,
                  defaultValue: false) ==
              true;
        }
        return false;
      }
      return v == true;
    }

    List<int>? storySpawnedFor(SystemId id) {
      final key = _storyMilestonesSpawnedKey(id);
      final v = settings.get(key);
      if (v == null) {
        if (id == SystemId.solo) {
          final legacy = settings.get(_kStoryMilestonesSpawned);
          if (legacy is List) {
            return legacy.map((e) => (e as num).toInt()).toList();
          }
        }
        return null;
      }
      if (v is List) {
        return v.map((e) => (e as num).toInt()).toList();
      }
      return null;
    }

    final tutorialSeededBySystem = <String, bool>{
      for (final id in SystemId.values) id.value: seededFor(id),
    };
    final tutorialSceneShownBySystem = <String, bool>{
      for (final id in SystemId.values) id.value: sceneShownFor(id),
    };
    final storyMilestonesSpawnedBySystem = <String, List<int>>{
      for (final id in SystemId.values)
        if (storySpawnedFor(id) != null)
          id.value: storySpawnedFor(id)!,
    };

    // Custom multi-world catalog (custom_<slug>).
    final customSystems = <String, Map<String, dynamic>>{};
    for (final slug in getCustomSystemSlugs()) {
      customSystems[slug] = <String, dynamic>{
        'dictionary': getCustomSystemDictionaryRawForSlug(slug),
        'rulesPreset': getCustomSystemRulesPresetForSlug(slug),
        'aiVoiceName': getCustomSystemAiVoiceNameForSlug(slug),
        'aiToneHint': getCustomSystemAiToneHintForSlug(slug),
        'aiUserPrompt': getCustomSystemAiUserPromptForSlug(slug),
        'themeName': getCustomSystemThemeNameForSlug(slug),
        'colorsHex': getCustomSystemColorsHexForSlug(slug),
        'backgroundAssetPath': getCustomSystemBackgroundAssetPathForSlug(slug),
        'backgroundKind': getCustomSystemBackgroundKindForSlug(slug),
        'particlesKind': getCustomSystemParticlesKindForSlug(slug),
        'panelRadius': getCustomSystemPanelRadiusForSlug(slug),
      };
    }

    return const JsonEncoder.withIndent('  ').convert({
      // Legacy/compat: текущий active hunter.
      'hunter': activeHunter?.toMap(),
      'hunterProfiles': profiles,
      'quests': quests.map((q) => q.toMap()).toList(),
      // Legacy (compat). Активная система в данный момент экспорта.
      'tagCounts': getTagCounts(),
      'achievements': getUnlockedAchievements(),
      'guild': getGuildName(),
      'themeSkin': getThemeSkinId(),
      'statLabels': getStatLabelOverrides(),
      'records': {
        'bestLevel': getRecordBestLevel(),
        'bestGold': getRecordBestGold(),
      },
      'meta': {
        // Legacy fields (solo).
        'tutorialAwakeningSeeded':
            settings.get(_kTutorialAwakeningSeeded, defaultValue: false),
        'tutorialAwakeningSceneShown':
            settings.get(_kAwakeningTutorialSceneShown, defaultValue: false),
        'storyMilestonesSpawned': settings.get(_kStoryMilestonesSpawned),
        // New multiverse fields.
        'tutorialAwakeningSeededBySystem': tutorialSeededBySystem,
        'tutorialAwakeningSceneShownBySystem': tutorialSceneShownBySystem,
        'storyMilestonesSpawnedBySystem': storyMilestonesSpawnedBySystem,
        'worldEventKind': settings.get(_kWorldEventKind),
        'worldEventUntil': settings.get(_kWorldEventUntil),
        'moraleHardFailStreak': settings.get(_kMoraleHardFailStreak),
        'activeSystemId': settings.get(_kActiveSystemId, defaultValue: 'solo'),
        'systemSelectionShown':
            settings.get(_kSystemSelectionShown, defaultValue: false),
        'onboardingStepBySystem': {
          for (final id in SystemId.values)
            id.value: settings.get(_onboardingStepKey(id)),
        },
        'onboardingPersonaBySystem': {
          for (final id in SystemId.values)
            id.value: settings.get(_onboardingPersonaKey(id)),
        },
        'mageRuneLastUsed': settings.get(_kMageRuneLastUsed),
        'customSystemDictionary': settings.get(_kCustomSystemDictionary),
        'customSystemRulesPreset': settings.get(_kCustomSystemRulesPreset),
        'customSystemAiVoiceName': settings.get(_kCustomSystemAiVoiceName),
        'customSystemAiToneHint': settings.get(_kCustomSystemAiToneHint),
        'customSystemAiUserPrompt': settings.get(_kCustomSystemAiUserPrompt),
        // New per-system meta progress.
        'tagCountsBySystem': settings.get(_kTagCountsBySystem),
        'achievementsBySystem': settings.get(_kAchievementsBySystem),
        'recordsBySystem': settings.get(_kRecordsBySystem),
        // New multi-custom catalog.
        'customSystems': customSystems,
      },
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> importGameBackupJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data['hunterProfiles'] is Map) {
      final rawProfiles = data['hunterProfiles'] as Map;
      for (final entry in rawProfiles.entries) {
        final systemKey = entry.key.toString();
        final id = SystemId.fromValue(systemKey);
        if (entry.value is Map) {
          final raw = Hunter.fromMap(
            Map<String, dynamic>.from(Map<String, dynamic>.from(entry.value as Map)),
          );
          final (normalized, _) = _normalizeHunterExperienceCurve(raw);
          await saveHunter(normalized, systemId: id);
        }
      }
    } else if (data['hunter'] != null) {
      final raw = Hunter.fromMap(
        Map<String, dynamic>.from(data['hunter'] as Map),
      );
      final (normalized, _) = _normalizeHunterExperienceCurve(raw);
      await saveHunter(normalized, systemId: SystemId.solo);
    }

    if (data['quests'] is List) {
      await deleteAllQuests();
      for (final raw in data['quests'] as List) {
        await addQuest(
          Quest.fromMap(Map<String, dynamic>.from(raw as Map)),
          ensureSystemTag: false,
        );
      }
    }
    final box = Hive.box(settingsBox);
    if (data['tagCounts'] is Map) {
      await box.put(_kTagCounts, data['tagCounts']);
    }
    if (data['achievements'] is List) {
      await box.put(_kAchievements, data['achievements']);
    }
    if (data.containsKey('guild')) {
      await setGuildName(data['guild'] as String?);
    }
    if (data['themeSkin'] != null) {
      await setThemeSkinId(data['themeSkin'] as String);
    }
    if (data['statLabels'] is Map) {
      await setStatLabelOverrides(
        (data['statLabels'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }
    final rec = data['records'];
    if (rec is Map) {
      if (rec['bestLevel'] != null) {
        await box.put(_kBestLevel, (rec['bestLevel'] as num).toInt());
      }
      if (rec['bestGold'] != null) {
        await box.put(_kBestGold, (rec['bestGold'] as num).toInt());
      }
    }

    final meta0 = data['meta'];
    if (meta0 is Map) {
      final onboardingBySystem = meta0['onboardingStepBySystem'];
      if (onboardingBySystem is Map) {
        for (final entry in onboardingBySystem.entries) {
          final id = SystemId.fromValue(entry.key.toString());
          final raw = entry.value?.toString();
          if (raw != null && raw.trim().isNotEmpty) {
            await box.put(_onboardingStepKey(id), raw.trim());
          }
        }
      }

      final personaBySystem = meta0['onboardingPersonaBySystem'];
      if (personaBySystem is Map) {
        for (final entry in personaBySystem.entries) {
          final id = SystemId.fromValue(entry.key.toString());
          final raw = entry.value?.toString();
          if (raw != null && raw.trim().isNotEmpty) {
            await box.put(_onboardingPersonaKey(id), raw.trim());
          }
        }
      }
    }
    final meta = data['meta'];
    if (meta is Map) {
      final m = Map<String, dynamic>.from(meta);
      if (m['tutorialAwakeningSeededBySystem'] is Map) {
        final bySystem = m['tutorialAwakeningSeededBySystem'] as Map;
        for (final entry in bySystem.entries) {
          final id = SystemId.fromValue(entry.key.toString());
          await box.put(
            _tutorialAwakeningSeededKey(id),
            entry.value == true,
          );
        }
      } else if (m.containsKey('tutorialAwakeningSeeded')) {
        // Legacy solo.
        await box.put(
          _tutorialAwakeningSeededKey(SystemId.solo),
          m['tutorialAwakeningSeeded'] == true,
        );
      }

      if (m['tutorialAwakeningSceneShownBySystem'] is Map) {
        final bySystem = m['tutorialAwakeningSceneShownBySystem'] as Map;
        for (final entry in bySystem.entries) {
          final id = SystemId.fromValue(entry.key.toString());
          await box.put(
            _awakeningTutorialSceneShownKey(id),
            entry.value == true,
          );
        }
      } else if (m.containsKey('tutorialAwakeningSceneShown')) {
        await box.put(
          _awakeningTutorialSceneShownKey(SystemId.solo),
          m['tutorialAwakeningSceneShown'] == true,
        );
      }

      if (m['storyMilestonesSpawnedBySystem'] is Map) {
        final bySystem = m['storyMilestonesSpawnedBySystem'] as Map;
        for (final entry in bySystem.entries) {
          final id = SystemId.fromValue(entry.key.toString());
          if (entry.value is List) {
            await box.put(
              _storyMilestonesSpawnedKey(id),
              entry.value,
            );
          }
        }
      } else if (m['storyMilestonesSpawned'] is List) {
        await box.put(
          _storyMilestonesSpawnedKey(SystemId.solo),
          m['storyMilestonesSpawned'],
        );
      }

      if (m['worldEventKind'] != null) {
        await box.put(_kWorldEventKind, m['worldEventKind'].toString());
      }
      if (m['worldEventUntil'] != null) {
        await box.put(_kWorldEventUntil, m['worldEventUntil'].toString());
      }
      if (m['moraleHardFailStreak'] != null) {
        await box.put(
          _kMoraleHardFailStreak,
          (m['moraleHardFailStreak'] as num).toInt(),
        );
      }
      if (m['activeSystemId'] != null) {
        final v = m['activeSystemId']?.toString();
        if (v != null && v.isNotEmpty) {
          await box.put(_kActiveSystemId, v);
        }
      }
      if (m.containsKey('systemSelectionShown')) {
        await box.put(_kSystemSelectionShown, m['systemSelectionShown'] == true);
      }
      if (m['mageRuneLastUsed'] is Map) {
        await box.put(_kMageRuneLastUsed, m['mageRuneLastUsed']);
      }
      if (m['customSystemDictionary'] is String) {
        await box.put(_kCustomSystemDictionary, m['customSystemDictionary']);
      }
      if (m['customSystemRulesPreset'] != null) {
        await box.put(
          _kCustomSystemRulesPreset,
          m['customSystemRulesPreset'].toString(),
        );
      }
      if (m['customSystemAiVoiceName'] != null) {
        await box.put(
          _kCustomSystemAiVoiceName,
          m['customSystemAiVoiceName'].toString(),
        );
      }
      if (m['customSystemAiToneHint'] != null) {
        await box.put(
          _kCustomSystemAiToneHint,
          m['customSystemAiToneHint'].toString(),
        );
      }
      if (m['customSystemAiUserPrompt'] != null) {
        await box.put(
          _kCustomSystemAiUserPrompt,
          m['customSystemAiUserPrompt'].toString(),
        );
      }

      // New per-system meta progress.
      if (m['tagCountsBySystem'] is String) {
        await box.put(_kTagCountsBySystem, m['tagCountsBySystem']);
      }
      if (m['achievementsBySystem'] is String) {
        await box.put(_kAchievementsBySystem, m['achievementsBySystem']);
      }
      if (m['recordsBySystem'] is String) {
        await box.put(_kRecordsBySystem, m['recordsBySystem']);
      }

      // New multi-custom catalog (custom_<slug>).
      if (m['customSystems'] is Map) {
        final rawSystems = m['customSystems'] as Map;
        for (final entry in rawSystems.entries) {
          final slug = entry.key.toString();
          if (entry.value is! Map) continue;
          final sys = Map<String, dynamic>.from(entry.value as Map);

          await setCustomSystemSlugExists(slug);

          final dictRaw = sys['dictionary'];
          if (dictRaw is Map) {
            final dict = dictRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
            await setCustomSystemDictionaryRawForSlug(slug, dict);
          }
          if (sys['rulesPreset'] != null) {
            await setCustomSystemRulesPresetForSlug(
              slug,
              sys['rulesPreset'].toString(),
            );
          }
          if (sys['aiVoiceName'] != null) {
            await setCustomSystemAiVoiceNameForSlug(
              slug,
              sys['aiVoiceName'].toString(),
            );
          }
          if (sys['aiToneHint'] != null) {
            await setCustomSystemAiToneHintForSlug(
              slug,
              sys['aiToneHint'].toString(),
            );
          }
          if (sys['aiUserPrompt'] != null) {
            await setCustomSystemAiUserPromptForSlug(
              slug,
              sys['aiUserPrompt'].toString(),
            );
          }
          if (sys['themeName'] != null) {
            await setCustomSystemThemeNameForSlug(
              slug,
              sys['themeName'].toString(),
            );
          }
          final colorsRaw = sys['colorsHex'];
          if (colorsRaw is Map) {
            final colors = colorsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
            await setCustomSystemColorsHexForSlug(slug, colors);
          }

          if (sys['backgroundAssetPath'] != null) {
            await setCustomSystemBackgroundAssetPathForSlug(
              slug,
              sys['backgroundAssetPath']?.toString(),
            );
          }
          if (sys['backgroundKind'] != null) {
            await setCustomSystemBackgroundKindForSlug(
              slug,
              sys['backgroundKind']?.toString(),
            );
          }
          if (sys['particlesKind'] != null) {
            await setCustomSystemParticlesKindForSlug(
              slug,
              sys['particlesKind']?.toString(),
            );
          }
          final radiusRaw = sys['panelRadius'];
          if (radiusRaw is num) {
            await setCustomSystemPanelRadiusForSlug(
              slug,
              radiusRaw.toDouble(),
            );
          }
        }
      }
    }
  }
}

enum OnboardingStep {
  needLore('need_lore'),
  needPhilosophySelection('need_philosophy_selection'),
  needMasterEncounter('need_master_encounter'),
  needAiProcessing('need_ai_processing'),
  done('done');

  const OnboardingStep(this.value);
  final String value;

  static OnboardingStep fromValue(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    // Migration from legacy steps.
    if (v == 'need_system_selection') return OnboardingStep.needLore;
    if (v == 'need_awakening_scene') return OnboardingStep.needAiProcessing;
    for (final s in OnboardingStep.values) {
      if (s.value == v) return s;
    }
    return OnboardingStep.needLore;
  }
}

