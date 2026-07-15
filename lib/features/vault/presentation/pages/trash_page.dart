import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vault_providers.dart';
import '../secrets_providers.dart';
import '../widgets/secret_type_icon.dart';

/// Lixeira: itens excluídos, restauráveis por 30 dias antes da remoção
/// definitiva.
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lixeira')),
      body: trashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('A lixeira está vazia.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final secret = items[index];
              return ListTile(
                leading: Icon(iconForSecretType(secret.type)),
                title: Text(secret.title),
                subtitle: const Text('Na lixeira'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Restaurar',
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        await ref
                            .read(secretsRepositoryProvider)
                            .restore(secret.id);
                        ref.invalidate(trashProvider);
                      },
                    ),
                    IconButton(
                      tooltip: 'Excluir definitivamente',
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () =>
                          _confirmDelete(context, ref, secret.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir definitivamente?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(secretsRepositoryProvider).deletePermanently(id);
      ref.invalidate(trashProvider);
    }
  }
}
