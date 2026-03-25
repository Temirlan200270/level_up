import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_service.dart';
import 'cloud_sync_adapter.dart';

/// Синхронизация JSON-бэкапа в таблицу `public.game_backups` (Supabase + Auth).
class SupabaseCloudSyncAdapter implements CloudSyncAdapter {
  SupabaseCloudSyncAdapter(this._client);

  final SupabaseClient _client;

  @override
  bool get isConfigured => true;

  @override
  Future<void> pushLocal() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Требуется вход в аккаунт');
    }
    final jsonStr = DatabaseService.exportGameBackupJson();
    final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
    await _client.from('game_backups').upsert({
      'user_id': user.id,
      'payload': payload,
      'schema_version': 1,
      'client_updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> pullRemote() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Требуется вход в аккаунт');
    }
    final row = await _client
        .from('game_backups')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return;
    final raw = row['payload'];
    if (raw == null) return;
    final jsonStr = raw is String ? raw : jsonEncode(raw);
    await DatabaseService.importGameBackupJson(jsonStr);
  }
}
