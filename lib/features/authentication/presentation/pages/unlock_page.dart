import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/password_prompt.dart';
import '../../data/auth_data_providers.dart';
import '../auth_controller.dart';

/// Desbloqueio do cofre existente pela senha mestra.
class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty) return;
    await ref.read(authControllerProvider.notifier).unlock(_passwordController.text);
    _passwordController.clear();
  }

  Future<void> _unlockWithPin() async {
    final pin = await promptForPassword(
      context,
      title: 'Desbloquear com PIN',
      fieldLabel: 'PIN',
      actionLabel: 'Desbloquear',
      minLength: 4,
      keyboardType: TextInputType.number,
    );
    if (pin == null) return;
    await ref.read(authControllerProvider.notifier).unlockWithPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    // Mensagem transitória (senha incorreta) vem no próprio estado.
    final error = authState.valueOrNull?.error;
    final pinEnabled = ref.watch(isPinEnabledProvider).valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Desbloquear NoxPass',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Senha mestra',
                      prefixIcon: const Icon(Icons.password),
                      errorText: error,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Desbloquear'),
                  ),
                  if (pinEnabled) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: isLoading ? null : _unlockWithPin,
                      icon: const Icon(Icons.pin_outlined),
                      label: const Text('Desbloquear com PIN'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
