import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../settings_providers.dart';

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
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup criptografado do NoxPass',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o cofre.')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    const typeGroup = XTypeGroup(label: 'NoxPass backup', extensions: ['backup']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final password = await promptForPassword(
      context,
      title: 'Senha do backup',
      actionLabel: 'Importar',
    );
    if (password == null) return;

    try {
      final count =
          await ref.read(vaultBackupManagerProvider).restore(bytes, password);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$count ${count == 1 ? 'segredo importado' : 'segredos importados'}.',
          ),
        ),
      );
    } on AuthenticationFailure {
      messenger.showSnackBar(
        const SnackBar(content: Text('Senha do backup incorreta.')),
      );
    } on BackupFormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Arquivo de backup inválido.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível importar.')),
      );
    }
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

    final enabled =
        ref.watch(isBiometricEnabledProvider).valueOrNull ?? false;
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
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
