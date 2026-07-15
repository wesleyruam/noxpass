import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/security/password_strength_meter.dart';
import '../../../shared/theme/nox_colors.dart';
import '../domain/password_generator.dart';

/// Folha do gerador de senhas com controles ao vivo.
///
/// Retorna a senha escolhida (ou `null` se cancelado) via [Navigator.pop].
class PasswordGeneratorSheet extends StatefulWidget {
  const PasswordGeneratorSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PasswordGeneratorSheet(),
    );
  }

  @override
  State<PasswordGeneratorSheet> createState() => _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends State<PasswordGeneratorSheet> {
  static const _generator = PasswordGenerator();

  PasswordGeneratorOptions _options = const PasswordGeneratorOptions();
  String _password = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() => _password = _generator.generate(_options));
  }

  void _update(PasswordGeneratorOptions next) {
    // Garante ao menos uma classe ativa antes de aplicar.
    if (!next.hasAnyClass) return;
    setState(() {
      _options = next;
      _password = _generator.generate(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gerador de senha',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            // Senha gerada, em destaque.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              decoration: BoxDecoration(
                color: nox.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nox.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _password,
                      style: context.mono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gerar outra',
                    onPressed: _regenerate,
                    icon: Icon(Icons.refresh, color: nox.textDim),
                  ),
                  IconButton(
                    tooltip: 'Copiar',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _password));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Senha copiada.')),
                        );
                      }
                    },
                    icon: Icon(Icons.copy_outlined, color: nox.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PasswordStrengthMeter(password: _password),
            const SizedBox(height: 12),
            // Comprimento.
            Row(
              children: [
                Text('Comprimento', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${_options.length}',
                  style: context.mono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _options.length.toDouble(),
              min: 6,
              max: 64,
              divisions: 58,
              onChanged: (v) => _update(_options.copyWith(length: v.round())),
            ),
            _ToggleRow(
              label: 'Letras maiúsculas',
              value: _options.useUpper,
              onChanged: (v) => _update(_options.copyWith(useUpper: v)),
            ),
            _ToggleRow(
              label: 'Letras minúsculas',
              value: _options.useLower,
              onChanged: (v) => _update(_options.copyWith(useLower: v)),
            ),
            _ToggleRow(
              label: 'Números',
              value: _options.useDigits,
              onChanged: (v) => _update(_options.copyWith(useDigits: v)),
            ),
            _ToggleRow(
              label: 'Símbolos',
              value: _options.useSymbols,
              onChanged: (v) => _update(_options.copyWith(useSymbols: v)),
            ),
            _ToggleRow(
              label: 'Evitar caracteres ambíguos',
              value: _options.avoidAmbiguous,
              onChanged: (v) => _update(_options.copyWith(avoidAmbiguous: v)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_password),
              child: const Text('Usar esta senha'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
