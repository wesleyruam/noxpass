import 'package:flutter/material.dart';

/// Pede uma senha ao usuário em um diálogo. Retorna a senha ou `null` se
/// cancelado. Com [requireConfirm], exige repetição idêntica.
Future<String?> promptForPassword(
  BuildContext context, {
  required String title,
  String? message,
  bool requireConfirm = false,
  String actionLabel = 'Confirmar',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasswordPromptDialog(
      title: title,
      message: message,
      requireConfirm: requireConfirm,
      actionLabel: actionLabel,
    ),
  );
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({
    required this.title,
    required this.message,
    required this.requireConfirm,
    required this.actionLabel,
  });

  final String title;
  final String? message;
  final bool requireConfirm;
  final String actionLabel;

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Informe uma senha.' : null,
              onFieldSubmitted: (_) => widget.requireConfirm ? null : _submit(),
            ),
            if (widget.requireConfirm) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                validator: (v) =>
                    v != _password.text ? 'As senhas não coincidem.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}
