import '../core/systems/system_id.dart';

class PublicProfile {
  const PublicProfile({
    required this.handle,
    required this.displayName,
    required this.discriminator4,
    required this.activeSystemId,
    required this.level,
    required this.rank,
  });

  final String handle; // Nick#1234
  final String displayName;
  final String discriminator4;
  final SystemId activeSystemId;
  final int level;
  final String rank;

  PublicProfile copyWith({
    String? handle,
    String? displayName,
    String? discriminator4,
    SystemId? activeSystemId,
    int? level,
    String? rank,
  }) {
    return PublicProfile(
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      discriminator4: discriminator4 ?? this.discriminator4,
      activeSystemId: activeSystemId ?? this.activeSystemId,
      level: level ?? this.level,
      rank: rank ?? this.rank,
    );
  }
}

