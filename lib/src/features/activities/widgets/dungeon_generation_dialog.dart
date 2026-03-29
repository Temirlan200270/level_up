import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/systems/system_dictionary.dart';
import '../../../core/systems/system_id.dart';
import '../../../core/system_visuals_extension.dart';
import '../../../models/hunter_model.dart';
import '../../../models/dungeon_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/database_service.dart';
import '../../../services/prompts/dungeon_generation_prompts.dart';
import '../../../services/translation_service.dart';

class DungeonGenerationDialog extends StatefulWidget {
  final Hunter hunter;

  const DungeonGenerationDialog({super.key, required this.hunter});

  @override
  State<DungeonGenerationDialog> createState() => _DungeonGenerationDialogState();
}

class _DungeonGenerationDialogState extends State<DungeonGenerationDialog> {
  final _goalController = TextEditingController();
  bool _isGenerating = false;
  int _stagesCount = 3;

  String _t(String key, {Map<String, String>? params}) =>
      TranslationService.translate(key, params: params);

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  static int _intFromJson(dynamic v, {required int fallback}) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  Future<void> _generateDungeon() async {
    final scheme = Theme.of(context).colorScheme;
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('dungeon_gen_goal_required_snack')),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final rules = DungeonGenerationPrompts.resolveActiveSystemRules();
      final systemId = SystemId.fromValue(DatabaseService.getActiveSystemId());
      final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
      final philosophy = DungeonGenerationPrompts.philosophyRoleLabel(nav);
      final tone = DungeonGenerationPrompts.philosophyTone(nav);
      final diffTier = (3 + widget.hunter.level ~/ 8).clamp(1, 10);
      final langCode = DatabaseService.getLanguage();

      final systemPrompt = DungeonGenerationPrompts.systemPrompt(
        stagesCount: _stagesCount,
        difficultyTier: diffTier,
        philosophy: philosophy,
        philosophyToneLine: tone,
        languageCode: langCode,
        hunterLevel: widget.hunter.level,
      );
      final userPrompt = DungeonGenerationPrompts.userPrompt(
        goal: goal,
        hunterLevel: widget.hunter.level,
      );

      final response = await AIService.sendMessage(
        message: userPrompt,
        systemPrompt: systemPrompt,
        temperature: 0.35,
      );

      Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(response);
      } catch (_) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (match != null) {
          jsonMap = jsonDecode(match.group(0)!);
        } else {
          throw const FormatException('Invalid JSON from AI');
        }
      }

      final title =
          jsonMap['title'] as String? ??
          _t('dungeon_gen_fallback_title', params: {'goal': goal});
      final desc =
          jsonMap['description'] as String? ??
          _t('dungeon_gen_fallback_description');

      List<String> sTitles = [];
      List<String> sDescs = [];
      List<int> sDiff = [];
      List<int> sExp = [];
      List<int> sGold = [];

      final stagesRaw = jsonMap['stages'];
      if (stagesRaw is List) {
        for (final item in stagesRaw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final st = m['title']?.toString().trim() ?? '';
          if (st.isEmpty) continue;
          final sd = (m['desc'] ?? m['description'])?.toString().trim() ?? '';
          sTitles.add(st);
          sDescs.add(sd.isNotEmpty ? sd : st);
          sDiff.add(_intFromJson(m['difficulty'], fallback: 3).clamp(1, 10));
          sExp.add(_intFromJson(m['exp'], fallback: 35).clamp(1, 99999));
          sGold.add(_intFromJson(m['gold'], fallback: 25).clamp(1, 99999));
        }
      }

      if (sTitles.length != _stagesCount || sTitles.length != sDescs.length) {
        sTitles =
            (jsonMap['stageTitles'] as List?)?.map((e) => e.toString()).toList() ??
                [];
        sDescs =
            (jsonMap['stageDescriptions'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        sDiff = [];
        sExp = [];
        sGold = [];
      }

      if (sTitles.isEmpty || sTitles.length != sDescs.length) {
        throw Exception(_t('dungeon_gen_ai_bad_stages'));
      }

      if (sTitles.length != _stagesCount) {
        throw Exception(_t('dungeon_gen_ai_bad_stages'));
      }

      final isRedGate = Random().nextDouble() < 0.10;

      final dungeonTitle = isRedGate
          ? _t('dungeon_blood_gate_title_prefix', params: {'title': title})
          : title;
      final dungeonDesc = isRedGate
          ? _t('dungeon_blood_gate_full_desc', params: {'desc': desc})
          : desc;

      final dungeon = Dungeon(
        title: dungeonTitle,
        description: dungeonDesc,
        stageTitles: sTitles,
        stageDescriptions: sDescs,
        stageDifficulties: sDiff.length == _stagesCount ? sDiff : const [],
        stageExpRewards: sExp.length == _stagesCount ? sExp : const [],
        stageGoldRewards: sGold.length == _stagesCount ? sGold : const [],
        isRedGate: isRedGate,
      );

      await DatabaseService.createDungeon(dungeon);

      if (mounted) {
        Navigator.pop(context, true);

        if (isRedGate) {
          final err = Theme.of(context).colorScheme.error;
          final cardR = context.worldCardRadius;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: err.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: err, width: 2),
                borderRadius: BorderRadius.circular(cardR),
              ),
              title: Text(
                _t('dungeon_red_gate_alert_title'),
                style: GoogleFonts.manrope(
                  color: err,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                _t('dungeon_red_gate_alert_body'),
                style: GoogleFonts.manrope(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: err,
                      foregroundColor: Theme.of(ctx).colorScheme.onError,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_t('dungeon_red_gate_accept')),
                  ),
                ),
              ],
            ),
          );
        } else {
          final sec = Theme.of(context).colorScheme.secondary;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t('dungeon_gen_opened_snack', params: {'title': title}),
              ),
              backgroundColor: sec,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        final err = Theme.of(context).colorScheme.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('dungeon_gen_create_error', params: {'error': '$e'}),
            ),
            backgroundColor: err,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardR = context.worldCardRadius;
    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardR),
      ),
      title: Text(
        _t('dungeon_gen_title'),
        style: GoogleFonts.manrope(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: _isGenerating
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: scheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  _t('dungeon_gen_loading'),
                  style: GoogleFonts.manrope(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t('dungeon_gen_goal_help'),
                  style: GoogleFonts.manrope(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    labelText: _t('dungeon_gen_goal_label'),
                    labelStyle: TextStyle(
                      color: scheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t('dungeon_gen_stages_value', params: {
                    'count': '$_stagesCount',
                  }),
                  style: GoogleFonts.manrope(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: _stagesCount.toDouble(),
                  min: 3,
                  max: 7,
                  divisions: 4,
                  activeColor: scheme.secondary,
                  onChanged: (val) {
                    setState(() {
                      _stagesCount = val.toInt();
                    });
                  },
                ),
              ],
            ),
      actions: [
        if (!_isGenerating)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _t('dungeon_gen_cancel'),
              style: TextStyle(color: scheme.outline),
            ),
          ),
        if (!_isGenerating)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
            ),
            onPressed: _generateDungeon,
            child: Text(_t('dungeon_gen_open_gates')),
          ),
      ],
    );
  }
}
