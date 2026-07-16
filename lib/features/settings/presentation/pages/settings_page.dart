import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/crypto/crypto_failure.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/noxpass_logo.dart';
import '../../../../shared/widgets/password_prompt.dart';
import '../../../authentication/data/auth_data_providers.dart';
import '../../../authentication/presentation/auth_controller.dart';
import '../../../authentication/presentation/widgets/change_master_password_dialog.dart';
import '../../../backup/data/backup_providers.dart';
import '../../../backup/domain/backup_service.dart';
import '../../../backup/domain/restore_plan.dart';
import '../../../backup/presentation/restore_preview_page.dart';
import '../../../sync/data/sync_providers.dart';
import '../../../sync/domain/drive_backup_manager.dart';
import '../settings_providers.dart';

/// Decifra os bytes, monta a prévia do restore, abre a tela de revisão e
/// aplica a escolha do usuário. Compartilhado pelo arquivo e pelo Drive.
Future<void> _runRestore(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes,
  String password,
  String source,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final plan = await ref
        .read(vaultBackupManagerProvider)
        .planRestore(bytes, password);
    if (plan.items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('O backup não tem itens.')),
      );
      return;
    }
    final summary = await navigator.push<RestoreSummary>(
      MaterialPageRoute(
        builder: (_) => RestorePreviewPage(plan: plan, source: source),
      ),
    );
    if (summary == null) return;
    final parts = <String>[
      if (summary.added > 0) '${summary.added} adicionados',
      if (summary.replaced > 0) '${summary.replaced} substituídos',
      if (summary.skipped > 0) '${summary.skipped} ignorados',
    ];
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          parts.isEmpty ? 'Nada aplicado.' : '${parts.join(', ')}.',
        ),
      ),
    );
  } on AuthenticationFailure {
    messenger.showSnackBar(
      const SnackBar(content: Text('Senha do backup incorreta.')),
    );
  } on BackupFormatException {
    messenger.showSnackBar(const SnackBar(content: Text('Backup inválido.')));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível restaurar.')),
    );
  }
}

/// Ajustes: segurança, backup e informações do app.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('Aparência'),
          const _ThemeModeTile(),
          const Divider(),
          const _SectionHeader('Segurança'),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Relatório de segurança'),
            subtitle: const Text('Senhas fracas e reutilizadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.securityPath),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Alterar senha mestra'),
            subtitle: const Text('Troca a senha sem recifrar o cofre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final changed = await showChangeMasterPasswordDialog(context);
              if (changed == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha mestra alterada.')),
                );
              }
            },
          ),
          const _PinTile(),
          const _BiometricTile(),
          _AutoLockTile(
            value: ref.watch(autoLockTimeoutProvider),
            onChanged: (duration) =>
                ref.read(autoLockTimeoutProvider.notifier).state = duration,
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Categorias'),
            subtitle: const Text('Criar, renomear e excluir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.categoriesPath),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Lixeira'),
            subtitle: const Text('Itens excluídos (30 dias)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.trashPath),
          ),
          const Divider(),
          const _SectionHeader('Backup'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar cofre'),
            subtitle: const Text('Arquivo .backup criptografado'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importar backup'),
            subtitle: const Text('Restaurar de um arquivo .backup'),
            onTap: () => _import(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Sincronização'),
          const _DriveSyncSection(),
          const Divider(),
          const _SectionHeader('Sobre'),
          const AboutListTile(
            icon: NoxPassShield(size: 32),
            applicationName: 'NoxPass',
            applicationVersion: 'Versão 1.0.0',
            applicationIcon: NoxPassShield(size: 56),
            applicationLegalese: 'Desenvolvido por Wesley Ruan',
            aboutBoxChildren: [
              SizedBox(height: 12),
              Text('Sua privacidade. Seu controle. Suas senhas.'),
            ],
            child: Text('Sobre o NoxPass'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    // Captura o messenger antes de qualquer await para não usar context depois.
    final messenger = ScaffoldMessenger.of(context);
    final password = await promptForPassword(
      context,
      title: 'Senha do backup',
      message: 'Protege este arquivo. Guarde-a bem — não é a senha mestra.',
      requireConfirm: true,
      actionLabel: 'Exportar',
    );
    if (password == null) return;

    try {
      final bytes = await ref.read(vaultBackupManagerProvider).create(password);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final file = File(p.join(dir.path, 'noxpass-$stamp.backup'));
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Backup criptografado do NoxPass');
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o cofre.')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    const typeGroup = XTypeGroup(
      label: 'NoxPass backup',
      extensions: ['backup'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final password = await promptForPassword(
      context,
      title: 'Senha do backup',
      actionLabel: 'Continuar',
    );
    if (password == null || !context.mounted) return;

    await _runRestore(context, ref, bytes, password, 'arquivo');
  }
}

/// Seção "Sincronização": conecta a conta Google e envia/restaura o cofre
/// cifrado na pasta privada do app no Drive do usuário.
class _DriveSyncSection extends ConsumerStatefulWidget {
  const _DriveSyncSection();

  @override
  ConsumerState<_DriveSyncSection> createState() => _DriveSyncSectionState();
}

class _DriveSyncSectionState extends ConsumerState<_DriveSyncSection> {
  String? _email;
  DateTime? _lastChange;
  bool _busy = false;

  DriveBackupManager get _manager => ref.read(driveBackupManagerProvider);

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final email = await _manager.restoreSession();
      if (!mounted) return;
      setState(() => _email = email);
      if (email != null) await _refreshLastChange();
    } catch (_) {
      // Sem sessão anterior ou sem rede: segue desconectado, sem alarde.
    }
  }

  Future<void> _refreshLastChange() async {
    try {
      final when = await _manager.lastRemoteChange();
      if (mounted) setState(() => _lastChange = when);
    } catch (_) {
      /* silencioso — é só um enfeite informativo */
    }
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final email = await _manager.connect();
      if (!mounted) return;
      setState(() => _email = email);
      await _refreshLastChange();
    } on GoogleSignInException catch (e) {
      // Cancelamento pelo usuário não é erro.
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        _snack('Não foi possível conectar ao Google Drive.');
      }
    } catch (_) {
      if (mounted) _snack('Não foi possível conectar ao Google Drive.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    await _manager.disconnect();
    if (mounted) {
      setState(() {
        _email = null;
        _lastChange = null;
      });
    }
  }

  Future<void> _backup() async {
    final password = await promptForPassword(
      context,
      title: 'Senha do backup',
      message: 'Protege o cofre no Drive. Guarde-a bem — não é a senha mestra.',
      requireConfirm: true,
      actionLabel: 'Enviar',
    );
    if (password == null) return;
    setState(() => _busy = true);
    try {
      await _manager.backupToDrive(password);
      await _refreshLastChange();
      if (mounted) _snack('Cofre enviado para o Google Drive.');
    } catch (_) {
      if (mounted) _snack('Não foi possível enviar o cofre.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final password = await promptForPassword(
      context,
      title: 'Senha do backup',
      actionLabel: 'Continuar',
    );
    if (password == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _manager.downloadBytes();
      if (!mounted) return;
      await _runRestore(context, ref, bytes, password, 'Google Drive');
    } on NoRemoteBackup {
      if (mounted) _snack('Nenhum backup encontrado no Drive.');
    } catch (_) {
      if (mounted) _snack('Não foi possível restaurar do Drive.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_email == null) {
      return ListTile(
        leading: const Icon(Icons.cloud_outlined),
        title: const Text('Conectar Google Drive'),
        subtitle: const Text('Backup cifrado na sua conta'),
        trailing: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _busy ? null : _connect,
      );
    }

    final subtitle = _lastChange == null
        ? _email!
        : '${_email!}\nÚltimo envio: ${DateFormat('dd/MM/yyyy HH:mm').format(_lastChange!.toLocal())}';

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_done_outlined),
          isThreeLine: _lastChange != null,
          title: const Text('Google Drive conectado'),
          subtitle: Text(subtitle),
          trailing: TextButton(
            onPressed: _busy ? null : _disconnect,
            child: const Text('Desconectar'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Enviar cofre para o Drive'),
          subtitle: const Text('Sobrescreve o backup na nuvem'),
          enabled: !_busy,
          onTap: _backup,
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Restaurar do Drive'),
          subtitle: const Text('Baixa e recria os segredos'),
          enabled: !_busy,
          onTap: _restore,
        ),
      ],
    );
  }
}

class _PinTile extends ConsumerWidget {
  const _PinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(isPinEnabledProvider).valueOrNull ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.pin_outlined),
      title: const Text('Desbloqueio por PIN'),
      subtitle: const Text('Abrir o cofre com um PIN'),
      value: enabled,
      onChanged: (value) async {
        final auth = ref.read(authControllerProvider.notifier);
        if (value) {
          final pin = await promptForPassword(
            context,
            title: 'Criar PIN',
            fieldLabel: 'PIN',
            actionLabel: 'Salvar',
            requireConfirm: true,
            minLength: 4,
            keyboardType: TextInputType.number,
          );
          if (pin != null) await auth.enrollPin(pin);
        } else {
          await auth.disablePin();
        }
      },
    );
  }
}

class _BiometricTile extends ConsumerWidget {
  const _BiometricTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available =
        ref.watch(isBiometricAvailableProvider).valueOrNull ?? false;
    if (!available) return const SizedBox.shrink();

    final enabled = ref.watch(isBiometricEnabledProvider).valueOrNull ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Desbloqueio por biometria'),
      subtitle: const Text('Abrir com digital ou rosto'),
      value: enabled,
      onChanged: (value) async {
        final auth = ref.read(authControllerProvider.notifier);
        if (value) {
          await auth.enrollBiometric();
        } else {
          await auth.disableBiometric();
        }
      },
    );
  }
}

class _AutoLockTile extends StatelessWidget {
  const _AutoLockTile({required this.value, required this.onChanged});

  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Bloqueio automático'),
      subtitle: const Text('Travar o cofre por inatividade'),
      trailing: DropdownButton<Duration>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final entry in kAutoLockOptions.entries)
            DropdownMenuItem(value: entry.value, child: Text(entry.key)),
        ],
        onChanged: (d) => d == null ? null : onChanged(d),
      ),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistema'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Claro'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Escuro'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              ref.read(themeModeProvider.notifier).set(selection.first),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
