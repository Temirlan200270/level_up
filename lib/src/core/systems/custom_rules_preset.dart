enum CustomRulesPreset {
  balanced('balanced'),
  solo('solo'),
  mage('mage'),
  cultivator('cultivator');

  const CustomRulesPreset(this.value);
  final String value;

  static CustomRulesPreset fromValue(String raw) {
    for (final v in CustomRulesPreset.values) {
      if (v.value == raw) return v;
    }
    return CustomRulesPreset.balanced;
  }
}

