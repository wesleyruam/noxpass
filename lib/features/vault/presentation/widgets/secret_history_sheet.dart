import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/vault_providers.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';

/// Lista as versões anteriores de um segredo e permite restaurá-las.
class SecretHistorySheet extends ConsumerStatefulWidget {
  const SecretHistorySheet({required this.secret, super.key});

  final Secret secret;

  static Future<void> show(BuildContext context, Secret secret) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SecretHistorySheet(secret: secret),
    );
  }

  @override
  ConsumerState<SecretHistorySheet> createState() => _SecretHistorySheetState();
}

class _SecretHistorySheetState extends ConsumerState<SecretHistorySheet> {
  late Future<List<SecretVersionSnapshot>> _versions;

  @override
  void initState() {
    super.initState();
    _versions = ref.read(secretsRepositoryProvider).getVersions(widget.secret.id);
  }

  Future<void> _restore(String versionId) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(secretsRepositoryProvider)
        .restoreVersion(widget.secret.id, versionId);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Versão restaurada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Histórico — ${widget.secret.title}',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<SecretVersionSnapshot>>(
            future: _versions,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final versions = snapshot.data!;
              if (versions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhuma alteração registrada ainda.'),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final version in versions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(version.title),
                      subtitle: Text(
                        '${dateFormat.format(version.createdAt)}'
                        '${version.payload[SecretPayload.username] != null ? ' · ${version.payload[SecretPayload.username]}' : ''}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _restore(version.id),
                        child: const Text('Restaurar'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
