import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/promo_ui.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/cloud_sync/cloud_sync_adapter.dart';
import '../../services/providers.dart';
import '../../services/supabase/supabase_config.dart';
import 'account_page.dart';

class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  StreamSubscription<AuthState>? _authSub;
  User? _user;
  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isConfigured) {
      final client = Supabase.instance.client;
      _user = client.auth.currentUser;
      _authSub = client.auth.onAuthStateChange.listen((data) {
        if (mounted) setState(() => _user = data.session?.user);
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _push(CloudSyncAdapter adapter, String Function(String) t) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await adapter.pushLocal();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(t('cloud_sync_success_push'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        messenger.showSnackBar(
          SnackBar(content: Text('${t('cloud_sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pull(CloudSyncAdapter adapter, String Function(String) t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          t('cloud_sync_pull_confirm'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: Text(
          t('cloud_sync_pull_confirm_body'),
          style: const TextStyle(color: SoloLevelingColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('cloud_sync_pull')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await adapter.pullRemote();
      ref.read(hunterProvider.notifier).reloadFromLocalDb();
      ref.read(questsProvider.notifier).reloadFromLocalDb();
      ref.read(themeSkinIdProvider.notifier).reloadFromDb();
      ref.read(settingsMetaRefreshProvider.notifier).state++;
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(t('cloud_sync_success_pull'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        messenger.showSnackBar(
          SnackBar(content: Text('${t('cloud_sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final adapter = ref.watch(cloudSyncAdapterProvider);
    final isConfigured = SupabaseConfig.isConfigured;
    final statusPillLabel = !isConfigured
        ? t('cloud_sync_status_local_only')
        : _user == null
            ? t('cloud_sync_status_need_account')
            : t('cloud_sync_status_ready');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(t('cloud_sync_title'), style: promoAppBarTitleStyle()),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileNeonCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t('cloud_sync_body_short'),
                              style: GoogleFonts.manrope(
                                color: SoloLevelingColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ProfilePillBadge(label: statusPillLabel),
                            const SizedBox(height: 12),
                            if (_errorText != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorText!,
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (!isConfigured) ...[
                              Text(
                                t('cloud_sync_need_dart_define'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.warning,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                            ] else if (_user == null) ...[
                              Text(
                                t('cloud_sync_need_account'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const AccountPage(),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.login_rounded),
                                label: Text(t('cloud_sync_go_to_account')),
                              ),
                            ] else ...[
                              Text(
                                t('cloud_sync_signed_in_as'),
                                style: const TextStyle(
                                  color: SoloLevelingColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _user!.email ?? _user!.id,
                                style: const TextStyle(
                                  color: SoloLevelingColors.neonBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _busy ? null : () => _push(adapter, t),
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: Text(t('cloud_sync_push')),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : () => _pull(adapter, t),
                                icon: const Icon(Icons.cloud_download_outlined),
                                label: Text(t('cloud_sync_pull')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

