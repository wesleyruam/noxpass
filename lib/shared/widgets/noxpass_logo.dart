import 'package:flutter/material.dart';

/// Marca do NoxPass.
///
/// O escudo é um PNG transparente (`assets/logo/noxpass_shield.png`) que
/// funciona sobre qualquer fundo. O nome e o slogan são renderizados como
/// texto nativo — assim ficam nítidos em qualquer tamanho e acompanham as
/// cores do tema (claro/escuro), evitando texto escuro sobre fundo escuro.
const String _shieldAsset = 'assets/logo/noxpass_shield.png';

/// Apenas o escudo, dimensionado por [size].
class NoxPassShield extends StatelessWidget {
  const NoxPassShield({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _shieldAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      // Fallback caso o asset falhe: mantém a identidade visual.
      errorBuilder: (context, _, _) => Icon(
        Icons.shield_outlined,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Lockup completo: escudo + "NoxPass" e, opcionalmente, o slogan.
///
/// Layout vertical (escudo em cima do nome), pensado para telas de abertura.
class NoxPassWordmark extends StatelessWidget {
  const NoxPassWordmark({
    this.shieldSize = 72,
    this.showTagline = true,
    super.key,
  });

  final double shieldSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoxPassShield(size: shieldSize),
        SizedBox(height: shieldSize * 0.28),
        // "Nox" no tom da marca + "Pass" na cor do texto do tema.
        Text.rich(
          TextSpan(
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Nox',
                style: TextStyle(color: colors.primary),
              ),
              TextSpan(
                text: 'Pass',
                style: TextStyle(color: colors.onSurface),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'SUA PRIVACIDADE. SEU CONTROLE.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
