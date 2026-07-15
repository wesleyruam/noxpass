import 'package:flutter/material.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../../domain/entities/secret_type.dart';
import 'secret_type_icon.dart';

/// Campo de seleção do tipo de segredo.
///
/// Em vez de um `DropdownButton` com nomes técnicos, mostra o tipo atual como
/// um campo (ícone + rótulo) e abre um seletor em folha com ícone, rótulo e
/// descrição de cada tipo — intuitivo e alinhado ao visual do app.
class SecretTypeField extends StatelessWidget {
  const SecretTypeField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final SecretType value;
  final ValueChanged<SecretType> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<SecretType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Usamos um grabber próprio dentro do DraggableScrollableSheet.
      showDragHandle: false,
      builder: (_) => _SecretTypeSheet(selected: value),
    );
    if (selected != null && selected != value) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tipo',
          contentPadding: EdgeInsets.fromLTRB(14, 12, 8, 12),
        ),
        child: Row(
          children: [
            Icon(iconForSecretType(value), size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labelForSecretType(value),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.unfold_more, size: 20, color: nox.textFaint),
          ],
        ),
      ),
    );
  }
}

class _SecretTypeSheet extends StatelessWidget {
  const _SecretTypeSheet({required this.selected});

  final SecretType selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;

    // Começa na metade da tela; o usuário arrasta o grabber para expandir.
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.5, 0.92],
      builder: (context, scrollController) => Column(
        children: [
          // Grabber para arrastar.
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tipo de segredo',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: SecretType.values.length,
              itemBuilder: (context, index) {
                final type = SecretType.values[index];
                final isSelected = type == selected;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(type),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isSelected
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
                            iconForSecretType(type),
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : nox.textDim,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labelForSecretType(type),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                descriptionForSecretType(type),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: nox.textDim),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              size: 20, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
