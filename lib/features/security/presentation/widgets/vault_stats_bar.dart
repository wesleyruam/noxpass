import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security_providers.dart';

/// Faixa de cartões-estatística exibida no topo da home.
///
/// Os cartões de "Fracas" e "Reutilizadas" são acionáveis quando há problemas.
class VaultStatsBar extends ConsumerWidget {
  const VaultStatsBar({this.onIssuesTap, super.key});

  final VoidCallback? onIssuesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(securityReportProvider);
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatCard(
            label: 'Total',
            value: '${report.total}',
            icon: Icons.inventory_2_outlined,
            color: colors.primary,
          ),
          _StatCard(
            label: 'Fracas',
            value: '${report.weakCount}',
            icon: Icons.gpp_maybe_outlined,
            color: report.weakCount > 0 ? colors.error : colors.primary,
            onTap: report.weakCount > 0 ? onIssuesTap : null,
          ),
          _StatCard(
            label: 'Reutilizadas',
            value: '${report.reusedCount}',
            icon: Icons.content_copy_outlined,
            color: report.reusedCount > 0 ? Colors.orange : colors.primary,
            onTap: report.reusedCount > 0 ? onIssuesTap : null,
          ),
          _StatCard(
            label: 'Favoritas',
            value: '${report.favorites}',
            icon: Icons.star_outline,
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 120,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
