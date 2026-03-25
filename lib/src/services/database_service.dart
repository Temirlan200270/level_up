import 'package:hive_flutter/hive_flutter.dart';
import '../models/hunter_model.dart';
import '../models/quest_model.dart';

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
  
  // Получить охотника
  static Hunter? getHunter() {
    try {
      final box = Hive.box<Map>(hunterBox);
      final map = box.get('current');
      if (map == null) return null;
      // Безопасное преобразование Map<dynamic, dynamic> в Map<String, dynamic>
      return Hunter.fromMap(Map<String, dynamic>.from(map));
    } catch (e) {
      // Если ошибка при чтении, возвращаем null
      return null;
    }
  }

  // Сохранить охотника
  static Future<void> saveHunter(Hunter hunter) async {
    final box = Hive.box<Map>(hunterBox);
    await box.put('current', hunter.toMap());
  }

  // Создать нового охотника (если его нет)
  static Future<Hunter> createDefaultHunter(String name) async {
    final existing = getHunter();
    if (existing != null) return existing;
    
    final newHunter = Hunter(name: name);
    await saveHunter(newHunter);
    return newHunter;
  }

  // Удалить охотника (для сброса прогресса)
  static Future<void> deleteHunter() async {
    final box = Hive.box<Map>(hunterBox);
    await box.delete('current');
  }

  // === КВЕСТЫ ===
  
  // Получить все квесты
  static List<Quest> getAllQuests() {
    try {
      final box = Hive.box<Map>(questsBox);
      return box.values
          .map((map) => Quest.fromMap(Map<String, dynamic>.from(map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      return Quest.fromMap(Map<String, dynamic>.from(map));
    } catch (e) {
      return null;
    }
  }

  // Добавить квест
  static Future<void> addQuest(Quest quest) async {
    final box = Hive.box<Map>(questsBox);
    await box.put(quest.id, quest.toMap());
  }

  // Обновить квест
  static Future<void> updateQuest(Quest quest) async {
    final box = Hive.box<Map>(questsBox);
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
}
