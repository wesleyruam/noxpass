import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/theme/nox_colors.dart';
import '../../../authentication/presentation/auth_controller.dart';
import '../../../security/presentation/widgets/vault_health_card.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import '../secrets_providers.dart';
import '../widgets/secret_detail_sheet.dart';
import '../widgets/secret_form_sheet.dart';

/// Filtro de busca da home (client-side sobre a lista já decifrada).
final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretsAsync = ref.watch(secretsListProvider);
    final query = ref.watch(_searchQueryProvider).trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NoxPass'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settingsPath),
          ),
          IconButton(
            tooltip: 'Travar cofre',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SecretFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: VaultHealthCard(
                onTap: () => context.push(AppRoutes.securityPath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchBar(
                hintText: 'Buscar no cofre',
                leading: Icon(Icons.search, color: context.nox.textFaint),
                onChanged: (value) =>
                    ref.read(_searchQueryProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: secretsAsync.when(
                loading: () => const _LoadingList(),
                error: (error, _) =>
                    Center(child: Text('Erro ao carregar: $error')),
                data: (secrets) {
                  final filtered = query.isEmpty
                      ? secrets
                      : secrets
                          .where((s) => s.title.toLowerCase().contains(query))
                          .toList();

                  if (secrets.isEmpty) return const _EmptyState();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum resultado para a busca.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _SectionLabel('Cofre');
                      }
                      return _SecretTile(secret: filtered[index - 1]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rótulo de seção em maiúsculas monoespaçadas (ex.: "COFRE").
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Text(
        text.toUpperCase(),
        style: context.mono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.nox.textFaint,
          letterSpacing: 2.4,
        ),
      ),
    );
  }
}

class _SecretTile extends StatelessWidget {
  const _SecretTile({required this.secret});

  final Secret secret;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final subtitle = secret.payload[SecretPayload.username] ??
        secret.payload[SecretPayload.url] ??
        '';
    final has2fa = secret.payload[SecretPayload.totp] != null;
    final tileColor = NoxTilePalette.forSeed(secret.title);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SecretDetailSheet.show(context, secret),
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _InitialTile(color: tileColor, text: NoxTilePalette.initials(secret.title)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              secret.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (secret.isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star, size: 14, color: nox.warn),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.mono(fontSize: 12, color: nox.textDim),
                        ),
                      ],
                    ],
                  ),
                ),
                if (has2fa) ...[
                  const SizedBox(width: 8),
                  const _Badge2fa(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialTile extends StatelessWidget {
  const _InitialTile({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _Badge2fa extends StatelessWidget {
  const _Badge2fa();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '2FA',
        style: context.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Placeholder de carregamento em forma de "skeleton" das linhas.
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final nox = context.nox;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      itemCount: 7,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: nox.surface3,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 140, color: nox.surface3),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 90, color: nox.surface3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Seu cofre está vazio', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Toque em "Novo" para guardar sua primeira senha com segurança.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
