/// Отображение ранга E–S от уровня (прогрессия в стиле манхвы).
String hunterRankCode(int level) {
  if (level >= 71) return 'S';
  if (level >= 51) return 'A';
  if (level >= 36) return 'B';
  if (level >= 26) return 'C';
  if (level >= 11) return 'D';
  return 'E';
}

/// Ключ локализации титула по рангу: hunter_title_rank_e … hunter_title_rank_s
String hunterTitleKeyForRank(String rankLetter) {
  return 'hunter_title_rank_${rankLetter.toLowerCase()}';
}
