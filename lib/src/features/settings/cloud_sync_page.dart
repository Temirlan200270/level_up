import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/systems/system_dictionary.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
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

  void _cloudSnack(
    ScaffoldMessengerState messenger,
    String Function(String, {Map<String, String>? params}) t, {
    required String headlineKey,
    required String masterLineKeyPrefix,
    Object? error,
  }) {
    final systemId = ref.read(activeSystemIdProvider);
    final rules = ref.read(activeSystemRulesProvider);
    final nav = SystemHomeNavLabels.effectiveNavSystemId(systemId, rules);
    final masterKey = '${masterLineKeyPrefix}_${nav.name}';
    final masterLine = t(masterKey);
    final headline = t(headlineKey);
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline),
            const SizedBox(height: 6),
            Text(
              masterLine,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                '${t('cloud_sync_error')}: $error',
                style: GoogleFonts.manrope(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _push(CloudSyncAdapter adapter, String Function(String, {Map<String, String>? params}) t) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await adapter.pushLocal();
      if (mounted) {
        _cloudSnack(
          messenger,
          t,
          headlineKey: 'cloud_sync_success_push',
          masterLineKeyPrefix: 'cloud_sync_master_push_ok',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        _cloudSnack(
          messenger,
          t,
          headlineKey: 'cloud_sync_error',
          masterLineKeyPrefix: 'cloud_sync_master_error',
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pull(CloudSyncAdapter adapter, String Function(String, {Map<String, String>? params}) t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = Theme.of(ctx).colorScheme;
        final cardR = ctx.worldCardRadius;
        return AlertDialog(
          backgroundColor: s.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardR),
          ),
          title: Text(
            t('cloud_sync_pull_confirm'),
            style: GoogleFonts.manrope(
              color: s.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            t('cloud_sync_pull_confirm_body'),
            style: GoogleFonts.manrope(
              color: s.onSurfaceVariant,
              height: 1.35,
            ),
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
        );
      },
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
        _cloudSnack(
          messenger,
          t,
          headlineKey: 'cloud_sync_success_pull',
          masterLineKeyPrefix: 'cloud_sync_master_pull_ok',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        _cloudSnack(
          messenger,
          t,
          headlineKey: 'cloud_sync_error',
          masterLineKeyPrefix: 'cloud_sync_master_error',
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final adapter = ref.watch(cloudSyncAdapterProvider);
    final isConfigured = SupabaseConfig.isConfigured;
    final statusPillLabel = !isConfigured
        ? t('cloud_sync_status_local_only')
        : _user == null
            ? t('cloud_sync_status_need_account')
            : t('cloud_sync_status_ready');
    final visuals = Theme.of(context).extension<SystemVisuals>() ??
        const SystemVisuals(
          backgroundKind: SystemBackgroundKind.grid,
          backgroundAssetPath: '',
          particlesKind: SystemParticlesKind.none,
          panelRadius: 12,
          panelBorderWidth: 1,
          panelBlur: 0,
          titleLetterSpacing: 2.2,
          surfaceKind: SystemSurfaceKind.digital,
          glowIntensity: 0.35,
          borderRadiusScale: 1.0,
          shadowProfile: SystemShadowProfile.soft,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: WorldSurfacePanel(
              visuals: visuals,
              margin: EdgeInsets.zero,
              child: CustomScrollView(
                slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  t('cloud_sync_title'),
                  style: promoAppBarTitleStyle(context),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
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
                                color: scheme.onSurfaceVariant,
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
                                  color: scheme.error,
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
                                  color: scheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                            ] else if (_user == null) ...[
                              Text(
                                t('cloud_sync_need_account'),
                                style: GoogleFonts.manrope(
                                  color: scheme.onSurface,
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
                                style: GoogleFonts.manrope(
                                  color: scheme.outline,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _user!.email ?? _user!.id,
                                style: GoogleFonts.manrope(
                                  color: scheme.primary,
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
        ),
      ),
    );
  }
}

