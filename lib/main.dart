import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'src/services/database_service.dart';
import 'src/services/translation_service.dart';
import 'src/services/ai_service.dart';
import 'src/services/quest_notification_service.dart';
import 'src/services/supabase/supabase_config.dart';
import 'src/services/background_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Инициализация базы данных Hive
  await DatabaseService.init();

  // Правила агента для системных промптов ИИ
  await AIService.preloadAgentRules();

  // Инициализация переводов
  await TranslationService.init();

  // Локальные уведомления о дедлайнах квестов (Android / iOS / …)
  await QuestNotificationService.init();

  // Фоновая обработка дедлайнов/штрафов (workmanager). На Web не запускаем.
  if (!kIsWeb) {
    await BackgroundTasks.init();
  }

  // Инициализация ежедневных квестов (если их нет)
  await DatabaseService.initializeDailyQuests();

  // Онбординг «Пробуждение» для охотников без серии awakening
  await DatabaseService.ensureAwakeningTutorialIfNeeded();

  // Случайная аномалия Системы (напр. «Кровавая луна»), если слот свободен
  await DatabaseService.tryRollWorldEventOnSessionStart();

  // Нормализация шага онбординга (защитные переходы).
  await DatabaseService.normalizeOnboardingStep();

  runApp(const ProviderScope(child: MyApp()));
}
