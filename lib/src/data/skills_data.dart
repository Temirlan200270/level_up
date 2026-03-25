import '../models/enums.dart';
import '../models/skill_model.dart';

// Базовые навыки, соответствующие плану разработки и концепции "Трех Путей"
final List<Skill> initialSkills = [
  // === НАВЫКИ УБИЙЦЫ (ASSASSIN) ===
  Skill(
    id: 'skill_sprint',
    name: 'Спринт',
    description: 'Заверши задачу за 30 мин и получи x2 награду.',
    branch: 'assassin',
    tier: 1,
    cost: 1,
    type: SkillType.active,
    cooldownSeconds: 86400, // 24 часа
    durationSeconds: 1800, // 30 минут
  ),
  Skill(
    id: 'crit_hit',
    name: 'Крит. Удар',
    description: 'Шанс получить x2 опыта.',
    branch: 'assassin',
    tier: 2,
    cost: 2,
    type: SkillType.passive,
    parentId: 'skill_sprint',
  ),
  Skill(
    id: 'skill_stealth',
    name: 'Скрытность',
    description: 'Снижает штраф за провал задачи на 20%.',
    branch: 'assassin',
    tier: 1,
    cost: 1,
    type: SkillType.passive,
  ),

  // === НАВЫКИ МАГА (MAGE) ===
  Skill(
    id: 'focus',
    name: 'Медитация',
    description: 'Режим фокуса. Фарм золота за время.',
    branch: 'mage',
    tier: 1,
    cost: 1,
    type: SkillType.active,
    cooldownSeconds: 3600, // 1 час
    durationSeconds: 1800, // 30 минут
  ),
];
