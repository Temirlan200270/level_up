import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/systems/system_id.dart';
import '../../models/hunter_model.dart';
import '../database_service.dart';

/// Минимальная запись публичного профиля для социалки (Фаза 8).
///
/// Важно: тут нет приватных данных, только то, что можно показывать другим игрокам.
class PublicProfilesService {
  const PublicProfilesService(this._client);

  final SupabaseClient _client;

  Future<void> upsertMyProfile({
    required Hunter hunter,
    required SystemId activeSystemId,
    String? hiddenClass,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final handle = DatabaseService.getSocialHandle();
    final displayName = DatabaseService.getSocialDisplayName();
    final avatarUrl = user.userMetadata?['avatar_url']?.toString();

    await _client.from('public_profiles').upsert({
      'user_id': user.id,
      'handle': handle,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'active_system_id': activeSystemId.value,
      'level': hunter.level,
      'hidden_class': (hiddenClass ?? hunter.hiddenClassId ?? '').trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

