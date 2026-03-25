enum SystemId {
  solo('solo'),
  mage('mage'),
  cultivator('cultivator'),
  custom('custom');

  const SystemId(this.value);
  final String value;

  static SystemId fromValue(String raw) {
    if (raw.startsWith('custom_')) {
      return SystemId.custom;
    }
    for (final v in SystemId.values) {
      if (v.value == raw) return v;
    }
    return SystemId.solo;
  }

  static String? extractCustomSlug(String raw) {
    if (!raw.startsWith('custom_')) return null;
    final slug = raw.substring('custom_'.length);
    if (slug.trim().isEmpty) return null;
    return slug;
  }
}

