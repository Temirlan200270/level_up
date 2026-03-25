import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/promo_ui.dart';
import '../../../core/theme.dart';
import '../../../services/cloud_sync/cloud_sync_adapter.dart';
import '../../../services/providers.dart';
import '../../../services/supabase/supabase_config.dart';

/// Диалог: объяснение, вход (email/пароль), выгрузка/восстановление бэкапа.
class CloudSyncDialog extends ConsumerStatefulWidget {
  const CloudSyncDialog({super.key, required this.t});

  final String Function(String) t;

  @override
  ConsumerState<CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends ConsumerState<CloudSyncDialog> {
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
        if (mounted) {
          setState(() => _user = data.session?.user);
        }
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

  Future<void> _push(CloudSyncAdapter adapter) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _busy = true;
        _errorText = null;
      });
      await adapter.pushLocal();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(widget.t('cloud_sync_success_push'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        messenger.showSnackBar(
          SnackBar(content: Text('${widget.t('cloud_sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pull(CloudSyncAdapter adapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoloLevelingColors.surface,
        title: Text(
          widget.t('cloud_sync_pull_confirm'),
          style: const TextStyle(color: SoloLevelingColors.textPrimary),
        ),
        content: Text(
          widget.t('cloud_sync_pull_confirm_body'),
          style: const TextStyle(color: SoloLevelingColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.t('cloud_sync_pull')),
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
          SnackBar(content: Text(widget.t('cloud_sync_success_pull'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        messenger.showSnackBar(
          SnackBar(content: Text('${widget.t('cloud_sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
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
          SnackBar(content: Text('${widget.t('cloud_sync_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
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
          SnackBar(content: Text('${widget.t('cloud_sync_error')}: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _signUp() async {
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
                  ? widget.t('cloud_sync_sign_up_hint')
                  : widget.t('cloud_sync_sign_up_done'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = '$e');
        messenger.showSnackBar(
          SnackBar(content: Text('${widget.t('cloud_sync_error')}: $e')),
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
    final t = widget.t;
    final adapter = ref.watch(cloudSyncAdapterProvider);
    final authEnabled = _user == null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight * 0.9;
          return SafeArea(
            child: ProfileNeonCard(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                SoloLevelingColors.neonBlue,
                                SoloLevelingColors.neonPurple,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t('cloud_sync_title'),
                            style: GoogleFonts.manrope(
                              color: SoloLevelingColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: t('close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_errorText != null) ...[
                      Text(
                        _errorText!,
                        style: GoogleFonts.manrope(
                          color: SoloLevelingColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: !SupabaseConfig.isConfigured
                            ? Text(
                                t('cloud_sync_need_dart_define'),
                                style: GoogleFonts.manrope(
                                  color: SoloLevelingColors.textSecondary,
                                  height: 1.45,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t('cloud_sync_body_short'),
                                    style: GoogleFonts.manrope(
                                      color: SoloLevelingColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_user != null) ...[
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
                                      onPressed:
                                          _busy ? null : () => _push(adapter),
                                      icon: const Icon(
                                          Icons.cloud_upload_outlined),
                                      label: Text(t('cloud_sync_push')),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed:
                                          _busy ? null : () => _pull(adapter),
                                      icon: const Icon(
                                          Icons.cloud_download_outlined),
                                      label: Text(t('cloud_sync_pull')),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _busy ? null : _signOut,
                                      child: Text(t('cloud_sync_sign_out')),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.manrope(
                                      color: SoloLevelingColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: promoInputDecoration(
                                      labelText: t('cloud_sync_email'),
                                    ),
                                    enabled: !_busy && authEnabled,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _password,
                                    obscureText: true,
                                    style: GoogleFonts.manrope(
                                      color: SoloLevelingColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: promoInputDecoration(
                                      labelText: t('cloud_sync_password'),
                                    ),
                                    enabled: !_busy && authEnabled,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _busy || !authEnabled
                                        ? null
                                        : _signIn,
                                    child: _busy
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(t('cloud_sync_sign_in')),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: _busy || !authEnabled
                                        ? null
                                        : _signInWithGoogle,
                                    icon: const Icon(Icons.g_translate_rounded),
                                    label: Text(t('cloud_sync_sign_in_google')),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: _busy || !authEnabled
                                        ? null
                                        : _signUp,
                                    child: Text(t('cloud_sync_sign_up')),
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
        },
      ),
    );
  }
}
