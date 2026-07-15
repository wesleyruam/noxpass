import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/crypto/crypto_failure.dart';
import '../../../../shared/security/password_strength_meter.dart';
import '../auth_controller.dart';

/// Abre o diálogo de troca da senha mestra. Retorna `true` se a troca ocorreu.
Future<bool?> showChangeMasterPasswordDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const _ChangeMasterPasswordDialog(),
  );
}

class _ChangeMasterPasswordDialog extends ConsumerStatefulWidget {
  const _ChangeMasterPasswordDialog();

  @override
  ConsumerState<_ChangeMasterPasswordDialog> createState() =>
      _ChangeMasterPasswordDialogState();
}

class _ChangeMasterPasswordDialogState
    extends ConsumerState<_ChangeMasterPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _currentError;

  static const int _minLength = 8;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).changeMasterPassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthenticationFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _currentError = 'Senha atual incorreta.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível trocar a senha.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha mestra'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  errorText: _currentError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Informe a senha atual.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _next,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => (v ?? '').length < _minLength
                    ? 'Use pelo menos $_minLength caracteres.'
                    : null,
              ),
              const SizedBox(height: 10),
              PasswordStrengthMeter(password: _next.text),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _next.text ? 'As senhas não coincidem.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Alterar'),
        ),
      ],
    );
  }
}
