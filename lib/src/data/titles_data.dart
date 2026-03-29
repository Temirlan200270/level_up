import '../models/title_def.dart';

const List<TitleDef> allTitles = [
  TitleDef(
    id: 'title_novice_hunter',
    name: 'Начинающий Охотник',
    description: 'Сделал первый шаг в мир Системы.',
    rarity: 'common',
    effects: {'xp_bonus': 0.05}, // +5% к получаемому опыту
  ),
  TitleDef(
    id: 'title_relentless',
    name: 'Неутомимый',
    description: 'Выполнил 7 ежедневных квестов подряд.',
    rarity: 'rare',
    effects: {'stat_vitality': 2}, // +2 к Живучести
  ),
  TitleDef(
    id: 'title_survivor',
    name: 'Выживший',
    description: 'Преодолел Штрафную Зону.',
    rarity: 'epic',
    effects: {'stat_strength': 3, 'stat_agility': 3}, // +3 к Силе и Ловкости
  ),
  TitleDef(
    id: 'title_system_favorite',
    name: 'Любимец Системы',
    description: 'Тот, за кем наблюдает нечто большее.',
    rarity: 'legendary',
    effects: {'xp_bonus': 0.15, 'stat_intelligence': 5}, 
    isHidden: true,
  ),
  // Добавьте больше титулов по мере необходимости
];

TitleDef? getTitleById(String id) {
  try {
    return allTitles.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}
