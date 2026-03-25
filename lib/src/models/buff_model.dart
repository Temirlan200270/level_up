// Модель для активных временных эффектов (баффов)
class Buff {
  final String effectId; // Например, 'xp_multiplier'
  final dynamic value; // Значение, например, 2.0
  final DateTime expiresAt; // Время окончания действия

  Buff({required this.effectId, required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'effectId': effectId,
      'value': value,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory Buff.fromMap(Map<String, dynamic> map) {
    return Buff(
      effectId: map['effectId'],
      value: map['value'],
      expiresAt: DateTime.parse(map['expiresAt']),
    );
  }
}
