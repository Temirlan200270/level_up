import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/database_service.dart';
import '../../models/dungeon_model.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dungeons = DatabaseService.getDungeons();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Активности',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SoloLevelingColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (dungeons.isEmpty)
                  ProfileNeonCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Подземелий пока нет',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Подземелье — это цепочка этапов. Спавнится только текущий этап; провал — вылет.',
                          style: GoogleFonts.manrope(
                            color: SoloLevelingColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () async {
                            await DatabaseService.createDungeon(
                              Dungeon(
                                title: 'Неделя без сахара',
                                description:
                                    '7 этапов, один за другим. Провал — вылет из данжа.',
                                stageTitles: const [
                                  'День 1: без сладкого',
                                  'День 2: без сладкого',
                                  'День 3: без сладкого',
                                  'День 4: без сладкого',
                                  'День 5: без сладкого',
                                  'День 6: без сладкого',
                                  'День 7: финал',
                                ],
                                stageDescriptions: const [
                                  'Проживи день без сладостей/сахара. Если сорвался — провал.',
                                  'Держим линию. Замени сладкое фруктами/чаем.',
                                  'Стабилизация. Отследи тягу и триггеры.',
                                  'Дисциплина. Не покупай сладкое вообще.',
                                  'Выносливость. Сон и вода — твои союзники.',
                                  'Контроль. Пройди день без “чуть-чуть”.',
                                  'Финальный рывок. Закрепи победу.',
                                ],
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Демо-данж создан')),
                              );
                            }
                          },
                          child: const Text('Создать демо-данж'),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: dungeons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final d = dungeons[i];
                        final status = switch (d.status) {
                          DungeonStatus.active => 'Активно',
                          DungeonStatus.completed => 'Завершено',
                          DungeonStatus.failed => 'Провалено',
                        };
                        return ProfileNeonCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      d.title,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w800,
                                        color: SoloLevelingColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  ProfilePillBadge(label: status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d.description,
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textSecondary,
                                  height: 1.35,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Прогресс: ${d.currentStageIndex}/${d.totalStages}',
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

