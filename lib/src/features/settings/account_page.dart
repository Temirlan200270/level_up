import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/promo_ui.dart';
import '../../core/system_visuals_extension.dart';
import '../../core/translations.dart';
import '../../core/widgets/world_surface_panel.dart';
import '../../services/supabase/supabase_config.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn(String Function(String) t) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
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

  Future<void> _signInWithGoogle(String Function(String) t) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
      );
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

  Future<void> _signUp(String Function(String) t) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              res.session == null
                  ? t('cloud_sync_sign_up_hint')
                  : t('cloud_sync_sign_up_done'),
            ),
          ),
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

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final t = useTranslations(ref);
    final scheme = Theme.of(context).colorScheme;
    final authEnabled = _user == null;
    final statusPillLabel = !SupabaseConfig.isConfigured
        ? t('account_status_local_only')
        : _user == null
            ? t('account_status_need_sign_in')
            : t('account_status_active');
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
                  t('account_title'),
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
                              t('account_title'),
                              style: GoogleFonts.manrope(
                                color: scheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ProfilePillBadge(label: statusPillLabel),
                            const SizedBox(height: 12),
                            Text(
                              t('account_body'),
                              style: GoogleFonts.manrope(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            if (!SupabaseConfig.isConfigured) ...[
                              const SizedBox(height: 12),
                              Text(
                                t('cloud_sync_need_dart_define'),
                                style: GoogleFonts.manrope(
                                  color: scheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                            ],
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
                            if (_user != null) ...[
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
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _busy ? null : _signOut,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(t('cloud_sync_sign_out')),
                              ),
                            ] else ...[
                              TextField(
                                controller: _email,
                                enabled:
                                    !_busy && authEnabled && SupabaseConfig.isConfigured,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.manrope(
                                  color: scheme.onSurface,
                                  fontSize: 15,
                                ),
                                decoration: promoInputDecoration(
                                  labelText: t('cloud_sync_email'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _password,
                                enabled:
                                    !_busy && authEnabled && SupabaseConfig.isConfigured,
                                obscureText: true,
                                style: GoogleFonts.manrope(
                                  color: scheme.onSurface,
                                  fontSize: 15,
                                ),
                                decoration: promoInputDecoration(
                                  labelText: t('cloud_sync_password'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _busy || !authEnabled || !SupabaseConfig.isConfigured
                                    ? null
                                    : () => _signIn(t),
                                icon: _busy
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(t('cloud_sync_sign_in')),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _busy || !authEnabled || !SupabaseConfig.isConfigured
                                    ? null
                                    : () => _signInWithGoogle(t),
                                icon: const Icon(Icons.g_translate_rounded),
                                label: Text(t('cloud_sync_sign_in_google')),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _busy || !authEnabled || !SupabaseConfig.isConfigured
                                    ? null
                                    : () => _signUp(t),
                                icon: const Icon(Icons.app_registration_rounded),
                                label: Text(t('cloud_sync_sign_up')),
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

