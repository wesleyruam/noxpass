import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/auth_controller.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import '../secrets_providers.dart';
import '../widgets/secret_detail_sheet.dart';
import '../widgets/secret_form_sheet.dart';
import '../widgets/secret_type_icon.dart';

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
            tooltip: 'Travar cofre',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SecretFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                hintText: 'Buscar no cofre',
                leading: const Icon(Icons.search),
                onChanged: (value) =>
                    ref.read(_searchQueryProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: secretsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Erro ao carregar: $error')),
                data: (secrets) {
                  final filtered = query.isEmpty
                      ? secrets
                      : secrets
                          .where((s) => s.title.toLowerCase().contains(query))
                          .toList();

                  if (secrets.isEmpty) {
                    return const _EmptyState();
                  }
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nenhum resultado para a busca.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _SecretTile(secret: filtered[index]),
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

class _SecretTile extends StatelessWidget {
  const _SecretTile({required this.secret});

  final Secret secret;

  @override
  Widget build(BuildContext context) {
    final subtitle = secret.payload[SecretPayload.username] ??
        secret.payload[SecretPayload.url] ??
        '';
    return ListTile(
      leading: CircleAvatar(child: Icon(iconForSecretType(secret.type))),
      title: Text(secret.title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: secret.isFavorite ? const Icon(Icons.star, size: 18) : null,
      onTap: () => SecretDetailSheet.show(context, secret),
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
            Text(
              'Seu cofre está vazio',
              style: theme.textTheme.titleMedium,
            ),
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
