import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/nox_colors.dart';
import '../../vault/domain/entities/secret_payload.dart';
import '../../vault/presentation/widgets/secret_type_icon.dart';
import '../data/backup_providers.dart';
import '../domain/restore_plan.dart';

/// Prévia de uma restauração: lista o que vem no backup comparado ao cofre
/// atual e deixa o usuário resolver cada conflito antes de aplicar.
///
/// Retorna (via [Navigator.pop]) o [RestoreSummary] aplicado, ou null se o
/// usuário cancelar.
class RestorePreviewPage extends ConsumerStatefulWidget {
  const RestorePreviewPage({required this.plan, this.source, super.key});

  final RestorePlan plan;

  /// Origem exibida no subtítulo (ex.: "Google Drive", "arquivo").
  final String? source;

  @override
  ConsumerState<RestorePreviewPage> createState() => _RestorePreviewPageState();
}

class _RestorePreviewPageState extends ConsumerState<RestorePreviewPage> {
  bool _applying = false;

  RestorePlan get _plan => widget.plan;

  /// Conflitos primeiro (exigem decisão), depois novos, depois idênticos.
  List<RestoreItem> get _ordered {
    int rank(RestoreItemKind k) => switch (k) {
      RestoreItemKind.conflict => 0,
      RestoreItemKind.added => 1,
      RestoreItemKind.identical => 2,
    };
    return [..._plan.items]
      ..sort((a, b) => rank(a.kind).compareTo(rank(b.kind)));
  }

  void _setAllConflicts(RestoreResolution resolution) {
    setState(() {
      for (final item in _plan.items) {
        if (item.kind == RestoreItemKind.conflict) item.resolution = resolution;
      }
    });
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final summary = await ref
          .read(vaultBackupManagerProvider)
          .applyRestore(_plan);
      navigator.pop(summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => _applying = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível aplicar a restauração.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nox = context.nox;
    final items = _ordered;
    final hasConflicts = _plan.conflictCount > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar restauração')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.source != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Backup de ${widget.source}',
                      style: TextStyle(color: nox.textDim),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CountChip(
                      color: nox.ok,
                      label: '${_plan.addedCount} novos',
                    ),
                    _CountChip(
                      color: nox.warn,
                      label: '${_plan.conflictCount} conflitos',
                    ),
                    _CountChip(
                      color: nox.textFaint,
                      label: '${_plan.identicalCount} idênticos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasConflicts)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Todos os conflitos:',
                    style: TextStyle(fontSize: 13, color: nox.textDim),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            _setAllConflicts(RestoreResolution.duplicate),
                        child: const Text('Adicionar cópia'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _setAllConflicts(RestoreResolution.replace),
                    child: const Text('Substituir'),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _RestoreTile(
                item: items[i],
                onResolution: (r) => setState(() => items[i].resolution = r),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applying ? null : _apply,
                  child: _applying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aplicar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreTile extends StatelessWidget {
  const _RestoreTile({required this.item, required this.onResolution});

  final RestoreItem item;
  final ValueChanged<RestoreResolution> onResolution;

  @override
  Widget build(BuildContext context) {
    final nox = context.nox;
    final draft = item.incoming;
    final username = draft.payload[SecretPayload.username];
    final subtitle = <String>[
      labelForSecretType(draft.type),
      if (username != null && username.isNotEmpty) username,
    ].join(' · ');

    return ListTile(
      leading: Icon(iconForSecretType(draft.type), color: nox.textDim),
      title: Text(draft.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: switch (item.kind) {
        RestoreItemKind.added => _KindBadge(color: nox.ok, label: 'Novo'),
        RestoreItemKind.identical => _KindBadge(
          color: nox.textFaint,
          label: 'Já existe',
        ),
        RestoreItemKind.conflict => _ResolutionMenu(
          value: item.resolution,
          onChanged: onResolution,
        ),
      },
    );
  }
}

/// Seletor compacto de ação para um conflito.
class _ResolutionMenu extends StatelessWidget {
  const _ResolutionMenu({required this.value, required this.onChanged});

  final RestoreResolution value;
  final ValueChanged<RestoreResolution> onChanged;

  static const _labels = <RestoreResolution, String>{
    RestoreResolution.duplicate: 'Adicionar cópia',
    RestoreResolution.replace: 'Substituir',
    RestoreResolution.skip: 'Ignorar',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (value) {
      RestoreResolution.replace => theme.colorScheme.error,
      RestoreResolution.skip => context.nox.textFaint,
      RestoreResolution.duplicate => theme.colorScheme.primary,
    };
    return PopupMenuButton<RestoreResolution>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Ação para o conflito',
      itemBuilder: (context) => [
        for (final entry in _labels.entries)
          PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _labels[value]!,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          Icon(Icons.arrow_drop_down, color: color),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
