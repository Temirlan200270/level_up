import 'package:flutter/material.dart';

enum SystemId {
  solo('solo'),
  mage('mage'),
  cultivator('cultivator'),
  custom('custom');

  const SystemId(this.value);
  final String value;

  IconData get icon {
    switch (this) {
      case SystemId.solo:
        return Icons.person_rounded;
      case SystemId.mage:
        return Icons.auto_awesome_rounded;
      case SystemId.cultivator:
        return Icons.spa_rounded;
      case SystemId.custom:
        return Icons.dashboard_customize_rounded;
    }
  }

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

