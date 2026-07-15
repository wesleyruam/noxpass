import 'package:flutter/material.dart';

/// Pede uma senha ao usuário em um diálogo. Retorna a senha ou `null` se
/// cancelado. Com [requireConfirm], exige repetição idêntica.
Future<String?> promptForPassword(
  BuildContext context, {
  required String title,
  String? message,
  bool requireConfirm = false,
  String actionLabel = 'Confirmar',
  int minLength = 1,
  TextInputType? keyboardType,
  String fieldLabel = 'Senha',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasswordPromptDialog(
      title: title,
      message: message,
      requireConfirm: requireConfirm,
      actionLabel: actionLabel,
      minLength: minLength,
      keyboardType: keyboardType,
      fieldLabel: fieldLabel,
    ),
  );
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({
    required this.title,
    required this.message,
    required this.requireConfirm,
    required this.actionLabel,
    required this.minLength,
    required this.keyboardType,
    required this.fieldLabel,
  });

  final String title;
  final String? message;
  final bool requireConfirm;
  final String actionLabel;
  final int minLength;
  final TextInputType? keyboardType;
  final String fieldLabel;

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
              keyboardType: widget.keyboardType,
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Informe ${widget.fieldLabel.toLowerCase()}.';
                if (value.length < widget.minLength) {
                  return 'Use pelo menos ${widget.minLength} caracteres.';
                }
                return null;
              },
              onFieldSubmitted: (_) => widget.requireConfirm ? null : _submit(),
            ),
            if (widget.requireConfirm) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  labelText: 'Confirmar ${widget.fieldLabel.toLowerCase()}',
                ),
                validator: (v) =>
                    v != _password.text ? 'Não coincide.' : null,
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
