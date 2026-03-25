import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider_model.dart';

/// Универсальный сервис для работы с различными AI провайдерами
class AIService {
  // Ключи для SharedPreferences
  static const String _prefsProvider = 'ai_provider';
  static const String _prefsModel = 'ai_model';
  static const String _prefsOpenAIKey = 'openai_api_key';
  static const String _prefsGeminiKey = 'gemini_api_key';
  static const String _prefsOpenRouterKey = 'openrouter_api_key';
  static const String _prefsHuggingFaceKey = 'huggingface_api_key';
  static const String _prefsClaudeKey = 'claude_api_key';

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

  /// Получить API ключ для провайдера
  static Future<String?> getApiKey(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
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

  /// Сохранить API ключ для провайдера
  static Future<void> setApiKey(AIProvider provider, String key) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case AIProvider.openai:
        await prefs.setString(_prefsOpenAIKey, key);
        break;
      case AIProvider.gemini:
        await prefs.setString(_prefsGeminiKey, key);
        break;
      case AIProvider.openRouter:
        await prefs.setString(_prefsOpenRouterKey, key);
        break;
      case AIProvider.huggingFace:
        await prefs.setString(_prefsHuggingFaceKey, key);
        break;
      case AIProvider.claude:
        await prefs.setString(_prefsClaudeKey, key);
        break;
    }
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

    switch (currentProvider) {
      case AIProvider.openai:
        return _sendOpenAIMessage(
          message: message,
          systemPrompt: systemPrompt,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.gemini:
        return _sendGeminiMessage(
          message: message,
          systemPrompt: systemPrompt,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.openRouter:
        return _sendOpenRouterMessage(
          message: message,
          systemPrompt: systemPrompt,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.huggingFace:
        return _sendHuggingFaceMessage(
          message: message,
          systemPrompt: systemPrompt,
          model: currentModel,
          apiKey: apiKey,
          temperature: temperature,
        );
      case AIProvider.claude:
        return _sendClaudeMessage(
          message: message,
          systemPrompt: systemPrompt,
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
        'parts': [{'text': systemPrompt}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Понял. Готов к работе.'}],
      });
    }
    
    contents.add({
      'role': 'user',
      'parts': [{'text': message}],
    });

    final response = await http.post(
      Uri.parse(
        '${_apiBaseUrls[AIProvider.gemini]}/models/$model:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
        },
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
        'parameters': {
          'temperature': temperature,
          'return_full_text': false,
        },
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
    messages.add({
      'role': 'user',
      'content': message,
    });

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

  /// Генерация квеста через ИИ
  static Future<Map<String, dynamic>> generateQuest({
    String? hunterLevel,
    String? hunterStats,
  }) async {
    final systemPrompt = '''Ты - Система из манги Solo Leveling. Твоя задача - генерировать интересные квесты для охотника.

Формат ответа должен быть строго в JSON:
{
  "title": "Название квеста",
  "description": "Описание квеста",
  "type": "daily|weekly|special|story",
  "experienceReward": число (10-50),
  "statPointsReward": число (0-5)
}

Квесты должны быть реалистичными и выполнимыми в реальной жизни. Используй стиль Solo Leveling - драматичный, но мотивирующий.''';

    final userPrompt = '''Сгенерируй один интересный квест для охотника.
${hunterLevel != null ? 'Уровень охотника: $hunterLevel' : ''}
${hunterStats != null ? 'Характеристики: $hunterStats' : ''}

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
  }) async {
    final systemPrompt = '''Ты - Система из манги Solo Leveling. Ты общаешься с охотником, который развивается и выполняет квесты.

Твой стиль общения:
- Загадочный и мистический
- Мотивирующий и поддерживающий
- Используй терминологию Solo Leveling (уровни, статы, квесты, опыт)
- Будь кратким, но атмосферным
- Отвечай на русском языке

Отвечай как настоящая Система - загадочно, но полезно.''';

    final userPrompt = '''${hunterName != null ? 'Охотник: $hunterName' : 'Охотник'}
${hunterLevel != null ? 'Уровень: $hunterLevel' : ''}

Контекст: $context

Ответь как Система.''';

    return await sendMessage(
      message: userPrompt,
      systemPrompt: systemPrompt,
      temperature: 0.9,
    );
  }
}

