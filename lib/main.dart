
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/database_service.dart';
import 'src/services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация базы данных Hive
  await DatabaseService.init();
  
  // Инициализация переводов
  await TranslationService.init();
  
  // Инициализация ежедневных квестов (если их нет)
  await DatabaseService.initializeDailyQuests();
  
  runApp(const ProviderScope(child: MyApp()));
}
