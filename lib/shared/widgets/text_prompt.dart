import 'package:flutter/material.dart';

/// Pede um texto curto ao usuário em um diálogo. Retorna o texto ou `null`
/// se cancelado. Usado para nomear categorias, por exemplo.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String label = 'Nome',
  String actionLabel = 'Salvar',
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
