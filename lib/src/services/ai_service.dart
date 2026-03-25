import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider_model.dart';
import '../models/quest_model.dart';
import '../core/systems/generated_system_theme_json.dart';

/// Универсальный сервис для работы с различными AI провайдерами
class AIService {
  /// Дополнительные правила агента из ассета (добавляются ко всем system-промптам).
  static String _agentRulesExtra = '';

  /// Загрузить `assets/agent_rules.txt` до первых запросов (вызывать из `main`).
  static Future<void> preloadAgentRules() async {
    try {
      _agentRulesExtra = await rootBundle.loadString('assets/agent_rules.txt');
    } catch (_) {
      _agentRulesExtra = '';
    }
  }

  /// Объединяет пользовательские правила с системным промптом.
  static String? _effectiveSystem(String? systemPrompt) {
    if (_agentRulesExtra.isEmpty) return systemPrompt;
    if (systemPrompt == null || systemPrompt.isEmpty) {
      return _agentRulesExtra;
    }
    return '$_agentRulesExtra\n\n---\n\n$systemPrompt';
  }

  // Настройки провайдера/модели остаются в SharedPreferences (не секреты).
  static const String _prefsProvider = 'ai_provider';
  static const String _prefsModel = 'ai_model';
  static const String _prefsKeysMigratedToSecure =
      'ai_api_keys_migrated_secure_v1';

  /// Легаси-ключи API в SharedPreferences (миграция в secure storage).
  static const String _prefsOpenAIKey = 'openai_api_key';
  static const String _prefsGeminiKey = 'gemini_api_key';
  static const String _prefsOpenRouterKey = 'openrouter_api_key';
  static const String _prefsHuggingFaceKey = 'huggingface_api_key';
  static const String _prefsClaudeKey = 'claude_api_key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String _secureKeyFor(AIProvider provider) =>
      'ai_api_key_${provider.name}';

  // Базовые URL для каждого провайдера
  static const Map<AIProvider, String> _apiBaseUrls = {
    AIProvider.openai: 'https://api.openai.com/v1',
    AIProvider.gemini: 'https://generativelanguage.googleapis.com/v1beta',
    AIProvider.openRouter: 'https://openrouter.ai/api/v1',
    AIProvider.huggingFace: 'https://api-inference.huggingface.co/models',
    AIProvider.claude: 'https://api.anthropic.com/v1',
  };

  /// Получить текущий провайдер
  static Future<AIProvider> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerStr = prefs.getString(_prefsProvider);
    if (providerStr != null) {
      return AIProvider.values.firstWhere(
        (e) => e.name == providerStr,
        orElse: () => AIProvider.openai,
      );
    }
    return AIProvider.openai;
  }

  /// Установить провайдера
  static Future<void> setProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsProvider, provider.name);
    // Устанавливаем модель по умолчанию для провайдера
    await setModel(AIModels.getDefaultModel(provider));
  }

  /// Получить текущую модель
  static Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsModel) ??
        AIModels.getDefaultModel(await getProvider());
  }

  /// Установить модель
  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsModel, model);
  }

  static String? _readLegacyApiKeyFromPrefs(
    SharedPreferences prefs,
    AIProvider provider,
  ) {
    switch (provider) {
      case AIProvider.openai:
        return prefs.getString(_prefsOpenAIKey);
      case AIProvider.gemini:
        return prefs.getString(_prefsGeminiKey);
      case AIProvider.openRouter:
        return prefs.getString(_prefsOpenRouterKey);
      case AIProvider.huggingFace:
        return prefs.getString(_prefsHuggingFaceKey);
      case AIProvider.claude:
        return prefs.getString(_prefsClaudeKey);
    }
  }

  static Future<void> _removeLegacyApiKeyFromPrefs(
    SharedPreferences prefs,
    AIProvider provider,
  ) async {
    switch (provider) {
      case AIProvider.openai:
        await prefs.remove(_prefsOpenAIKey);
        break;
      case AIProvider.gemini:
        await prefs.remove(_prefsGeminiKey);
        break;
      case AIProvider.openRouter:
        await prefs.remove(_prefsOpenRouterKey);
        break;
      case AIProvider.huggingFace:
        await prefs.remove(_prefsHuggingFaceKey);
        break;
      case AIProvider.claude:
        await prefs.remove(_prefsClaudeKey);
        break;
    }
  }

  /// Перенос ключей из SharedPreferences в `flutter_secure_storage` (один раз).
  static Future<void> _ensureApiKeysMigratedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKeysMigratedToSecure) == true) return;

    for (final provider in AIProvider.values) {
      final legacy = _readLegacyApiKeyFromPrefs(prefs, provider);
      if (legacy != null && legacy.isNotEmpty) {
        await _secureStorage.write(
          key: _secureKeyFor(provider),
          value: legacy,
        );
        await _removeLegacyApiKeyFromPrefs(prefs, provider);
      }
    }
    await prefs.setBool(_prefsKeysMigratedToSecure, true);
  }

  /// Получить API ключ для провайдера
  static Future<String?> getApiKey(AIProvider provider) async {
    await _ensureApiKeysMigratedFromPrefs();
    return _secureStorage.read(key: _secureKeyFor(provider));
  }

  /// Сохранить API ключ для провайдера
  static Future<void> setApiKey(AIProvider provider, String key) async {
    await _ensureApiKeysMigratedFromPrefs();
    await _secureStorage.write(key: _secureKeyFor(provider), value: key);
    final prefs = await SharedPreferences.getInstance();
    await _removeLegacyApiKeyFromPrefs(prefs, provider);
  }

  /// Проверка наличия API ключа
  static Future<bool> hasApiKey([AIProvider? provider]) async {
    final providerToCheck = provider ?? await getProvider();
    final key = await getApiKey(providerToCheck);
    return key != null && key.isNotEmpty;
  }

  /// Отправить сообщение к выбранному провайдеру
  static Future<String> sendMessage({
    required String message,
    String? systemPrompt,
    AIProvider? provider,
    String? model,
    double temperature = 0.7,
  }) async {
    final currentProvider = provider ?? await getProvider();
    final currentModel = model ?? await getModel();
    final apiKey = await getApiKey(currentProvider);

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API ключ не установлен для ${AIModels.getProviderName(currentProvider)}. '
        'Пожалуйста, установите ключ в настройках.',
      );
    }

    final system = _effectiveSystem(systemPrompt);

    switch (currentProvider) {
      case AIProvider.openai:
        return _sendOpenAIMessage(
          message: message,
          systemPrompt: system,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.gemini:
        return _sendGeminiMessage(
          message: message,
          systemPrompt: system,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.openRouter:
        return _sendOpenRouterMessage(
          message: message,
          systemPrompt: system,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.huggingFace:
        return _sendHuggingFaceMessage(
          message: message,
          systemPrompt: system,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.claude:
        return _sendClaudeMessage(
          message: message,
          systemPrompt: system,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
    }
  }

  // === OpenAI ===
  static Future<String> _sendOpenAIMessage({
    required String message,
    String? systemPrompt,
    required String model,
    required String apiKey,
    required double temperature,
  }) async {
    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': message});

    final response = await http.post(
      Uri.parse('${_apiBaseUrls[AIProvider.openai]}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
      }),
    );

    return _handleResponse(response, 'OpenAI');
  }

  // === Gemini ===
  static Future<String> _sendGeminiMessage({
    required String message,
    String? systemPrompt,
    required String model,
    required String apiKey,
    required double temperature,
  }) async {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt},
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Понял. Готов к работе.'},
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': message},
      ],
    });

    final response = await http.post(
      Uri.parse(
        '${_apiBaseUrls[AIProvider.gemini]}/models/$model:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {'temperature': temperature},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List;
      if (candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>;
        final parts = content['parts'] as List;
        return parts[0]['text'] as String;
      }
      throw Exception('Пустой ответ от Gemini');
    }
    return _handleResponse(response, 'Gemini');
  }

  // === OpenRouter ===
  static Future<String> _sendOpenRouterMessage({
    required String message,
    String? systemPrompt,
    required String model,
    required String apiKey,
    required double temperature,
  }) async {
    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': message});

    final response = await http.post(
      Uri.parse('${_apiBaseUrls[AIProvider.openRouter]}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://solo-leveling-app.com',
        'X-Title': 'Solo Leveling System',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
      }),
    );

    return _handleResponse(response, 'OpenRouter');
  }

  // === Hugging Face ===
  static Future<String> _sendHuggingFaceMessage({
    required String message,
    String? systemPrompt,
    required String model,
    required String apiKey,
    required double temperature,
  }) async {
    final fullMessage = systemPrompt != null
        ? '$systemPrompt\n\n$message'
        : message;

    final response = await http.post(
      Uri.parse('${_apiBaseUrls[AIProvider.huggingFace]}/$model'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'inputs': fullMessage,
        'parameters': {'temperature': temperature, 'return_full_text': false},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] as String;
      }
      throw Exception('Неожиданный формат ответа от Hugging Face');
    }
    return _handleResponse(response, 'Hugging Face');
  }

  // === Claude ===
  static Future<String> _sendClaudeMessage({
    required String message,
    String? systemPrompt,
    required String model,
    required String apiKey,
    required double temperature,
  }) async {
    final messages = <Map<String, dynamic>>[];
    messages.add({'role': 'user', 'content': message});

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': 1024,
      'messages': messages,
      'temperature': temperature,
    };

    if (systemPrompt != null) {
      body['system'] = systemPrompt;
    }

    final response = await http.post(
      Uri.parse('${_apiBaseUrls[AIProvider.claude]}/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List;
      if (content.isNotEmpty) {
        return content[0]['text'] as String;
      }
      throw Exception('Пустой ответ от Claude');
    }
    return _handleResponse(response, 'Claude');
  }

  // Обработка ответа
  static String _handleResponse(http.Response response, String providerName) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>;
        return message['content'] as String;
      }
      throw Exception('Пустой ответ от $providerName');
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        error['error']?['message'] ??
            'Ошибка при запросе к $providerName API: ${response.statusCode}',
      );
    }
  }

  /// Жёсткие потолки наград для ручного квеста (после ответа модели).
  static Map<String, dynamic> clampManualQuestBalance(
    Map<String, dynamic> raw,
    int hunterLevel,
  ) {
    final lv = hunterLevel.clamp(1, 999);
    final maxExp = (18 + lv * 4).clamp(15, 130);
    final maxGold = (12 + lv * 6).clamp(8, 280);
    final d = ((raw['difficulty'] as num?)?.toInt() ?? 2).clamp(1, 5);
    var exp = (raw['experienceReward'] as num?)?.toInt() ?? 20;
    var gold = (raw['goldReward'] as num?)?.toInt() ?? 10;
    var sp = (raw['statPointsReward'] as num?)?.toInt() ?? 0;
    exp = exp.clamp(5, maxExp);
    gold = gold.clamp(0, maxGold);
    sp = sp.clamp(0, 3);

    return {
      'difficulty': d,
      'experienceReward': exp,
      'goldReward': gold,
      'statPointsReward': sp,
      'mandatory': raw['mandatory'] == true,
    };
  }

  /// Балансировщик ручного квеста: только JSON, низкая температура, затем [clampManualQuestBalance].
  static Future<Map<String, dynamic>> balanceManualQuestDraft({
    required String title,
    required String description,
    required QuestType questType,
    required int hunterLevel,
    int playerDifficulty = 2,
    int playerGold = 10,
    int playerExp = 20,
    int playerStatPoints = 0,
    bool playerMandatory = false,
  }) async {
    final typeName = questType.name;
    const systemPrompt =
        '''Ты — Система Solo Leveling (античит-балансировщик).
Оцени черновик квеста охотника и верни СТРОГО один JSON без текста вокруг:
{
  "difficulty": целое 1-5,
  "experienceReward": целое,
  "goldReward": целое (фиксированное золото за завершение),
  "statPointsReward": целое 0-3,
  "mandatory": true или false (true только при явной критичности/дедлайне в описании),
  "rankLabel": краткая строка ранга E..S (например "C-Rank")
}
Правила:
- Уровень охотника ограничивает адекватность наград; сложные реальные задачи = выше difficulty.
- Тривиальным задачам не давай завышенных наград.
- Штрафной тип penalty сюда не попадает — не предлагай его.''';

    final userPrompt =
        '''Уровень охотника: $hunterLevel
Тип квеста: $typeName
Черновик игрока — сложность: $playerDifficulty, опыт: $playerExp, золото: $playerGold, очки статов: $playerStatPoints, обязательный: $playerMandatory

Название: $title
Описание: $description

Верни только JSON.''';

    final response = await sendMessage(
      message: userPrompt,
      systemPrompt: systemPrompt,
      temperature: 0.25,
    );

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('ИИ не вернул JSON для баланса');
      }
      parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    }
    return clampManualQuestBalance(parsed, hunterLevel);
  }

  /// Генерация квеста через ИИ
  static Future<Map<String, dynamic>> generateQuest({
    String? hunterLevel,
    String? hunterStats,
    String? lowestStatsFocus,
  }) async {
    final systemPrompt =
        '''Ты - Система из манги Solo Leveling. Твоя задача - генерировать интересные квесты для охотника.

Формат ответа должен быть строго в JSON:
{
  "title": "Название квеста",
  "description": "Описание квеста",
  "type": "daily|weekly|special|story",
  "experienceReward": число (10-50),
  "statPointsReward": число (0-5),
  "goldReward": число (0-40, фиксированное золото за завершение)
}

Квесты должны быть реалистичными и выполнимыми в реальной жизни. Используй стиль Solo Leveling - драматичный, но мотивирующий.''';

    final userPrompt =
        '''Сгенерируй один интересный квест для охотника.
${hunterLevel != null ? 'Уровень охотника: $hunterLevel' : ''}
${hunterStats != null ? 'Характеристики: $hunterStats' : ''}
${lowestStatsFocus != null && lowestStatsFocus.isNotEmpty ? 'ФОКУС (обязательно учти): $lowestStatsFocus' : ''}

Квест должен быть выполнимым в реальной жизни и мотивирующим. Верни только JSON, без дополнительного текста.''';

    try {
      final response = await sendMessage(
        message: userPrompt,
        systemPrompt: systemPrompt,
        temperature: 0.8,
      );

      // Парсим JSON ответ
      final jsonResponse = jsonDecode(response) as Map<String, dynamic>;
      return jsonResponse;
    } catch (e) {
      // Если не удалось распарсить как JSON, пытаемся извлечь JSON из текста
      final response = await sendMessage(
        message: userPrompt,
        systemPrompt: systemPrompt,
        temperature: 0.8,
      );

      // Пытаемся найти JSON в ответе
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }

      throw Exception('Не удалось сгенерировать квест: $e');
    }
  }

  /// Генерация сообщения от Системы
  static Future<String> generateSystemMessage({
    required String context,
    String? hunterName,
    int? hunterLevel,
    String? philosophyVoiceName,
    String? philosophyToneHint,
    Map<String, String>? philosophyTerms,
  }) async {
    final voice = philosophyVoiceName ?? 'Система';
    final tone = philosophyToneHint ?? 'загадочно, но полезно';
    final terms = philosophyTerms ?? const {};
    final termsBlock = terms.isEmpty
        ? ''
        : '''

Термины активной философии:
- Уровень: ${terms['level'] ?? 'Уровень'}
- Опыт/прогресс: ${terms['experience'] ?? 'Опыт'}
- Валюта: ${terms['currency'] ?? 'Золото'}
- Энергия: ${terms['energy'] ?? 'Энергия'}
- Навыки: ${terms['skills'] ?? 'Навыки'}''';

    final systemPrompt = '''Ты — $voice. Ты общаешься с пользователем, который развивается и выполняет квесты.

Твой стиль общения:
- Тон: $tone
- Будь кратким, но атмосферным
- Отвечай на русском языке$termsBlock''';

    final userPrompt =
        '''${hunterName != null ? 'Охотник: $hunterName' : 'Охотник'}
${hunterLevel != null ? 'Уровень: $hunterLevel' : ''}

Контекст: $context

Ответь в роли: $voice.''';

    return await sendMessage(
      message: userPrompt,
      systemPrompt: systemPrompt,
      temperature: 0.9,
    );
  }

  /// AI-конструктор: генерирует JSON (строго) для кастомной философии/темы.
  ///
  /// Примечание: приложение пока использует терминологию и rules preset,
  /// а цвета/токены (background/primary/surface/glow) будут применены после
  /// расширения ThemeExtension на полные UI-панели.
  static Future<GeneratedSystemThemeJson> generateCustomSystemThemeJson({
    required String systemIdea,
    required String rulesPreset,
    String systemIdValue = 'custom_ai_generated',
    Map<String, String>? exampleTerminology,
  }) async {
    final terminologyExampleBlock = (exampleTerminology == null ||
            exampleTerminology.isEmpty)
        ? ''
        : '''

Пример терминов:
exp: ${exampleTerminology['exp'] ?? ''}
level: ${exampleTerminology['level'] ?? ''}
currency: ${exampleTerminology['currency'] ?? ''}
sp: ${exampleTerminology['sp'] ?? ''}
system: ${exampleTerminology['system'] ?? ''}''';

    final schema = '''
{
  "system_id": "$systemIdValue",
  "theme_name": "string",
  "terminology": {
    "exp": "string",
    "level": "string",
    "currency": "string",
    "sp": "string",
    "system": "string"
  },
  "colors": {
    "background_hex": "#RRGGBB",
    "primary_hex": "#RRGGBB",
    "surface_hex": "#RRGGBB",
    "glow_hex": "#RRGGBB"
  },
  "ai_prompt": "string",
  "rules_preset": "$rulesPreset"
}''';

    final systemPrompt = '''
Ты — генератор игровых систем.
Верни ТОЛЬКО валидный JSON-объект без markdown и без комментариев.
Строго следуй схеме.
Цвета возвращай как HEX строку формата #RRGGBB.

Схема JSON:
$schema''';

    final response = await sendMessage(
      message: '''
Идея системы:
$systemIdea$terminologyExampleBlock

rules_preset: $rulesPreset
system_id: $systemIdValue
''',
      systemPrompt: systemPrompt,
      temperature: 0.6,
    );

    try {
      final decoded = jsonDecode(response);
      if (decoded is Map<String, dynamic>) {
        return GeneratedSystemThemeJson.fromMap(decoded);
      }
      if (decoded is Map) {
        return GeneratedSystemThemeJson.fromMap(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      throw const FormatException('AI JSON is not an object');
    } catch (_) {
      // Если модель добавила мусор, пытаемся вытащить первый объект JSON.
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('Не удалось найти JSON в ответе AI');
      }
      final decoded2 = jsonDecode(jsonMatch.group(0)!);
      if (decoded2 is Map<String, dynamic>) {
        return GeneratedSystemThemeJson.fromMap(decoded2);
      }
      if (decoded2 is Map) {
        return GeneratedSystemThemeJson.fromMap(
          decoded2.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      throw const FormatException('AI JSON is not an object');
    }
  }
}
