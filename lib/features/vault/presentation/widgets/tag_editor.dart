import 'package:flutter/material.dart';

import '../../../../shared/theme/nox_colors.dart';

/// Editor de tags de um segredo: chips removíveis + campo para adicionar,
/// com sugestões das tags já usadas no cofre.
///
/// Controlado: mantém a lista fora (no formulário) e notifica por [onChanged].
class TagEditor extends StatefulWidget {
  const TagEditor({
    required this.tags,
    required this.onChanged,
    this.suggestions = const [],
    super.key,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    // Case-insensitive: não duplica "Trabalho" e "trabalho".
    final exists =
        widget.tags.any((t) => t.toLowerCase() == name.toLowerCase());
    if (!exists) {
      widget.onChanged([...widget.tags, name]);
    }
    _controller.clear();
    _focus.requestFocus();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final available = widget.suggestions
        .where((s) => !widget.tags
            .any((t) => t.toLowerCase() == s.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'Adicionar e pressionar Enter',
            prefixIcon: const Icon(Icons.label_outline),
            suffixIcon: IconButton(
              tooltip: 'Adicionar tag',
              icon: const Icon(Icons.add),
              onPressed: () => _add(_controller.text),
            ),
          ),
          onChanged: (value) {
            // Vírgula também confirma a tag.
            if (value.endsWith(',')) {
              _add(value.substring(0, value.length - 1));
            }
          },
          onSubmitted: _add,
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.tags)
                Chip(
                  label: Text(tag),
                  onDeleted: () => _remove(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        if (available.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Sugestões',
            style: theme.textTheme.labelSmall?.copyWith(color: nox.textFaint),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in available.take(12))
                ActionChip(
                  label: Text(tag),
                  avatar: Icon(Icons.add, size: 16, color: nox.textDim),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => _add(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
