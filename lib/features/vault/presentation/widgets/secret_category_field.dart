import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../../data/vault_providers.dart';
import '../secrets_providers.dart';
import 'category_icon.dart';

/// Campo de seleção de categoria (opcional) de um segredo.
///
/// Mostra a categoria atual (ícone + nome) ou "Sem categoria" e abre um
/// seletor com as categorias existentes, a opção "Nenhuma" e criar nova.
class SecretCategoryField extends ConsumerWidget {
  const SecretCategoryField({
    required this.categoryId,
    required this.onChanged,
    super.key,
  });

  final String? categoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final selected = categories.firstWhereOrNull((c) => c.id == categoryId);

    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        builder: (_) => _CategoryPickerSheet(
          selectedId: categoryId,
          onSelected: onChanged,
        ),
      ),
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Categoria',
          contentPadding: EdgeInsets.fromLTRB(14, 12, 8, 12),
        ),
        child: Row(
          children: [
            Icon(
              selected == null
                  ? Icons.folder_off_outlined
                  : categoryIconFor(selected.icon),
              size: 20,
              color: selected == null ? nox.textFaint : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.name ?? 'Sem categoria',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: selected == null ? nox.textDim : null,
                ),
              ),
            ),
            Icon(Icons.unfold_more, size: 20, color: nox.textFaint),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final ValueChanged<String?> onSelected;

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final name = await _promptCategoryName(context);
    if (name == null || name.trim().isEmpty) return;
    final category =
        await ref.read(secretsRepositoryProvider).createCategory(name.trim());
    if (context.mounted) {
      onSelected(category.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: nox.textFaint,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Categoria',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _createNew(context, ref),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nova'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                _CategoryRow(
                  icon: Icons.folder_off_outlined,
                  label: 'Nenhuma',
                  selected: selectedId == null,
                  onTap: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final c in categories)
                  _CategoryRow(
                    icon: categoryIconFor(c.icon),
                    label: c.name,
                    selected: selectedId == c.id,
                    onTap: () {
                      onSelected(c.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: nox.surface3,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: selected ? theme.colorScheme.primary : nox.textDim,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Diálogo simples para nomear uma nova categoria.
Future<String?> _promptCategoryName(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nova categoria'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nome'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Criar'),
        ),
      ],
    ),
  );
}
