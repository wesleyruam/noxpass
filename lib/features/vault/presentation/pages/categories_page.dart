import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../../../../shared/widgets/text_prompt.dart';
import '../../data/vault_providers.dart';
import '../secrets_providers.dart';
import '../widgets/category_icon.dart';

/// Gestão de categorias: criar, renomear e excluir as personalizadas.
///
/// As categorias nativas (semeadas na criação do cofre) ficam protegidas.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await promptForText(
      context,
      title: 'Nova categoria',
      actionLabel: 'Criar',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(secretsRepositoryProvider).createCategory(name.trim());
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String id,
    String current,
  ) async {
    final name = await promptForText(
      context,
      title: 'Renomear categoria',
      initialValue: current,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(secretsRepositoryProvider).renameCategory(id, name.trim());
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Excluir "$name"? Os segredos nela ficam sem categoria '
          '(não são apagados).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(secretsRepositoryProvider).deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria ainda.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: nox.surface3,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(categoryIconFor(c.icon),
                      size: 20, color: theme.colorScheme.primary),
                ),
                title: Text(c.name),
                subtitle: c.isBuiltIn ? const Text('Nativa') : null,
                trailing: c.isBuiltIn
                    ? Icon(Icons.lock_outline, size: 18, color: nox.textFaint)
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            _rename(context, ref, c.id, c.name);
                          } else if (value == 'delete') {
                            _delete(context, ref, c.id, c.name);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Renomear'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
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
}
