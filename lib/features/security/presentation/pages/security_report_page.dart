import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../../../vault/domain/entities/secret.dart';
import '../../../vault/presentation/widgets/secret_detail_sheet.dart';
import '../security_providers.dart';

/// Lista os problemas de segurança do cofre (senhas fracas e reutilizadas).
class SecurityReportPage extends ConsumerWidget {
  const SecurityReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(securityReportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Segurança')),
      body: !report.hasIssues
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Tudo certo por aqui',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma senha fraca ou reutilizada.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (report.weakSecrets.isNotEmpty)
                  _Section(
                    title: 'Senhas fracas',
                    subtitle: 'Considere trocá-las por senhas mais fortes.',
                    children: [
                      for (final secret in report.weakSecrets)
                        _IssueTile(secret: secret),
                    ],
                  ),
                for (var i = 0; i < report.reusedGroups.length; i++)
                  _Section(
                    title: 'Senha reutilizada #${i + 1}',
                    subtitle:
                        '${report.reusedGroups[i].length} contas usam a mesma senha.',
                    children: [
                      for (final secret in report.reusedGroups[i])
                        _IssueTile(secret: secret),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.secret});

  final Secret secret;

  @override
  Widget build(BuildContext context) {
    final color = NoxTilePalette.forSeed(secret.title);
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          NoxTilePalette.initials(secret.title),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(secret.title),
      trailing: Icon(Icons.chevron_right, color: context.nox.textFaint),
      onTap: () => SecretDetailSheet.show(context, secret),
    );
  }
}
