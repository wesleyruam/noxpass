import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/security/password_strength_meter.dart';
import '../auth_controller.dart';

/// Cadastro da senha mestra (primeiro uso). Deixa claro que, num modelo
/// Zero-Knowledge, esquecer a senha significa perder o acesso ao cofre.
class CreateMasterPasswordPage extends ConsumerStatefulWidget {
  const CreateMasterPasswordPage({super.key});

  @override
  ConsumerState<CreateMasterPasswordPage> createState() =>
      _CreateMasterPasswordPageState();
}

class _CreateMasterPasswordPageState
    extends ConsumerState<CreateMasterPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  static const int _minLength = 8;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .createVault(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o cofre.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Criar cofre')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Defina sua senha mestra',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ela protege tudo no NoxPass e nunca sai do seu '
                      'dispositivo. Guarde-a bem: sem ela, não há como '
                      'recuperar seus dados.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Senha mestra',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if ((value ?? '').length < _minLength) {
                          return 'Use pelo menos $_minLength caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    PasswordStrengthMeter(password: _passwordController.text),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha mestra',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar cofre'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
