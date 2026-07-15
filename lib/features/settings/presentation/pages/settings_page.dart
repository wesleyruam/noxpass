import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/password_prompt.dart';
import '../../../backup/data/backup_providers.dart';

/// Ajustes: segurança, backup e informações do app.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('Segurança'),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Relatório de segurança'),
            subtitle: const Text('Senhas fracas e reutilizadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.securityPath),
          ),
          const Divider(),
          const _SectionHeader('Backup'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar cofre'),
            subtitle: const Text('Arquivo .backup criptografado'),
            onTap: () => _export(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Sobre'),
          const AboutListTile(
            icon: Icon(Icons.shield_outlined),
            applicationName: 'NoxPass',
            applicationVersion: 'Versão 1.0.0',
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
