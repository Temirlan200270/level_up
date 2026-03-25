import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/systems/system_config.dart';
import '../../services/ai_service.dart';
import '../../services/supabase/supabase_config.dart';
import 'onboarding_models.dart';

class OnboardingAiService {
  const OnboardingAiService();

  Future<OnboardingAiResult> initPersona({
    required SystemConfig system,
    required OnboardingPersona persona,
  }) async {
    // 1) Edge Function (если Supabase настроен и пользователь вошёл)
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final res = await Supabase.instance.client.functions.invoke(
            'onboarding_init',
            body: {
              'system_id': system.id.value,
              'ai_voice_name': system.aiVoiceName,
              'ai_tone_hint': system.aiToneHint,
              'terms': {
                'level': system.dictionary.levelName,
                'experience': system.dictionary.experienceName,
                'currency': system.dictionary.currencyName,
                'energy': system.dictionary.energyName,
                'skills': system.dictionary.skillsName,
              },
              'persona': persona.toMap(),
            },
          );
          final parsed = _parseJsonResult(res.data);
          if (parsed != null) return parsed;
        } catch (_) {
          // fallthrough
        }
      }
    }

    // 2) Локальный AIService (если есть ключ) — строгий JSON.
    try {
      if (await AIService.hasApiKey()) {
        final message = _buildUserMessage(system: system, persona: persona);
        final raw = await AIService.sendMessage(
          message: message,
          systemPrompt: _buildSystemPrompt(system: system),
          temperature: 0.35,
        );
        final parsed = _parseJsonResult(raw);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // ignore
    }

    // 3) Fallback: без ИИ — детерминированные первые квесты.
    return _fallback(system: system, persona: persona);
  }

  String _buildSystemPrompt({required SystemConfig system}) {
    return '''
Ты — Мастер/Наставник мира "${system.aiVoiceName}". Тон: ${system.aiToneHint}.
Твоя задача — инициировать игрока и дать ему стартовую цепочку побед.

Верни ответ СТРОГО JSON (без пояснений и без markdown), по схеме:
{
  "hidden_class": "string",
  "hidden_class_reason": "string",
  "quests": [
    {
      "title": "string",
      "description": "string",
      "tags": ["string"],
      "difficulty": 1-5,
      "exp": int,
      "gold": int,
      "stat_points": int,
      "mandatory": true/false
    }
  ]
}

Правила:
- quests: 3..5 штук
- теги только латиницей/подчёркивания (например: code, sport, focus, health, study)
- difficulty: 1..5
- Тексты на русском.
''';
  }

  String _buildUserMessage({
    required SystemConfig system,
    required OnboardingPersona persona,
  }) {
    final i = persona.interests.join(', ');
    return '''
Игрок описал себя так:
- Кто он: ${persona.selfRole}
- Интересы: $i
- Цель: ${persona.goal}

Сгенерируй hidden_class и стартовые квесты. Термины мира:
уровень="${system.dictionary.levelName}", опыт="${system.dictionary.experienceName}", валюта="${system.dictionary.currencyName}".
''';
  }

  OnboardingAiResult? _parseJsonResult(dynamic raw) {
    if (raw == null) return null;
    final text = raw is String ? raw : jsonEncode(raw);
    final obj = _extractJsonObject(text);
    if (obj == null) return null;
    try {
      final m = jsonDecode(obj) as Map<String, dynamic>;
      final hidden = (m['hidden_class'] as String?)?.trim() ?? '';
      final reason = (m['hidden_class_reason'] as String?)?.trim() ?? '';
      final questsRaw = m['quests'];
      if (hidden.isEmpty || questsRaw is! List) return null;
      final quests = <OnboardingQuestSeed>[];
      for (final q in questsRaw) {
        if (q is Map) {
          final seed = OnboardingQuestSeed.fromMap(Map<String, dynamic>.from(q));
          if (seed.title.trim().isNotEmpty) quests.add(seed);
        }
      }
      if (quests.length < 3) return null;
      return OnboardingAiResult(
        hiddenClass: hidden,
        hiddenClassReason: reason,
        quests: quests.take(5).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  String? _extractJsonObject(String s) {
    final start = s.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inStr = false;
    var esc = false;
    for (var i = start; i < s.length; i++) {
      final ch = s[i];
      if (inStr) {
        if (esc) {
          esc = false;
          continue;
        }
        if (ch == '\\') {
          esc = true;
          continue;
        }
        if (ch == '"') inStr = false;
        continue;
      }
      if (ch == '"') {
        inStr = true;
        continue;
      }
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          return s.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  OnboardingAiResult _fallback({
    required SystemConfig system,
    required OnboardingPersona persona,
  }) {
    final interests = persona.interests.map((e) => e.toLowerCase()).toSet();
    final isCoder = interests.contains('code') || persona.goal.toLowerCase().contains('код');
    final hidden = isCoder ? 'Теневой Архитектор' : 'Искатель Ритуалов';
    final reason = isCoder
        ? 'Твоя цель и интересы указывают на склонность к системному мышлению и дисциплине.'
        : 'В твоих словах есть стремление к ритуалам и устойчивым практикам.';

    final baseTags = <String>[
      if (isCoder) 'code' else 'focus',
      'discipline',
      ...interests.take(2),
    ].where((e) => e.trim().isNotEmpty).toSet().toList();

    final quests = <OnboardingQuestSeed>[
      OnboardingQuestSeed(
        title: 'Инициация: Первый шаг',
        description: 'Сделай 10 минут того, что напрямую приближает к цели: ${persona.goal}.',
        tags: [...baseTags, 'onboarding'],
        difficulty: 2,
        exp: 25,
        gold: 12,
        statPoints: 1,
        mandatory: true,
      ),
      OnboardingQuestSeed(
        title: 'Ритуал фокуса',
        description: '25 минут без отвлечений: один таймер, одна задача. В конце — короткая фиксация результата.',
        tags: [...baseTags, 'focus'],
        difficulty: 3,
        exp: 35,
        gold: 16,
        statPoints: 0,
        mandatory: false,
      ),
      OnboardingQuestSeed(
        title: 'Закрепление основы',
        description: 'Сделай одно простое действие для тела: прогулка 10 минут или растяжка 5 минут.',
        tags: [...baseTags, 'health'],
        difficulty: 1,
        exp: 18,
        gold: 8,
        statPoints: 0,
        mandatory: false,
      ),
    ];

    // Немного вариативности.
    if (kDebugMode) {
      quests.add(
        OnboardingQuestSeed(
          title: 'Печать намерения',
          description: 'Запиши 3 причины, почему ты хочешь пройти этот путь. Сохрани как обещание самому себе.',
          tags: [...baseTags, 'mind'],
          difficulty: 2,
          exp: 22,
          gold: 10,
          statPoints: 0,
          mandatory: false,
        ),
      );
    }

    return OnboardingAiResult(hiddenClass: hidden, hiddenClassReason: reason, quests: quests.take(5).toList());
  }
}

