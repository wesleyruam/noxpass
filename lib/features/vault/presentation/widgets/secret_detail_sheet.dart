import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vault_providers.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import 'secret_form_sheet.dart';
import 'secret_history_sheet.dart';
import 'secret_type_icon.dart';

/// Exibe os detalhes de um segredo com revelar/copiar seguros.
class SecretDetailSheet extends ConsumerStatefulWidget {
  const SecretDetailSheet({required this.secret, super.key});

  final Secret secret;

  static Future<void> show(BuildContext context, Secret secret) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SecretDetailSheet(secret: secret),
    );
  }

  @override
  ConsumerState<SecretDetailSheet> createState() => _SecretDetailSheetState();
}

class _SecretDetailSheetState extends ConsumerState<SecretDetailSheet> {
  bool _revealPassword = false;

  /// Tempo até a área de transferência ser limpa automaticamente.
  static const Duration _clipboardClear = Duration(seconds: 30);

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    // Limpa a área de transferência se ainda contiver o valor copiado.
    Future<void>.delayed(_clipboardClear, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copiado (limpa em 30s).')),
      );
    }
  }

  Future<void> _moveToTrash() async {
    await ref.read(secretsRepositoryProvider).moveToTrash(widget.secret.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secret = widget.secret;
    final payload = secret.payload;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(child: Icon(iconForSecretType(secret.type))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  secret.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Histórico',
                icon: const Icon(Icons.history),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await SecretHistorySheet.show(context, secret);
                },
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await SecretFormSheet.show(context, existing: secret);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (payload[SecretPayload.username] case final user?)
            _FieldTile(
              label: 'Usuário',
              value: user,
              onCopy: () => _copy('Usuário', user),
            ),
          if (payload[SecretPayload.password] case final pass?)
            _FieldTile(
              label: 'Senha',
              value: _revealPassword ? pass : '••••••••••',
              onCopy: () => _copy('Senha', pass),
              trailing: IconButton(
                icon: Icon(
                  _revealPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _revealPassword = !_revealPassword),
              ),
            ),
          if (payload[SecretPayload.url] case final url?)
            _FieldTile(
              label: 'URL',
              value: url,
              onCopy: () => _copy('URL', url),
            ),
          if (payload[SecretPayload.notes] case final notes?)
            _FieldTile(label: 'Observações', value: notes),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _moveToTrash,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Mover para a lixeira'),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          ?trailing,
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy_outlined),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
