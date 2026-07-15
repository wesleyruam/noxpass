import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../../../totp/presentation/totp_code_tile.dart';
import '../../data/vault_providers.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import 'secret_form_sheet.dart';
import 'secret_history_sheet.dart';

/// Exibe os detalhes de um segredo com revelar/copiar seguros.
class SecretDetailSheet extends ConsumerStatefulWidget {
  const SecretDetailSheet({required this.secret, super.key});

  final Secret secret;

  static Future<void> show(BuildContext context, Secret secret) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SecretDetailSheet(secret: secret),
    );
  }

  @override
  ConsumerState<SecretDetailSheet> createState() => _SecretDetailSheetState();
}

class _SecretDetailSheetState extends ConsumerState<SecretDetailSheet> {
  bool _revealPassword = false;
  late bool _isFavorite;

  /// Tempo até a área de transferência ser limpa automaticamente.
  static const Duration _clipboardClear = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.secret.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    await ref
        .read(secretsRepositoryProvider)
        .setFavorite(widget.secret.id, value: next);
  }

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
    final nox = context.nox;
    final secret = widget.secret;
    final payload = secret.payload;
    final subtitle = payload[SecretPayload.username] ??
        payload[SecretPayload.url] ??
        '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: NoxTilePalette.forSeed(secret.title),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    NoxTilePalette.initials(secret.title),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        secret.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.mono(fontSize: 12, color: nox.textFaint),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? nox.warn : null,
                  ),
                  onPressed: _toggleFavorite,
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
            const SizedBox(height: 16),
            if (payload[SecretPayload.username] case final user?)
              _FieldTile(
                label: 'Usuário',
                value: user,
                onCopy: () => _copy('Usuário', user),
              ),
            if (payload[SecretPayload.password] case final pass?)
              _FieldTile(
                label: 'Senha',
                value: _revealPassword ? pass : '••••••••••••',
                onCopy: () => _copy('Senha', pass),
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _revealPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
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
              _FieldTile(label: 'Observações', value: notes, mono: false),
            if (payload[SecretPayload.totp] case final totp?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TotpCodeTile(
                  rawSecret: totp,
                  onCopy: (code) => _copy('Código 2FA', code),
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _moveToTrash,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Mover para a lixeira'),
              ),
            ),
          ],
        ),
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
    this.mono = true,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final valueStyle = mono
        ? context.mono(fontSize: 14, color: theme.colorScheme.onSurface)
        : theme.textTheme.bodyMedium;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: nox.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: nox.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nox.textFaint,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: valueStyle),
              ],
            ),
          ),
          ?trailing,
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_outlined, size: 20, color: nox.textDim),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
